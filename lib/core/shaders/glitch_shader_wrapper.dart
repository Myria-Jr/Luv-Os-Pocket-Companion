import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/cute_horror_theme.dart';

/// Multi-Pass GLSL Post-Processing Wrapper (`shaders/yandere_glitch.frag`).
///
/// Feeds all 6 required uniforms into the shader pipeline:
/// - `u_time` (float)
/// - `u_resolution` (vec2)
/// - `u_corruption` (float)
/// - `u_mania` (float)
/// - `u_touch_pos` (vec2)
/// - `u_heartbeat_pulse` (float)
class GlitchShaderWrapper extends StatefulWidget {
  final Widget child;
  final double corruption;
  final double obsession;
  final double mania;
  final double glitchIntensity;
  final double heartbeatPulse;

  const GlitchShaderWrapper({
    super.key,
    required this.child,
    required this.corruption,
    required this.obsession,
    this.mania = 0.1,
    required this.glitchIntensity,
    this.heartbeatPulse = 0.0,
  });

  @override
  State<GlitchShaderWrapper> createState() => _GlitchShaderWrapperState();
}

class _GlitchShaderWrapperState extends State<GlitchShaderWrapper>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  double _timeSeconds = 0.0;
  Offset _lastTouchPos = const Offset(200, 400);

  @override
  void initState() {
    super.initState();
    _loadFragmentProgram();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadFragmentProgram() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/yandere_glitch.frag');
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
      });
    } catch (_) {
      // Procedural multi-pass fallback painter remains active in headless/test mode.
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    setState(() {
      _timeSeconds = elapsed.inMicroseconds / 1000000.0;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.corruption.clamp(0.0, 1.0);
    final o = widget.obsession.clamp(0.0, 1.0);
    final m = (widget.mania + widget.glitchIntensity * 0.65).clamp(0.0, 1.0);
    final g = widget.glitchIntensity.clamp(0.0, 1.0);

    // Compute synthetic heartbeat pulse combined with explicit pulse uniform
    final beatFreq = 3.2 + c * 5.8 + m * 2.5;
    final synthBeat = math
        .pow(math.max(0.0, math.sin(_timeSeconds * beatFreq)), 8.0)
        .toDouble();
    final effectiveHeartbeat =
        math.max(widget.heartbeatPulse, synthBeat * (0.25 + o * 0.75)).clamp(0.0, 1.0);

    // High-frequency UI tremor during active glitch bursts or high mania
    double jitterX = 0.0;
    double jitterY = 0.0;
    if (g > 0.18 || c > 0.55 || m > 0.65) {
      final wave =
          math.sin(_timeSeconds * 47.0) * math.cos(_timeSeconds * 23.0);
      final spikeGate =
          (math.sin(_timeSeconds * 12.5) > 0.70) || g > 0.22 || m > 0.75;
      if (spikeGate) {
        final strength =
            (g * 5.0) + (c > 0.55 ? (c - 0.55) * 4.0 : 0.0) + (m * 2.2);
        jitterX = wave * strength;
        jitterY = math.cos(_timeSeconds * 37.0) * (strength * 0.30);
      }
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _lastTouchPos = e.localPosition,
      onPointerMove: (e) => _lastTouchPos = e.localPosition,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Transform.translate(
            offset: Offset(jitterX, jitterY),
            child: widget.child,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MultiPassGlitchPainter(
                  shader: _shader,
                  time: _timeSeconds,
                  corruption: c,
                  mania: m,
                  obsession: o,
                  glitchIntensity: g,
                  touchPos: _lastTouchPos,
                  heartbeatPulse: effectiveHeartbeat,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiPassGlitchPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final double time;
  final double corruption;
  final double mania;
  final double obsession;
  final double glitchIntensity;
  final Offset touchPos;
  final double heartbeatPulse;

  const _MultiPassGlitchPainter({
    required this.shader,
    required this.time,
    required this.corruption,
    required this.mania,
    required this.obsession,
    required this.glitchIntensity,
    required this.touchPos,
    required this.heartbeatPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final activeShader = shader;
    if (activeShader != null) {
      try {
        // Uniform layout in shaders/yandere_glitch.frag:
        // 0: u_time
        // 1, 2: u_resolution (width, height)
        // 3: u_corruption
        // 4: u_mania
        // 5, 6: u_touch_pos (dx, dy)
        // 7: u_heartbeat_pulse
        activeShader.setFloat(0, time);
        activeShader.setFloat(1, size.width);
        activeShader.setFloat(2, size.height);
        activeShader.setFloat(3, corruption);
        activeShader.setFloat(4, mania);
        activeShader.setFloat(5, touchPos.dx.clamp(0.0, size.width));
        activeShader.setFloat(6, touchPos.dy.clamp(0.0, size.height));
        activeShader.setFloat(7, heartbeatPulse);

        final shaderPaint = Paint()..shader = activeShader;
        canvas.drawRect(Offset.zero & size, shaderPaint);
      } catch (_) {
        _paintProceduralMultiPassFallback(canvas, size);
      }
    } else {
      _paintProceduralMultiPassFallback(canvas, size);
    }

    if (glitchIntensity > 0.14 || corruption > 0.42 || mania > 0.55) {
      _paintDatamoshSlices(canvas, size);
    }
  }

  void _paintProceduralMultiPassFallback(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Pass 1: Dreamy Halation (low corruption) vs Abyss Vignette (high corruption)
    final vignetteAlpha =
        (0.07 + corruption * 0.38 + obsession * 0.14).clamp(0.0, 0.64);
    final edgeColor = corruption < 0.35
        ? const Color(0xFFFFB7C5).withAlphaFactor(vignetteAlpha * 0.55)
        : CuteHorrorPalette.voidBlack.withAlphaFactor(vignetteAlpha);

    final pulseColor = CuteHorrorPalette.cyberCrimson.withAlphaFactor(
      (heartbeatPulse * (0.18 + corruption * 0.25)).clamp(0.0, 0.42),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.longestSide * 0.72,
          [
            Colors.transparent,
            Color.lerp(edgeColor, pulseColor, 0.4) ?? edgeColor,
          ],
          const [0.46, 1.0],
        ),
    );

    // Pass 2: Radial Chromatic Ring around last Touch Position
    final clampedTouch = Offset(
      touchPos.dx.clamp(0.0, size.width),
      touchPos.dy.clamp(0.0, size.height),
    );
    final ringRadius = 24.0 + ((time * 60.0) % 90.0);
    final ringAlpha = (0.14 * (1.0 - ringRadius / 120.0)).clamp(0.0, 0.18);
    if (ringAlpha > 0.01) {
      canvas.drawCircle(
        clampedTouch,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = (corruption >= 0.5
                  ? CuteHorrorPalette.cyberCrimson
                  : CuteHorrorPalette.hotPink)
              .withAlphaFactor(ringAlpha),
      );
    }

    // Pass 3: LCD Subpixel Scanlines
    final scanAlpha = (0.02 + corruption * 0.08).clamp(0.0, 0.14);
    final scanPaint = Paint()
      ..color = (corruption < 0.35
              ? CuteHorrorPalette.deepBerry
              : CuteHorrorPalette.voidBlack)
          .withAlphaFactor(scanAlpha)
      ..strokeWidth = 1.0;

    final scrollOffset = (time * 24.0) % 4.0;
    for (double y = scrollOffset; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }
  }

  void _paintDatamoshSlices(Canvas canvas, Size size) {
    final seed = (time * 22.0).floor();
    final rng = math.Random(seed);
    final power =
        (glitchIntensity + (corruption - 0.30).clamp(0.0, 0.7) + mania * 0.35)
            .clamp(0.0, 1.3);
    final sliceCount = (power * 7).round();

    for (var i = 0; i < sliceCount; i++) {
      if (rng.nextDouble() > (0.36 + power * 0.45)) continue;
      final y = rng.nextDouble() * size.height;
      final h = 1.5 + rng.nextDouble() * (8.5 * power);
      final w = (0.18 + rng.nextDouble() * 0.76) * size.width;
      final x = rng.nextDouble() * (size.width - w);
      final isCyan = rng.nextBool();

      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        Paint()
          ..color = (isCyan
                  ? CuteHorrorPalette.cyanGlitch
                  : CuteHorrorPalette.cyberCrimson)
              .withAlphaFactor(
                  (0.08 + rng.nextDouble() * 0.18 * power).clamp(0.0, 0.34)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MultiPassGlitchPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.corruption != corruption ||
        oldDelegate.mania != mania ||
        oldDelegate.glitchIntensity != glitchIntensity ||
        oldDelegate.touchPos != touchPos ||
        oldDelegate.heartbeatPulse != heartbeatPulse ||
        oldDelegate.shader != shader;
  }
}
