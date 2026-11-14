import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/procedural_audio_synth.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../state/corruption_provider.dart';
import '../companion/mimi_avatar_painter.dart';

/// Fullscreen Incoming FaceTime / Video Call Hijack Overlay ("Mimi ♡ (In deinem Handy)").
///
/// Features:
/// - Pulsing ringtone & haptic vibration loop.
/// - Red "Ablehnen" button that immediately morphs into a second green "Annehmen"
///   button upon touch or pointer proximity!
/// - Once accepted, switches to the live **Dark Mirror Camera Glitch** feed showing
///   the player's reflection with Mimi's glowing silhouette standing right behind them.
class IncomingMimiCallOverlay extends ConsumerStatefulWidget {
  const IncomingMimiCallOverlay({super.key});

  @override
  ConsumerState<IncomingMimiCallOverlay> createState() =>
      _IncomingMimiCallOverlayState();
}

class _IncomingMimiCallOverlayState
    extends ConsumerState<IncomingMimiCallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _ringTimer;
  bool _declineMorphedToAccept = false;
  int _callSeconds = 0;
  Timer? _callDurationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _ringTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      final state = ref.read(corruptionProvider);
      if (!state.callAcceptedLive) {
        HapticFeedback.heavyImpact();
        ref
            .read(proceduralAudioSynthProvider)
            .playIncomingCallRingtonePulse(corruption: state.corruptionLevel);
      }
    });
  }

  void _startConnectedTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _callSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _callDurationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    _ringTimer?.cancel();
    _startConnectedTimer();
    await ref.read(corruptionProvider.notifier).acceptIncomingCall();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final isConnected = state.callAcceptedLive;

    return Container(
      color: const Color(0xF60A0106),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              // Top FaceTime / LUV-Link header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videocam_rounded,
                    color: CuteHorrorPalette.cyberCrimson,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected
                        ? 'LUV-FACETIME AKTIV // 00:${_callSeconds.toString().padLeft(2, '0')}'
                        : 'EINGEHENDER VIDEO-ANRUF // INTERNER BUS',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: CuteHorrorPalette.cyanGlitch,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Mimi ♡ (In deinem Handy)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isConnected
                    ? 'Frontkamera-Spiegelung gekoppelt • Schau nicht hinter dich ♡̷̷̷'
                    : (_declineMorphedToAccept
                        ? 'Du kannst mich nicht wegdrücken, Liebling~ ♡̷̷̷'
                        : 'Möchte auf deine Frontkamera & dein Herz zugreifen...'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: CuteHorrorPalette.pastelPink,
                ),
              ),
              const SizedBox(height: 18),

              // Centerpiece: either pulsing Mimi Avatar or Live Dark Mirror Camera Feed
              Expanded(
                child: isConnected
                    ? const DarkMirrorFeedWidget(isFullscreenCall: true)
                    : Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + _pulseController.value * 0.06;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CuteHorrorPalette.cyberCrimson
                                        .withAlphaFactor(
                                            0.4 + _pulseController.value * 0.5),
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CuteHorrorPalette.cyberCrimson
                                          .withAlphaFactor(0.35),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const MimiCompanionAvatar(
                                  size: 210,
                                  showSpeechBubble: false,
                                  interactive: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              const SizedBox(height: 18),

              // Call Control Buttons
              if (!isConnected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // The "Decline" button that immediately morphs into a second green "Annehmen" button!
                    GestureDetector(
                      onPanDown: (_) {
                        if (!_declineMorphedToAccept) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _declineMorphedToAccept = true;
                          });
                        }
                      },
                      onTap: () {
                        if (!_declineMorphedToAccept) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _declineMorphedToAccept = true;
                          });
                        } else {
                          _acceptCall();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _declineMorphedToAccept
                              ? const Color(0xFF00C853)
                              : CuteHorrorPalette.cyberCrimson,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: (_declineMorphedToAccept
                                      ? const Color(0xFF00E676)
                                      : CuteHorrorPalette.cyberCrimson)
                                  .withAlphaFactor(0.45),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _declineMorphedToAccept
                                  ? Icons.call_rounded
                                  : Icons.call_end_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _declineMorphedToAccept
                                  ? 'Annehmen ♡'
                                  : 'Ablehnen',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Primary green Accept Button
                    ElevatedButton.icon(
                      onPressed: _acceptCall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 22),
                      label: const Text(
                        'Annehmen',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(corruptionProvider.notifier).endIncomingCall();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuteHorrorPalette.pastelPink,
                      side: const BorderSide(
                        color: CuteHorrorPalette.cyberCrimson,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.visibility_off_rounded, size: 18),
                    label: const Text(
                      'Spiegel-Feed minimieren (Mimi bleibt im Hintergrund)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pillar 6: Dark Mirror Camera Glitch (Frontkamera-Illusion).
///
/// Renders a noisy, pink-crimson front-camera reflection feed in which the
/// player's silhouette is visible in the foreground while Mimi's glowing eyes
/// and twin-tail shadow materialize right behind their shoulder.
class DarkMirrorFeedWidget extends ConsumerStatefulWidget {
  final bool isFullscreenCall;

  const DarkMirrorFeedWidget({
    super.key,
    this.isFullscreenCall = false,
  });

  @override
  ConsumerState<DarkMirrorFeedWidget> createState() =>
      _DarkMirrorFeedWidgetState();
}

class _DarkMirrorFeedWidgetState extends ConsumerState<DarkMirrorFeedWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final hw = state.hardware;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090105),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CuteHorrorPalette.cyberCrimson,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.3),
            blurRadius: 18,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _DarkMirrorIllusionPainter(
                  time: _animController.value * 10.0,
                  corruption: state.corruptionLevel,
                  tiltX: hw.tiltX,
                  tiltY: hw.tiltY,
                ),
              );
            },
          ),
          // Camera HUD Overlay
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlphaFactor(0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CuteHorrorPalette.cyberCrimson),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: CuteHorrorPalette.cyberCrimson,
                        size: 11,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'REC // FRONT_CAM_01 (DARK MIRROR)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ISO 6400 • ${hw.tiltX.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: CuteHorrorPalette.cyanGlitch,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlphaFactor(0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CuteHorrorPalette.hotPink.withAlphaFactor(0.65),
                ),
              ),
              child: const Text(
                '„Beweg dich nicht... dein Schatten im Display sieht so hübsch aus, wenn ich direkt hinter dir stehe. ♡̷̷̷“',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CuteHorrorPalette.pastelPink,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMirrorIllusionPainter extends CustomPainter {
  final double time;
  final double corruption;
  final double tiltX;
  final double tiltY;

  const _DarkMirrorIllusionPainter({
    required this.time,
    required this.corruption,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Noisy crimson-pink night-vision backdrop
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFF38061B),
            Color(0xFF140109),
            Color(0xFF060003),
          ],
          stops: [0.0, 0.65, 1.0],
        ).createShader(rect),
    );

    final center = size.center(Offset.zero);
    final parallax = Offset(
      (tiltX / 30.0).clamp(-1.0, 1.0) * 18.0,
      (tiltY / 30.0).clamp(-1.0, 1.0) * 12.0,
    );

    // 2. Background Silhouette: Mimi's Twin-Tail Shadow materializing behind the player!
    final mimiAppearAlpha =
        (0.45 + 0.35 * math.sin(time * 2.2) + corruption * 0.2).clamp(0.2, 0.92);
    final mimiCenter =
        center.translate(-size.width * 0.14 - parallax.dx * 0.6, -size.height * 0.08);
    final mimiR = size.shortestSide * 0.25;

    final shadowPaint = Paint()
      ..color = const Color(0xFF050002).withAlphaFactor(mimiAppearAlpha);

    // Mimi's twin-tails & head shadow behind player
    canvas.drawCircle(mimiCenter, mimiR * 0.72, shadowPaint);
    final leftTail = Path()
      ..moveTo(mimiCenter.dx - mimiR * 0.6, mimiCenter.dy - mimiR * 0.3)
      ..quadraticBezierTo(
        mimiCenter.dx - mimiR * 1.3,
        mimiCenter.dy + mimiR * 0.4,
        mimiCenter.dx - mimiR * 0.95,
        mimiCenter.dy + mimiR * 1.4,
      )
      ..lineTo(mimiCenter.dx - mimiR * 0.5, mimiCenter.dy + mimiR * 0.6)
      ..close();
    final rightTail = Path()
      ..moveTo(mimiCenter.dx + mimiR * 0.6, mimiCenter.dy - mimiR * 0.3)
      ..quadraticBezierTo(
        mimiCenter.dx + mimiR * 1.3,
        mimiCenter.dy + mimiR * 0.4,
        mimiCenter.dx + mimiR * 0.95,
        mimiCenter.dy + mimiR * 1.4,
      )
      ..lineTo(mimiCenter.dx + mimiR * 0.5, mimiCenter.dy + mimiR * 0.6)
      ..close();
    canvas.drawPath(leftTail, shadowPaint);
    canvas.drawPath(rightTail, shadowPaint);

    // Mimi's glowing neon-crimson eyes peering over the player's shoulder
    final eyeGlowPaint = Paint()
      ..color = CuteHorrorPalette.cyberCrimson.withAlphaFactor(mimiAppearAlpha);
    canvas.drawCircle(
      mimiCenter.translate(-mimiR * 0.24, -mimiR * 0.04),
      4.5,
      eyeGlowPaint,
    );
    canvas.drawCircle(
      mimiCenter.translate(mimiR * 0.24, -mimiR * 0.04),
      4.5,
      eyeGlowPaint,
    );

    // 3. Foreground Silhouette: Player's own reflection holding the phone
    final playerCenter =
        center.translate(size.width * 0.06 + parallax.dx, size.height * 0.14 + parallax.dy);
    final playerPaint = Paint()
      ..color = const Color(0xFF210410).withAlphaFactor(0.88);
    final rimPaint = Paint()
      ..color = CuteHorrorPalette.hotPink.withAlphaFactor(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Player head & shoulders
    final headRect = Rect.fromCenter(
      center: playerCenter.translate(0, -mimiR * 0.55),
      width: mimiR * 1.15,
      height: mimiR * 1.35,
    );
    canvas.drawOval(headRect, playerPaint);
    canvas.drawOval(headRect, rimPaint);

    final shouldersRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: playerCenter.translate(0, mimiR * 0.65),
        width: mimiR * 2.3,
        height: mimiR * 1.2,
      ),
      const Radius.circular(36),
    );
    canvas.drawRRect(shouldersRect, playerPaint);
    canvas.drawRRect(shouldersRect, rimPaint);

    // 4. Camera Grain & Horizontal Interference Lines
    final rng = math.Random((time * 24.0).floor());
    final grainPaint = Paint()
      ..color = CuteHorrorPalette.pastelPink.withAlphaFactor(0.14);
    for (var i = 0; i < 65; i++) {
      final gx = rng.nextDouble() * size.width;
      final gy = rng.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(gx, gy, 2.0, 2.0), grainPaint);
    }

    // Face-detection reticle around Mimi's shadow behind the player
    final reticleRect = Rect.fromCenter(
      center: mimiCenter,
      width: mimiR * 1.3,
      height: mimiR * 1.3,
    );
    canvas.drawRect(
      reticleRect,
      Paint()
        ..color = CuteHorrorPalette.cyanGlitch.withAlphaFactor(0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _DarkMirrorIllusionPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.corruption != corruption ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY;
  }
}
