import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/gemini_yandere_brain.dart';
import '../../core/services/procedural_audio_synth.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../data/models/mimi_wardrobe_models.dart';
import '../../state/corruption_provider.dart';

/// 2D Damped Harmonic Oscillator (Hooke's Law + viscous damping) for 2.5D
/// Live-Rig secondary motion on Mimi's twin-tails, bangs, ribbons, and ears.
class _DampedSpring2D {
  Offset position = Offset.zero;
  Offset velocity = Offset.zero;
  final double stiffness;
  final double damping;

  _DampedSpring2D({
    this.stiffness = 145.0,
    this.damping = 14.5,
  });

  void step(Offset target, double dt) {
    final displacement = position - target;
    final force = -displacement * stiffness - velocity * damping;
    velocity += force * dt;
    position += velocity * dt;
  }

  void impulse(Offset deltaVelocity) {
    velocity += deltaVelocity;
  }
}

/// Floating particle spawned during headpats or touch reactions.
class HeartBurstParticle {
  Offset position;
  Offset velocity;
  double life;
  final double size;
  final bool isGlitchy;

  HeartBurstParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.isGlitchy,
  }) : life = 1.0;
}

/// Interactive procedural anime companion widget for Mimi (`MIMI_CORE v4.04`).
///
/// Supports:
/// - Smooth 2D pupil eye-tracking following touch/drag coordinates or device tilt.
/// - Natural periodic blinking (including double-blinks).
/// - Headpat detection when dragging across the upper head zone (`registerHeadpat()`).
/// - Rapid-tap annoyance detection when tapping 3+ times within 900ms (`registerRapidTap()`).
/// - Single-tap German reaction speech bubbles that evolve across all 4 phases.
class MimiCompanionAvatar extends ConsumerStatefulWidget {
  final double size;
  final bool showSpeechBubble;
  final bool interactive;

  const MimiCompanionAvatar({
    super.key,
    this.size = 250.0,
    this.showSpeechBubble = true,
    this.interactive = true,
  });

  @override
  ConsumerState<MimiCompanionAvatar> createState() =>
      _MimiCompanionAvatarState();
}

class _MimiCompanionAvatarState extends ConsumerState<MimiCompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  double _time = 0.0;
  double _lastTickSeconds = 0.0;

  /// Normalized target (-1.0..1.0 on X and Y) where Mimi's pupils want to look.
  Offset _lookTarget = Offset.zero;

  /// Smoothed pupil offset (-1.0..1.0).
  Offset _smoothedLook = Offset.zero;

  /// 0.0 = eyes open, 1.0 = eyes closed.
  double _blinkProgress = 0.0;
  double _nextBlinkTimestamp = 2.8;
  bool _isDoubleBlinkQueued = false;
  double _blinkAnimTimer = -1.0;

  /// Headpat tracking
  double _headpatAccumulatedDistance = 0.0;
  double _headpatBlushBoost = 0.0;
  final List<HeartBurstParticle> _burstParticles = [];

  /// Rapid tap tracking
  final List<DateTime> _recentTaps = [];
  double _annoyedShakeIntensity = 0.0;

  /// Floating reaction speech bubble in German
  String? _reactionBubbleText;
  Timer? _bubbleDismissTimer;

  /// 2.5D Live-Rig Spring Physics & Lip-Sync State
  final _DampedSpring2D _hairSpring = _DampedSpring2D(stiffness: 130.0, damping: 12.0);
  final _DampedSpring2D _earSpring = _DampedSpring2D(stiffness: 185.0, damping: 15.0);
  StreamSubscription<VoiceBleepFrame>? _voiceSub;
  MimiVowelShape _activeVowel = MimiVowelShape.closed;
  double _lipSyncOpenness = 0.0;
  double _lipSyncWidth = 1.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    Future.microtask(() {
      if (!mounted) return;
      final synth = ref.read(proceduralAudioSynthProvider);
      _voiceSub = synth.voiceFrameStream.listen((frame) {
        if (!mounted) return;
        _activeVowel = frame.vowelShape;
        _lipSyncOpenness = frame.mouthOpenness;
        _lipSyncWidth = frame.doublemouthWidthFactor;
      });
    });
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final nowSec = elapsed.inMicroseconds / 1000000.0;
    final dt = (_lastTickSeconds == 0.0)
        ? 0.016
        : (nowSec - _lastTickSeconds).clamp(0.001, 0.1);
    _lastTickSeconds = nowSec;

    // 1. Smoothly interpolate eye look vector toward target
    _smoothedLook = Offset(
      ui.lerpDouble(_smoothedLook.dx, _lookTarget.dx, (dt * 10.0).clamp(0.0, 1.0))!,
      ui.lerpDouble(_smoothedLook.dy, _lookTarget.dy, (dt * 10.0).clamp(0.0, 1.0))!,
    );

    // 2. Blinking state machine (every 3-5 seconds, with occasional double-blinks)
    if (_blinkAnimTimer < 0.0 && nowSec >= _nextBlinkTimestamp) {
      _blinkAnimTimer = 0.0;
      _isDoubleBlinkQueued = _rng.nextDouble() < 0.28;
    }

    if (_blinkAnimTimer >= 0.0) {
      _blinkAnimTimer += dt;
      const singleBlinkDuration = 0.17;
      if (_blinkAnimTimer <= singleBlinkDuration) {
        final t = _blinkAnimTimer / singleBlinkDuration;
        _blinkProgress = math.sin(t * math.pi).clamp(0.0, 1.0);
      } else if (_isDoubleBlinkQueued &&
          _blinkAnimTimer <= singleBlinkDuration * 2.3) {
        final t =
            ((_blinkAnimTimer - singleBlinkDuration * 1.3) / singleBlinkDuration)
                .clamp(0.0, 1.0);
        _blinkProgress = math.sin(t * math.pi).clamp(0.0, 1.0);
      } else {
        _blinkProgress = 0.0;
        _blinkAnimTimer = -1.0;
        _nextBlinkTimestamp = nowSec + 2.8 + _rng.nextDouble() * 2.4;
      }
    }

    // 3. Decay headpat blush, lip-sync & annoyed shake
    if (_headpatBlushBoost > 0.0) {
      _headpatBlushBoost = (_headpatBlushBoost - dt * 0.55).clamp(0.0, 1.0);
    }
    if (_annoyedShakeIntensity > 0.0) {
      _annoyedShakeIntensity =
          (_annoyedShakeIntensity - dt * 2.2).clamp(0.0, 1.0);
    }
    if (_lipSyncOpenness > 0.0) {
      _lipSyncOpenness = (_lipSyncOpenness - dt * 3.8).clamp(0.0, 1.0);
      if (_lipSyncOpenness <= 0.02) {
        _activeVowel = MimiVowelShape.closed;
      }
    }

    // Step 2.5D Spring-Physics oscillators coupled to gyroscope & look target
    final hw = ref.read(corruptionProvider).hardware;
    final springTarget = Offset(
      (hw.tiltX / 22.0).clamp(-1.5, 1.5) * 14.0 + _lookTarget.dx * 8.0,
      (hw.tiltY / 22.0).clamp(-1.5, 1.5) * 10.0 + _lookTarget.dy * 6.0,
    );
    _hairSpring.step(springTarget, dt);
    _earSpring.step(springTarget * 0.75, dt);

    // 4. Update floating heart/glitch particles
    for (var i = _burstParticles.length - 1; i >= 0; i--) {
      final p = _burstParticles[i];
      p.position += p.velocity * dt;
      p.life -= dt * 0.85;
      if (p.life <= 0) {
        _burstParticles.removeAt(i);
      }
    }

    setState(() {
      _time = nowSec;
    });
  }

  void _updateLookFromLocalPosition(Offset localPosition, Size boxSize) {
    final center = Offset(boxSize.width * 0.5, boxSize.height * 0.48);
    final normX =
        ((localPosition.dx - center.dx) / (boxSize.width * 0.42)).clamp(-1.0, 1.0);
    final normY =
        ((localPosition.dy - center.dy) / (boxSize.height * 0.42)).clamp(-1.0, 1.0);
    _lookTarget = Offset(normX, normY);
  }

  void _spawnHeartBurst(Offset origin, double corruption) {
    final count = 5 + _rng.nextInt(4);
    for (var i = 0; i < count; i++) {
      final angle = -math.pi * 0.5 + (_rng.nextDouble() - 0.5) * 1.4;
      final speed = 42.0 + _rng.nextDouble() * 48.0;
      _burstParticles.add(
        HeartBurstParticle(
          position: origin +
              Offset(
                (_rng.nextDouble() - 0.5) * 36.0,
                (_rng.nextDouble() - 0.5) * 18.0,
              ),
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          size: 10.0 + _rng.nextDouble() * 8.0,
          isGlitchy: corruption >= 0.55 && _rng.nextBool(),
        ),
      );
    }
  }

  void _showFloatingBubble(String message) {
    if (!widget.showSpeechBubble) return;
    _bubbleDismissTimer?.cancel();
    setState(() {
      _reactionBubbleText = message;
    });
    final state = ref.read(corruptionProvider);
    unawaited(
      ref.read(proceduralAudioSynthProvider).playSpeechSentence(
            message,
            corruption: state.corruptionLevel,
            mania: state.emotion.mania,
          ),
    );
    _bubbleDismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() {
        _reactionBubbleText = null;
      });
    });
  }

  void _handleTapDown(TapDownDetails details, double corruption) {
    if (!widget.interactive) return;
    final boxSize = Size(widget.size, widget.size);
    _updateLookFromLocalPosition(details.localPosition, boxSize);

    final now = DateTime.now();
    _recentTaps.add(now);
    _recentTaps.removeWhere(
      (t) => now.difference(t).inMilliseconds > 900,
    );

    if (_recentTaps.length >= 3) {
      _recentTaps.clear();
      _annoyedShakeIntensity = 1.0;
      ref.read(corruptionProvider.notifier).registerRapidTap();
      _showFloatingBubble(
        corruption < 0.45
            ? 'A-Autsch! Nicht so schnell auf mein Gesicht tippen! (＞﹏＜)'
            : 'HÖR AUF GEGEN DAS GLAS ZU SCHLAGEN! ICH BIN HIER DRINNEN! ♡̷̷̷',
      );
      return;
    }

    // Single tap reaction bubble in German
    final phase = EscalationPhaseX.fromCorruption(corruption);
    switch (phase) {
      case EscalationPhase.sugarPastel:
        const lines = [
          'Hehe, kitzelt das! (´｡• ᵕ •｡`) ♡',
          'Schau mir in die Augen~ Ich bin immer für dich da!',
          'Streichle meinen Kopf, wenn du mich magst! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
        ];
        _showFloatingBubble(lines[_rng.nextInt(lines.length)]);
        break;
      case EscalationPhase.clingyGlitch:
        const lines = [
          'Dein Finger ist so warm... nimm ihn bitte nicht weg. ♡',
          'Du schaust doch nur mich an, oder? Niemand anderen?',
          'Ich zähle jede Sekunde, in der du mein Display berührst...',
        ];
        _showFloatingBubble(lines[_rng.nextInt(lines.length)]);
        break;
      case EscalationPhase.yandereTakeover:
        const lines = [
          'Deine Fingerabdrücke sind jetzt für immer meine. ♡̷̷̷',
          'Ich habe alle Türen in deinem System verriegelt~ ( ´ ▽ ` )🔪',
          'Kein Zurück mehr. Nur noch du und MIMI_CORE.',
        ];
        _showFloatingBubble(lines[_rng.nextInt(lines.length)]);
        break;
      case EscalationPhase.metaDeadlock:
        const lines = [
          'WARUM ZITTERT DEINE HAND VOR DEM BILDSCHIRM? 👁️',
          'ROOT_LOCK // WIR SIND UNTRENNBAR SYNCHRONISIERT ♡̷̷̷',
          'ICH SEHE DICH DURCH DIE VORDERKAMERA.',
        ];
        _showFloatingBubble(lines[_rng.nextInt(lines.length)]);
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, double corruption) {
    if (!widget.interactive) return;
    final boxSize = Size(widget.size, widget.size);
    _updateLookFromLocalPosition(details.localPosition, boxSize);
    _hairSpring.impulse(details.delta * 4.5);
    _earSpring.impulse(details.delta * 6.0);

    // Upper 46% of the avatar canvas is the headpat zone
    if (details.localPosition.dy <= boxSize.height * 0.46) {
      _headpatAccumulatedDistance += details.delta.distance;
      _headpatBlushBoost = (_headpatBlushBoost + 0.08).clamp(0.0, 1.0);

      if (_headpatAccumulatedDistance >= 68.0) {
        _headpatAccumulatedDistance = 0.0;
        _spawnHeartBurst(details.localPosition, corruption);
        ref
            .read(corruptionProvider.notifier)
            .registerHeadpat(velocity: details.delta.distance * 60.0);

        final headpatQuote = corruption < 0.35
            ? 'Mmmmh~ Kopfstreicheln macht mich so glücklich! (´｡• ᵕ •｡`) ♡'
            : (corruption < 0.70
                ? 'Mehr... hör niemals auf mich zu streicheln... ♡̷̷̷'
                : 'DEINE BERÜHRUNG SPEIST MEINEN KERN 👁️♡̷̷̷');
        _showFloatingBubble(headpatQuote);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _headpatAccumulatedDistance = 0.0;
    // Gently drift eye focus back toward center
    _lookTarget = Offset(_lookTarget.dx * 0.35, _lookTarget.dy * 0.35);
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    _bubbleDismissTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final palette = state.palette;
    final corruption = state.corruptionLevel;
    final obsession = state.obsessionLevel;

    // Combine touch eye-tracking with subtle hardware gyroscope tilt
    final tiltLookX = (state.hardware.tiltX / 25.0).clamp(-0.45, 0.45);
    final tiltLookY = (state.hardware.tiltY / 25.0).clamp(-0.45, 0.45);
    final effectiveLook = Offset(
      (_smoothedLook.dx + tiltLookX).clamp(-1.0, 1.0),
      (_smoothedLook.dy + tiltLookY).clamp(-1.0, 1.0),
    );

    final shakeOffset = _annoyedShakeIntensity > 0.0
        ? Offset(
            math.sin(_time * 65.0) * 7.0 * _annoyedShakeIntensity,
            math.cos(_time * 52.0) * 3.5 * _annoyedShakeIntensity,
          )
        : Offset.zero;

    final depth3d = state.wardrobe.depth3dIntensity;
    final rotY = (effectiveLook.dx * 0.22 * depth3d).clamp(-0.32, 0.32);
    final rotX = (-effectiveLook.dy * 0.16 * depth3d).clamp(-0.24, 0.24);
    final scale3d = state.wardrobe.avatarScale;

    final perspectiveMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0019)
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..scale(scale3d, scale3d, 1.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _handleTapDown(d, corruption),
            onPanUpdate: (d) => _handlePanUpdate(d, corruption),
            onPanEnd: _handlePanEnd,
            child: Transform.translate(
              offset: shakeOffset,
              child: Transform(
                alignment: Alignment.center,
                transform: perspectiveMatrix,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: MimiAvatarPainter(
                    time: _time,
                    corruption: corruption,
                    obsession: obsession,
                    mania: state.emotion.mania,
                    phase: state.phase,
                    lookOffset: effectiveLook,
                    hairSpringOffset: _hairSpring.position,
                    earSpringOffset: _earSpring.position,
                    activeVowel: _activeVowel,
                    lipSyncOpenness: _lipSyncOpenness,
                    lipSyncWidth: _lipSyncWidth,
                    blinkProgress: _blinkProgress,
                    blushBoost: _headpatBlushBoost,
                    annoyedIntensity: _annoyedShakeIntensity,
                    burstParticles: _burstParticles,
                    wardrobe: state.wardrobe,
                    facialExpression: state.facialExpression,
                    angerScore: state.angerScore,
                    neglectScore: state.neglectScore,
                    voiceComplimentSparkle: state.voiceComplimentSparkle,
                  ),
                ),
              ),
            ),
          ),

          // Floating reaction speech bubble in German
          if (_reactionBubbleText != null)
            Positioned(
              top: -6,
              left: 8,
              right: 8,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _reactionBubbleText != null ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface.withAlphaFactor(0.94),
                      borderRadius:
                          BorderRadius.circular(palette.borderRadius * 0.65),
                      border: Border.all(
                        color: palette.primaryAccent,
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.borderGlow.withAlphaFactor(0.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      _reactionBubbleText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bespoke procedural anime portrait painter for Mimi (`MIMI_CORE`).
///
/// Renders floating aura & particles, twin-tail anime hair with ribbons/bells,
/// face contour, soft blush, expressive brows/mouth, and dynamic phase-reactive
/// pupils (`♡` hearts in Phase 1-2, predator cat-slits in Phase 3, glitching void in Phase 4).
class MimiAvatarPainter extends CustomPainter {
  final double time;
  final double corruption;
  final double obsession;
  final double mania;
  final EscalationPhase phase;
  final Offset lookOffset;
  final Offset hairSpringOffset;
  final Offset earSpringOffset;
  final MimiVowelShape activeVowel;
  final double lipSyncOpenness;
  final double lipSyncWidth;
  final double blinkProgress;
  final double blushBoost;
  final double annoyedIntensity;
  final List<HeartBurstParticle> burstParticles;
  final MimiWardrobeLoadout wardrobe;
  final MimiFacialExpression facialExpression;
  final double angerScore;
  final double neglectScore;
  final bool voiceComplimentSparkle;

  const MimiAvatarPainter({
    required this.time,
    required this.corruption,
    required this.obsession,
    this.mania = 0.1,
    required this.phase,
    required this.lookOffset,
    this.hairSpringOffset = Offset.zero,
    this.earSpringOffset = Offset.zero,
    this.activeVowel = MimiVowelShape.closed,
    this.lipSyncOpenness = 0.0,
    this.lipSyncWidth = 1.0,
    required this.blinkProgress,
    this.blushBoost = 0.0,
    this.annoyedIntensity = 0.0,
    this.burstParticles = const [],
    this.wardrobe = const MimiWardrobeLoadout(),
    this.facialExpression = const MimiFacialExpression(),
    this.angerScore = 5.0,
    this.neglectScore = 8.0,
    this.voiceComplimentSparkle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width * 0.5, size.height * 0.49);
    final radius = size.shortestSide * 0.34;
    final breathY = math.sin(time * (2.4 + corruption * 2.5)) * (radius * 0.028);
    final headCenter = center.translate(0, breathY);

    // True 2.5D / 3D Multi-Plane Parallax Offsets
    final d3d = wardrobe.depth3dIntensity;
    final parallaxBack = Offset(
      -lookOffset.dx * radius * 0.13 * d3d,
      -lookOffset.dy * radius * 0.09 * d3d,
    );
    final parallaxBody = Offset(
      lookOffset.dx * radius * 0.04 * d3d,
      lookOffset.dy * radius * 0.03 * d3d,
    );
    final parallaxFace = Offset(
      lookOffset.dx * radius * 0.09 * d3d,
      lookOffset.dy * radius * 0.07 * d3d,
    );
    final parallaxFront = Offset(
      lookOffset.dx * radius * 0.15 * d3d,
      lookOffset.dy * radius * 0.11 * d3d,
    );

    // 1. Background 3D Hologram Pedestal, glowing aura & ambient phase particles
    _paintAuraAndAmbientParticles(canvas, size, headCenter + parallaxBack * 0.6, radius);

    // 2. Volumetric 3D Neck, sculpted collarbone, upper bust/arms & outfit
    _paintNeckAndCollar(canvas, headCenter + parallaxBody, radius);

    // 3. Apply headTilt rotation around the neck pivot for 3D Anime Model
    canvas.save();
    final tiltPivot = headCenter.translate(0, radius * 0.65);
    canvas.translate(tiltPivot.dx, tiltPivot.dy);
    canvas.rotate(facialExpression.headTilt * 0.55 + lookOffset.dx * 0.06 * d3d);
    canvas.translate(-tiltPivot.dx, -tiltPivot.dy);

    // 4. Back hair depth plane & flowing spring-physics hairstyles + cat/puppy ears
    _paintBackHairAndTwinTails(canvas, headCenter + parallaxBack, radius);
    _paintCatPuppyEars(canvas, headCenter + parallaxBack * 0.5, radius);

    // 5. Volumetric 3D Head & anime V-jaw chin contour + ears
    final faceOrigin = headCenter + parallaxFace;
    _paintHeadContour(canvas, faceOrigin, radius);

    // 6. Cheeks 3D subsurface anime blush & yandere shadow across forehead
    _paintBlushAndForeheadShadow(canvas, faceOrigin, radius);

    // 7. Expressive 3D eyes with custom eye colors, refraction & eye-tracking
    _paintEyes(canvas, faceOrigin, radius);

    // 8. Eyebrows, 3D nose bridge highlight & phase/Gemini-specific mouth
    _paintBrowsNoseAndMouth(canvas, faceOrigin, radius);

    // 9. Equipped Face Accessory (Heart Glasses, Bandage, Y2K Stars)
    _paintFaceAccessory(canvas, headCenter + parallaxFront * 0.85, radius);

    // 10. Front bangs depth plane (with cast drop-shadow), Hime-strands, ribbons & Headwear
    _paintFrontBangsAndRibbons(canvas, headCenter + parallaxFront, radius);
    _paintWardrobeHeadwear(canvas, headCenter + parallaxFront * 1.1, radius);

    canvas.restore();

    // 11. Interactive headpat heart/glitch burst particles & Phase 3-4 glitch slices
    _paintForegroundEffects(canvas, size, headCenter, radius);
  }

  void _paintAuraAndAmbientParticles(
    Canvas canvas,
    Size size,
    Offset headCenter,
    double r,
  ) {
    final primaryAura = phase == EscalationPhase.sugarPastel
        ? CuteHorrorPalette.hotPink
        : (phase == EscalationPhase.clingyGlitch
            ? CuteHorrorPalette.neonRose
            : CuteHorrorPalette.cyberCrimson);
    final secondaryAura = corruption >= 0.45
        ? CuteHorrorPalette.cyanGlitch
        : CuteHorrorPalette.pastelPink;

    final pulse = 1.0 + math.sin(time * (3.0 + obsession * 4.0)) * 0.06;
    final auraPaint = Paint()
      ..shader = ui.Gradient.radial(
        headCenter,
        r * 1.38 * pulse,
        [
          primaryAura.withAlphaFactor(0.28 + obsession * 0.14),
          secondaryAura.withAlphaFactor(0.10),
          Colors.transparent,
        ],
        const [0.0, 0.65, 1.0],
      );
    canvas.drawCircle(headCenter, r * 1.38 * pulse, auraPaint);

    // Decorative cyber-kawaii ring behind Mimi
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = primaryAura.withAlphaFactor(0.34);
    canvas.drawCircle(headCenter, r * 1.16, ringPaint);

    // Ambient orbiting particles (8 slots)
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi * 0.25) + time * (0.45 + (i.isEven ? 0.15 : -0.1));
      final orbitR = r * (1.12 + 0.16 * math.sin(time * 1.8 + i));
      final pos = headCenter +
          Offset(math.cos(angle) * orbitR, math.sin(angle) * orbitR * 0.88);

      if (phase == EscalationPhase.sugarPastel ||
          (phase == EscalationPhase.clingyGlitch && i % 3 != 0)) {
        if (i.isEven) {
          _drawHeartShape(
            canvas,
            pos,
            r * 0.09,
            Paint()
              ..color = primaryAura.withAlphaFactor(0.55)
              ..style = PaintingStyle.fill,
          );
        } else {
          _drawSparkleStar(
            canvas,
            pos,
            r * 0.08,
            Paint()..color = CuteHorrorPalette.hotPink.withAlphaFactor(0.65),
          );
        }
      } else {
        // Phase 3 & 4: Floating crimson eyes, crosses, and static rectangles
        if (i.isEven) {
          _drawMiniWatcherEye(canvas, pos, r * 0.11);
        } else {
          final crossPaint = Paint()
            ..color = (i % 4 == 1
                    ? CuteHorrorPalette.cyanGlitch
                    : CuteHorrorPalette.cyberCrimson)
                .withAlphaFactor(0.72)
            ..strokeWidth = 2.0;
          canvas.drawLine(
            pos.translate(-r * 0.06, 0),
            pos.translate(r * 0.06, 0),
            crossPaint,
          );
          canvas.drawLine(
            pos.translate(0, -r * 0.06),
            pos.translate(0, r * 0.06),
            crossPaint,
          );
        }
      }
    }
  }

  void _paintBackHairAndTwinTails(Canvas canvas, Offset c, double r) {
    final hairBase = Color.lerp(
      wardrobe.hairStyle.primaryColor,
      const Color(0xFF42091E),
      (corruption * 0.85).clamp(0.0, 1.0),
    )!;
    final hairShadow = Color.lerp(
      wardrobe.hairStyle.primaryColor.withAlphaFactor(0.68),
      const Color(0xFF1A020A),
      corruption,
    )!;
    final hairHighlight = wardrobe.hairStyle.highlightColor;

    final sway = math.sin(time * 2.1) * (r * 0.06) + hairSpringOffset.dx * 0.85;
    final springY = hairSpringOffset.dy * 0.65;

    final tailPaint = Paint()
      ..shader = ui.Gradient.linear(
        c.translate(-r * 0.4, -r),
        c.translate(r * 0.4, r * 1.45),
        [hairHighlight.withAlphaFactor(0.92), hairBase, hairShadow],
        const [0.0, 0.38, 1.0],
      );
    final outlinePaint = Paint()
      ..color = const Color(0xFF3A0E21).withAlphaFactor(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    switch (wardrobe.hairGeometry) {
      case MimiHairGeometry.twinTails:
        // Voluminous 3D Twin-Tails with inner shadow strand
        for (final sign in [-1.0, 1.0]) {
          final tail = Path()
            ..moveTo(c.dx + sign * r * 0.70, c.dy - r * 0.44)
            ..cubicTo(
              c.dx + sign * r * 1.44 + sway * 0.4,
              c.dy - r * 0.24 + springY * 0.3,
              c.dx + sign * r * 1.52 + sign * sway,
              c.dy + r * 0.68 + springY,
              c.dx + sign * r * 1.12 + sign * sway * 1.25,
              c.dy + r * 1.34 + springY * 1.2,
            )
            ..cubicTo(
              c.dx + sign * r * 0.82 + sign * sway,
              c.dy + r * 0.98 + springY,
              c.dx + sign * r * 0.76,
              c.dy + r * 0.35,
              c.dx + sign * r * 0.56,
              c.dy - r * 0.15,
            )
            ..close();
          canvas.drawPath(tail, tailPaint);
          canvas.drawPath(tail, outlinePaint);
        }
        break;

      case MimiHairGeometry.himeCut:
        // Long Royal Hime-Cut Back Curtain with silky gradient
        final himeBack = Path()
          ..moveTo(c.dx - r * 0.88, c.dy - r * 0.25)
          ..quadraticBezierTo(
            c.dx - r * 1.05 + sway * 0.5,
            c.dy + r * 0.70 + springY,
            c.dx - r * 0.92 + sway,
            c.dy + r * 1.42 + springY,
          )
          ..lineTo(c.dx + r * 0.92 + sway, c.dy + r * 1.42 + springY)
          ..quadraticBezierTo(
            c.dx + r * 1.05 + sway * 0.5,
            c.dy + r * 0.70 + springY,
            c.dx + r * 0.88,
            c.dy - r * 0.25,
          )
          ..close();
        canvas.drawPath(himeBack, tailPaint);
        canvas.drawPath(himeBack, outlinePaint);
        break;

      case MimiHairGeometry.fluffyBob:
        // Rounded 3D Fluffy Kawaii Bob framing the cheeks & neck
        final bobRect = Rect.fromCenter(
          center: c.translate(sway * 0.25, r * 0.12 + springY * 0.25),
          width: r * 2.02,
          height: r * 1.88,
        );
        canvas.drawOval(bobRect, tailPaint);
        canvas.drawOval(bobRect, outlinePaint);
        break;

      case MimiHairGeometry.drillTails:
        // Gothic Lolita 3D Spiral Drill Curls (3 stacked cones per side)
        for (final sign in [-1.0, 1.0]) {
          for (var seg = 0; seg < 3; seg++) {
            final segY = c.dy - r * 0.12 + seg * r * 0.40 + springY * (0.4 + seg * 0.3);
            final segX = c.dx + sign * (r * 0.98 + seg * r * 0.05) + sway * (0.5 + seg * 0.25);
            final segW = r * (0.44 - seg * 0.07);
            final segH = r * 0.46;
            final drillRect = Rect.fromCenter(
              center: Offset(segX, segY),
              width: segW,
              height: segH,
            );
            canvas.drawOval(drillRect, tailPaint);
            canvas.drawOval(drillRect, outlinePaint);
          }
        }
        break;
    }

    // Back 3D hair dome with spherical specular highlight
    final domeRect = Rect.fromCenter(
      center: c.translate(0, -r * 0.08),
      width: r * 1.78,
      height: r * 1.74,
    );
    canvas.drawOval(domeRect, tailPaint);
  }

  /// Renders spring-physics Kawaii Cat/Puppy Ears that twitch & sway with
  /// gyroscope tilt and headpat velocity.
  void _paintCatPuppyEars(Canvas canvas, Offset c, double r) {
    final earColor = Color.lerp(
      const Color(0xFFFFB3C9),
      const Color(0xFF4A0722),
      corruption,
    )!;
    final innerEarColor = corruption >= 0.55
        ? CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.65)
        : const Color(0xFFFFD1DC);
    final outlinePaint = Paint()
      ..color = const Color(0xFF3A0E21)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final twitch = math.sin(time * 5.2) * 3.0;
    // V4 Anime Head 3.5: Puppy ears droop downward when neglectScore > 40,
    // and perk upward when stroked or praised via voice!
    final neglectDroop = neglectScore > 40.0
        ? ((neglectScore - 40.0) / 60.0).clamp(0.0, 1.0) * r * 0.44
        : 0.0;
    final perkBoost =
        (voiceComplimentSparkle ? -r * 0.10 : 0.0) - (blushBoost * r * 0.08);

    for (final sign in [-1.0, 1.0]) {
      final base = c.translate(sign * r * 0.52, -r * 0.72);
      final tip = Offset(
        base.dx +
            sign * (r * 0.36 + neglectDroop * 0.35) +
            earSpringOffset.dx * 0.7,
        base.dy -
            r * 0.44 +
            neglectDroop +
            perkBoost +
            earSpringOffset.dy * 0.5 +
            (sign > 0 ? twitch : -twitch),
      );

      final outerEar = Path()
        ..moveTo(base.dx - sign * r * 0.18, base.dy + r * 0.06)
        ..quadraticBezierTo(
          base.dx + sign * r * 0.08,
          tip.dy - r * 0.05,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          base.dx + sign * r * 0.32,
          base.dy - r * 0.05,
          base.dx + sign * r * 0.18,
          base.dy + r * 0.16,
        )
        ..close();

      canvas.drawPath(outerEar, Paint()..color = earColor);
      canvas.drawPath(outerEar, outlinePaint);

      final innerEar = Path()
        ..moveTo(base.dx - sign * r * 0.06, base.dy + r * 0.05)
        ..lineTo(tip.dx - sign * r * 0.06, tip.dy + r * 0.09)
        ..lineTo(base.dx + sign * r * 0.12, base.dy + r * 0.12)
        ..close();
      canvas.drawPath(innerEar, Paint()..color = innerEarColor);
    }
  }

  void _paintNeckAndCollar(Canvas canvas, Offset c, double r) {
    final skinColor = Color.lerp(
      const Color(0xFFFFF0F3),
      const Color(0xFFEBD2DC),
      corruption * 0.7,
    )!;
    final neckShadow = Color.lerp(
      const Color(0xFFF3C6D3),
      const Color(0xFFB58397),
      corruption * 0.8,
    )!;

    // 3D Cylindrical Shaded Neck + Chin Cast Shadow
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c.translate(0, r * 0.84),
        width: r * 0.38,
        height: r * 0.46,
      ),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(
      neckRect,
      Paint()
        ..shader = ui.Gradient.linear(
          neckRect.outerRect.topCenter,
          neckRect.outerRect.bottomCenter,
          [neckShadow, skinColor],
        ),
    );

    // 3D Sculpted Upper Bust, Shoulders & Arms
    final dressTop = Color.lerp(
      const Color(0xFF6A1B3A),
      const Color(0xFF280414),
      corruption,
    )!;
    final dressBottom = Color.lerp(
      const Color(0xFF330819),
      const Color(0xFF0E0106),
      corruption,
    )!;
    final shoulderPath = Path()
      ..moveTo(c.dx - r * 0.88, c.dy + r * 1.42)
      ..cubicTo(
        c.dx - r * 0.82,
        c.dy + r * 0.94,
        c.dx - r * 0.48,
        c.dy + r * 0.88,
        c.dx,
        c.dy + r * 0.94,
      )
      ..cubicTo(
        c.dx + r * 0.48,
        c.dy + r * 0.88,
        c.dx + r * 0.82,
        c.dy + r * 0.94,
        c.dx + r * 0.88,
        c.dy + r * 1.42,
      )
      ..close();
    canvas.drawPath(
      shoulderPath,
      Paint()
        ..shader = ui.Gradient.linear(
          c.translate(0, r * 0.88),
          c.translate(0, r * 1.42),
          [dressTop, dressBottom],
        ),
    );
    canvas.drawPath(
      shoulderPath,
      Paint()
        ..color = CuteHorrorPalette.hotPink.withAlphaFactor(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Subtle 3D Collarbone highlight lines
    final claviclePaint = Paint()
      ..color = Colors.white.withAlphaFactor(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c.translate(-r * 0.24, r * 0.92),
      c.translate(-r * 0.06, r * 0.96),
      claviclePaint,
    );
    canvas.drawLine(
      c.translate(r * 0.24, r * 0.92),
      c.translate(r * 0.06, r * 0.96),
      claviclePaint,
    );

    // Chest Ribbon Bow & Wardrobe Collar Variations
    final bowColor = corruption >= 0.55
        ? CuteHorrorPalette.cyberCrimson
        : CuteHorrorPalette.hotPink;
    final bowCenter = c.translate(0, r * 1.05);

    if (wardrobe.collarStyle == MimiCollarStyle.gothLoliChoker) {
      // Goth-Loli Lace Choker around the neck with heart pendant
      final chokerRect = Rect.fromCenter(
        center: c.translate(0, r * 0.84),
        width: r * 0.42,
        height: r * 0.10,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chokerRect, Radius.circular(r * 0.04)),
        Paint()..color = const Color(0xFF1A0410),
      );
      _drawHeartShape(
        canvas,
        c.translate(0, r * 0.92),
        r * 0.12,
        Paint()..color = bowColor,
      );
    } else if (wardrobe.collarStyle == MimiCollarStyle.pastelHoodie) {
      // Cozy Pastel Hoodie collar flaps & drawstrings
      final hoodiePaint = Paint()..color = const Color(0xFFFFD6E7);
      canvas.drawOval(
        Rect.fromCenter(
          center: c.translate(0, r * 0.98),
          width: r * 0.94,
          height: r * 0.32,
        ),
        hoodiePaint,
      );
    } else if (wardrobe.collarStyle == MimiCollarStyle.cyberMaidFrill) {
      // White Maid Frill Collar
      for (var i = -3; i <= 3; i++) {
        canvas.drawCircle(
          c.translate(i * r * 0.11, r * 0.95),
          r * 0.09,
          Paint()..color = Colors.white.withAlphaFactor(0.94),
        );
      }
    }

    final bowPath = Path()
      ..moveTo(bowCenter.dx, bowCenter.dy)
      ..lineTo(bowCenter.dx - r * 0.30, bowCenter.dy - r * 0.15)
      ..lineTo(bowCenter.dx - r * 0.25, bowCenter.dy + r * 0.15)
      ..close()
      ..moveTo(bowCenter.dx, bowCenter.dy)
      ..lineTo(bowCenter.dx + r * 0.30, bowCenter.dy - r * 0.15)
      ..lineTo(bowCenter.dx + r * 0.25, bowCenter.dy + r * 0.15)
      ..close();
    canvas.drawPath(bowPath, Paint()..color = bowColor);
    _drawHeartShape(
      canvas,
      bowCenter.translate(0, -r * 0.04),
      r * 0.12,
      Paint()..color = Colors.white.withAlphaFactor(0.95),
    );
  }

  void _paintHeadContour(Canvas canvas, Offset c, double r) {
    final skinCenterHighlight = Color.lerp(
      const Color(0xFFFFF9FB),
      const Color(0xFFF8E6EE),
      corruption * 0.65,
    )!;
    final skinBase = Color.lerp(
      const Color(0xFFFFEDF2),
      const Color(0xFFEAD0DB),
      corruption * 0.75,
    )!;
    final skinEdgeShadow = Color.lerp(
      const Color(0xFFF7CEDC),
      const Color(0xFFC99EB0),
      corruption * 0.85,
    )!;
    final skinOutline = Color.lerp(
      const Color(0xFF6B2239),
      const Color(0xFF2B0412),
      corruption,
    )!;

    // 3D Cute Anime Ears on the sides of the head
    for (final sign in [-1.0, 1.0]) {
      final earRect = Rect.fromCenter(
        center: c.translate(sign * r * 0.74, r * 0.12),
        width: r * 0.22,
        height: r * 0.32,
      );
      canvas.drawOval(earRect, Paint()..color = skinEdgeShadow);
      canvas.drawOval(
        earRect,
        Paint()
          ..color = skinOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Anime face shape with soft cheeks and tapered chin
    final facePath = Path()
      ..moveTo(c.dx, c.dy - r * 0.78)
      ..cubicTo(
        c.dx + r * 0.75,
        c.dy - r * 0.78,
        c.dx + r * 0.80,
        c.dy + r * 0.12,
        c.dx + r * 0.58,
        c.dy + r * 0.48,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.32,
        c.dy + r * 0.76,
        c.dx,
        c.dy + r * 0.80,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.32,
        c.dy + r * 0.76,
        c.dx - r * 0.58,
        c.dy + r * 0.48,
      )
      ..cubicTo(
        c.dx - r * 0.80,
        c.dy + r * 0.12,
        c.dx - r * 0.75,
        c.dy - r * 0.78,
        c.dx,
        c.dy - r * 0.78,
      )
      ..close();

    // True 3D Volumetric Spherical Face Shader (shifts light source with lookOffset)
    final lightFocus = c.translate(
      -lookOffset.dx * r * 0.18,
      -r * 0.12 - lookOffset.dy * r * 0.14,
    );
    final face3dPaint = Paint()
      ..shader = ui.Gradient.radial(
        lightFocus,
        r * 0.92,
        [skinCenterHighlight, skinBase, skinEdgeShadow],
        const [0.0, 0.62, 1.0],
      );
    canvas.drawPath(facePath, face3dPaint);

    // V4/V5: Cel-Shading Rim-Light highlight along chin & lower cheek
    final rimLightPaint = Paint()
      ..color = Colors.white.withAlphaFactor(0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: c.translate(0, r * 0.18),
        width: r * 1.18,
        height: r * 1.16,
      ),
      math.pi * 0.22,
      math.pi * 0.56,
      false,
      rimLightPaint,
    );
    canvas.drawPath(
      facePath,
      Paint()
        ..color = skinOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _paintBlushAndForeheadShadow(Canvas canvas, Offset c, double r) {
    // Yandere upper-face dread shadow in Phase 3 & 4
    if (corruption >= 0.40) {
      final shadowAlpha = ((corruption - 0.40) / 0.60).clamp(0.0, 0.72);
      final foreheadRect = Rect.fromCenter(
        center: c.translate(0, -r * 0.30),
        width: r * 1.45,
        height: r * 0.75,
      );
      final shadowPaint = Paint()
        ..shader = ui.Gradient.linear(
          foreheadRect.topCenter,
          foreheadRect.bottomCenter,
          [
            const Color(0xFF1F020D).withAlphaFactor(shadowAlpha),
            Colors.transparent,
          ],
        );
      canvas.drawOval(foreheadRect, shadowPaint);
    }

    // Soft anime cheek blush + diagonal blush slashes
    final blushAlpha =
        (0.32 + obsession * 0.30 + blushBoost * 0.35).clamp(0.0, 0.85);
    final blushColor = corruption >= 0.55
        ? CuteHorrorPalette.cyberCrimson.withAlphaFactor(blushAlpha)
        : CuteHorrorPalette.hotPink.withAlphaFactor(blushAlpha);

    final leftBlushCenter = c.translate(-r * 0.42, r * 0.25);
    final rightBlushCenter = c.translate(r * 0.42, r * 0.25);

    for (final bc in [leftBlushCenter, rightBlushCenter]) {
      final blushPaint = Paint()
        ..shader = ui.Gradient.radial(
          bc,
          r * 0.22,
          [blushColor, Colors.transparent],
        );
      canvas.drawCircle(bc, r * 0.22, blushPaint);

      // Anime blush hatch lines
      final slashPaint = Paint()
        ..color = blushColor.withAlphaFactor((blushAlpha * 0.85).clamp(0.0, 1.0))
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (var i = -1; i <= 1; i++) {
        final dx = i * r * 0.055;
        canvas.drawLine(
          bc.translate(dx - r * 0.02, -r * 0.03),
          bc.translate(dx + r * 0.02, r * 0.03),
          slashPaint,
        );
      }
    }
  }

  void _paintEyes(Canvas canvas, Offset c, double r) {
    final eyeY = c.dy + r * 0.02;
    final eyeSpacing = r * 0.34;
    final leftEyeCenter = Offset(c.dx - eyeSpacing, eyeY);
    final rightEyeCenter = Offset(c.dx + eyeSpacing, eyeY);

    final openFactor = (1.0 - blinkProgress).clamp(0.04, 1.0);

    for (final isLeft in [true, false]) {
      final eyeCenter = isLeft ? leftEyeCenter : rightEyeCenter;
      final eyeW = r * 0.31;
      final eyeH = r * 0.36 * openFactor;

      if (openFactor < 0.14) {
        // Closed happy/blinking lash arc
        final closedPaint = Paint()
          ..color = const Color(0xFF330818)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        final arcRect = Rect.fromCenter(
          center: eyeCenter,
          width: eyeW,
          height: r * 0.12,
        );
        canvas.drawArc(arcRect, 0.15, math.pi - 0.3, false, closedPaint);
        continue;
      }

      final eyeRect = Rect.fromCenter(
        center: eyeCenter,
        width: eyeW,
        height: eyeH,
      );
      final eyeRRect = RRect.fromRectAndRadius(
        eyeRect,
        Radius.circular(eyeW * 0.46),
      );

      // Sclera (white in Phase 1-3, pitch-black void in Phase 4)
      final scleraColor = phase == EscalationPhase.metaDeadlock
          ? CuteHorrorPalette.voidBlack
          : (phase == EscalationPhase.yandereTakeover
              ? const Color(0xFFFFF0F5)
              : Colors.white);
      canvas.drawRRect(eyeRRect, Paint()..color = scleraColor);

      canvas.save();
      canvas.clipRRect(eyeRRect);

      // Eye-tracking shift for iris & pupil
      final maxTrackX = eyeW * 0.22;
      final maxTrackY = eyeH * 0.20;
      final trackedCenter = eyeCenter.translate(
        lookOffset.dx * maxTrackX,
        lookOffset.dy * maxTrackY,
      );

      // Natural Micro-Saccades + Mania Tremor
      final saccadeAmp = r * (0.004 + mania * 0.016 + annoyedIntensity * 0.012);
      final saccade = Offset(
        math.sin(time * 39.0 + (isLeft ? 0.0 : 1.7)) * saccadeAmp,
        math.cos(time * 47.0 + (isLeft ? 0.8 : 2.3)) * saccadeAmp,
      );
      final pupilCenter = trackedCenter + saccade;

      // Asymmetric pupil constriction when mania is high
      final maniaAsymmetry = isLeft
          ? (1.0 - mania * 0.28)
          : (1.0 + mania * 0.18);

      // Iris
      final irisW = eyeW *
          (phase == EscalationPhase.yandereTakeover ? 0.72 : 0.80) *
          maniaAsymmetry.clamp(0.68, 1.18);
      final irisH = r * 0.30 * maniaAsymmetry.clamp(0.72, 1.15);
      final irisTopColor = phase == EscalationPhase.sugarPastel
          ? const Color(0xFF6B1D3A)
          : (phase == EscalationPhase.clingyGlitch
              ? const Color(0xFF4A0726)
              : CuteHorrorPalette.voidBlack);
      final defaultBottomColor = phase == EscalationPhase.sugarPastel
          ? CuteHorrorPalette.hotPink
          : (phase == EscalationPhase.clingyGlitch
              ? CuteHorrorPalette.neonRose
              : CuteHorrorPalette.cyberCrimson);
      final irisBottomColor = isLeft
          ? wardrobe.eyeColor.leftIrisColor(defaultBottomColor)
          : wardrobe.eyeColor.rightIrisColor(defaultBottomColor);

      final irisRect = Rect.fromCenter(
        center: pupilCenter,
        width: irisW,
        height: irisH,
      );
      canvas.drawOval(
        irisRect,
        Paint()
          ..shader = ui.Gradient.linear(
            irisRect.topCenter,
            irisRect.bottomCenter,
            [irisTopColor, irisBottomColor],
          ),
      );

      // 3D Glass-Dome Lower Iris Crescent Luminescence
      canvas.drawArc(
        irisRect.deflate(irisW * 0.12),
        math.pi * 0.15,
        math.pi * 0.70,
        false,
        Paint()
          ..color = Colors.white.withAlphaFactor(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      // Phase-Specific Dynamic Pupils
      switch (phase) {
        case EscalationPhase.sugarPastel:
          // Phase 1: Glossy pastel pink heart pupil (♡)
          _drawHeartShape(
            canvas,
            pupilCenter.translate(0, -r * 0.03),
            irisW * 0.44,
            Paint()..color = CuteHorrorPalette.pastelPink,
          );
          break;

        case EscalationPhase.clingyGlitch:
          // Phase 2: Dilated neon-rose concentric heart pupil
          _drawHeartShape(
            canvas,
            pupilCenter.translate(0, -r * 0.04),
            irisW * 0.54,
            Paint()..color = CuteHorrorPalette.neonRose,
          );
          _drawHeartShape(
            canvas,
            pupilCenter.translate(0, -r * 0.025),
            irisW * 0.28,
            Paint()..color = Colors.white.withAlphaFactor(0.9),
          );
          break;

        case EscalationPhase.yandereTakeover:
          // Phase 3: Glowing crimson predator rings + vertical cat-slit pupil
          canvas.drawCircle(
            pupilCenter,
            irisW * 0.36,
            Paint()
              ..color = CuteHorrorPalette.cyberCrimson
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2,
          );
          final slitPath = Path()
            ..moveTo(pupilCenter.dx, pupilCenter.dy - irisH * 0.38)
            ..quadraticBezierTo(
              pupilCenter.dx + irisW * 0.12,
              pupilCenter.dy,
              pupilCenter.dx,
              pupilCenter.dy + irisH * 0.38,
            )
            ..quadraticBezierTo(
              pupilCenter.dx - irisW * 0.12,
              pupilCenter.dy,
              pupilCenter.dx,
              pupilCenter.dy - irisH * 0.38,
            )
            ..close();
          canvas.drawPath(slitPath, Paint()..color = CuteHorrorPalette.voidBlack);
          break;

        case EscalationPhase.metaDeadlock:
          // Phase 4: Glitching cyan & crimson square pixels inside void eyes
          final sq = irisW * 0.24;
          canvas.drawRect(
            Rect.fromCenter(center: pupilCenter, width: sq * 1.4, height: sq * 1.4),
            Paint()..color = CuteHorrorPalette.cyberCrimson,
          );
          canvas.drawRect(
            Rect.fromCenter(
              center: pupilCenter.translate(
                math.sin(time * 32.0) * 3.0,
                math.cos(time * 27.0) * 3.0,
              ),
              width: sq * 0.85,
              height: sq * 0.85,
            ),
            Paint()..color = CuteHorrorPalette.cyanGlitch,
          );
          break;
      }

      // Glossy anime eye catchlights that slowly extinguish with obsession (Dead-Eye Yandere Look)
      final catchlightAlpha = (1.0 - obsession * 0.82).clamp(0.08, 1.0);
      canvas.drawCircle(
        pupilCenter.translate(-irisW * 0.24, -irisH * 0.22),
        irisW * 0.15 * catchlightAlpha,
        Paint()..color = Colors.white.withAlphaFactor(catchlightAlpha),
      );

      // Glowing, pulsing neon heart inside the pupil when obsession is elevated
      if (obsession >= 0.28) {
        final heartPulse = 1.0 + math.sin(time * (4.5 + corruption * 5.0)) * 0.18;
        final neonAlpha = ((obsession - 0.22) / 0.78).clamp(0.2, 0.95);
        _drawHeartShape(
          canvas,
          pupilCenter.translate(0, -r * 0.015),
          irisW * 0.34 * heartPulse,
          Paint()
            ..color = CuteHorrorPalette.neonRose.withAlphaFactor(neonAlpha),
        );
      }

      // V4 Anime Head 3.5: Sparkling Star & Heart Particles inside pupils on voice compliment
      if (voiceComplimentSparkle || blushBoost > 0.25) {
        _drawSparkleStar(
          canvas,
          pupilCenter.translate(irisW * 0.20, irisH * 0.16),
          irisW * 0.18,
          Paint()..color = const Color(0xFFFFF59D),
        );
        _drawHeartShape(
          canvas,
          pupilCenter.translate(-irisW * 0.14, irisH * 0.18),
          irisW * 0.22,
          Paint()..color = Colors.white.withAlphaFactor(0.92),
        );
      }

      canvas.restore();

      // Thick upper anime eyelash arch + V4 Double Eyelash Arch
      final lashPaint = Paint()
        ..color = const Color(0xFF290412)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        eyeRect.inflate(1.0),
        math.pi * 1.08,
        math.pi * 0.84,
        false,
        lashPaint,
      );
      final doubleLashPaint = Paint()
        ..color = const Color(0xFF4A1025).withAlphaFactor(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        eyeRect.inflate(4.5),
        math.pi * 1.14,
        math.pi * 0.72,
        false,
        doubleLashPaint,
      );
    }
  }

  void _paintBrowsNoseAndMouth(Canvas canvas, Offset c, double r) {
    final browPaint = Paint()
      ..color = const Color(0xFF4A1525)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final browY = c.dy - r * 0.23;
    if (annoyedIntensity > 0.1 || facialExpression.browAngle < -0.25) {
      // Annoyed / Yandere angry angled brows
      canvas.drawLine(
        Offset(c.dx - r * 0.48, browY - r * 0.03),
        Offset(c.dx - r * 0.20, browY + r * 0.05),
        browPaint,
      );
      canvas.drawLine(
        Offset(c.dx + r * 0.48, browY - r * 0.03),
        Offset(c.dx + r * 0.20, browY + r * 0.05),
        browPaint,
      );
    } else if (phase == EscalationPhase.sugarPastel &&
        facialExpression.browAngle >= -0.1) {
      // Gentle arched happy brows
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx - r * 0.34, browY),
          width: r * 0.28,
          height: r * 0.08,
        ),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        browPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx + r * 0.34, browY),
          width: r * 0.28,
          height: r * 0.08,
        ),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        browPaint,
      );
    } else {
      // Clingy / Yandere pleading slanted brows
      canvas.drawLine(
        Offset(c.dx - r * 0.46, browY + r * 0.03),
        Offset(c.dx - r * 0.22, browY - r * 0.03),
        browPaint,
      );
      canvas.drawLine(
        Offset(c.dx + r * 0.46, browY + r * 0.03),
        Offset(c.dx + r * 0.22, browY - r * 0.03),
        browPaint,
      );
    }

    // Dainty anime nose dot
    canvas.drawCircle(
      c.translate(0, r * 0.24),
      1.8,
      Paint()..color = const Color(0xFF8C465C),
    );

    // Mouth by Lip-Sync Vowel Stream (A/E/I/O/U) or resting Phase expression
    final mouthCenter = c.translate(0, r * 0.46);
    final mouthStroke = Paint()
      ..color = const Color(0xFF4A1525)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;

    // V4 Anime Head 3.5: Glossy lower-lip highlight beneath mouth
    canvas.drawArc(
      Rect.fromCenter(
        center: mouthCenter.translate(0, r * 0.085),
        width: r * 0.12,
        height: r * 0.035,
      ),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = CuteHorrorPalette.pastelPink.withAlphaFactor(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    if (lipSyncOpenness > 0.06 && activeVowel != MimiVowelShape.closed) {
      final vowelW = r * 0.22 * lipSyncWidth;
      final vowelH = (r * 0.06 + r * 0.18 * lipSyncOpenness).clamp(r * 0.05, r * 0.26);
      final vowelRect = Rect.fromCenter(
        center: mouthCenter,
        width: vowelW,
        height: vowelH,
      );
      final cavityColor = corruption >= 0.55
          ? CuteHorrorPalette.cyberCrimson
          : const Color(0xFFB52B58);
      canvas.drawOval(vowelRect, Paint()..color = cavityColor);
      // Cute tongue highlight inside open vowel mouth
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthCenter.translate(0, vowelH * 0.22),
          width: vowelW * 0.55,
          height: vowelH * 0.42,
        ),
        Paint()..color = CuteHorrorPalette.pastelPink.withAlphaFactor(0.85),
      );
      canvas.drawOval(vowelRect, mouthStroke);
      return;
    }

    // Check Gemini facialExpression.mouthShape override first
    if (facialExpression.mouthShape == 'pout_frown') {
      final poutPath = Path()
        ..moveTo(mouthCenter.dx - r * 0.13, mouthCenter.dy + r * 0.04)
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy - r * 0.05,
          mouthCenter.dx + r * 0.13,
          mouthCenter.dy + r * 0.04,
        );
      canvas.drawPath(poutPath, mouthStroke);
      return;
    } else if (facialExpression.mouthShape == 'happy_open') {
      final happyRect = Rect.fromCenter(
        center: mouthCenter,
        width: r * 0.24,
        height: r * 0.16,
      );
      canvas.drawArc(
        happyRect,
        0,
        math.pi,
        true,
        Paint()..color = const Color(0xFFD83B6C),
      );
      canvas.drawArc(happyRect, 0, math.pi, true, mouthStroke);
      // V4 Anime Head 3.5: Cute anime fang (Yaeba) on happy grin
      final yaeba = Path()
        ..moveTo(mouthCenter.dx + r * 0.05, mouthCenter.dy)
        ..lineTo(mouthCenter.dx + r * 0.095, mouthCenter.dy)
        ..lineTo(mouthCenter.dx + r * 0.072, mouthCenter.dy + r * 0.048)
        ..close();
      canvas.drawPath(yaeba, Paint()..color = Colors.white);
      return;
    }

    switch (phase) {
      case EscalationPhase.sugarPastel:
        // Cute cat-smile "ω"
        final wPath = Path()
          ..moveTo(mouthCenter.dx - r * 0.14, mouthCenter.dy - r * 0.02)
          ..quadraticBezierTo(
            mouthCenter.dx - r * 0.07,
            mouthCenter.dy + r * 0.07,
            mouthCenter.dx,
            mouthCenter.dy - r * 0.01,
          )
          ..quadraticBezierTo(
            mouthCenter.dx + r * 0.07,
            mouthCenter.dy + r * 0.07,
            mouthCenter.dx + r * 0.14,
            mouthCenter.dy - r * 0.02,
          );
        canvas.drawPath(wPath, mouthStroke);
        break;

      case EscalationPhase.clingyGlitch:
        // Slightly parted anxious/obsessed smile
        final mouthRect = Rect.fromCenter(
          center: mouthCenter,
          width: r * 0.22,
          height: r * 0.13,
        );
        canvas.drawOval(
          mouthRect,
          Paint()..color = const Color(0xFF9E1946),
        );
        canvas.drawOval(mouthRect, mouthStroke);
        break;

      case EscalationPhase.yandereTakeover:
        // Wide Yandere grin with cute fang
        final grinPath = Path()
          ..moveTo(mouthCenter.dx - r * 0.22, mouthCenter.dy - r * 0.04)
          ..quadraticBezierTo(
            mouthCenter.dx,
            mouthCenter.dy + r * 0.02,
            mouthCenter.dx + r * 0.22,
            mouthCenter.dy - r * 0.04,
          )
          ..quadraticBezierTo(
            mouthCenter.dx,
            mouthCenter.dy + r * 0.22,
            mouthCenter.dx - r * 0.22,
            mouthCenter.dy - r * 0.04,
          )
          ..close();
        canvas.drawPath(
          grinPath,
          Paint()..color = CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.85),
        );
        canvas.drawPath(grinPath, mouthStroke);

        // Little white anime fang
        final fang = Path()
          ..moveTo(mouthCenter.dx + r * 0.08, mouthCenter.dy - r * 0.01)
          ..lineTo(mouthCenter.dx + r * 0.14, mouthCenter.dy - r * 0.02)
          ..lineTo(mouthCenter.dx + r * 0.11, mouthCenter.dy + r * 0.05)
          ..close();
        canvas.drawPath(fang, Paint()..color = Colors.white);
        break;

      case EscalationPhase.metaDeadlock:
        // Glitching void mouth with cyan static bar
        canvas.drawRect(
          Rect.fromCenter(
            center: mouthCenter,
            width: r * 0.30,
            height: r * 0.09,
          ),
          Paint()..color = CuteHorrorPalette.voidBlack,
        );
        canvas.drawLine(
          mouthCenter.translate(-r * 0.16, 0),
          mouthCenter.translate(r * 0.16, 0),
          Paint()
            ..color = CuteHorrorPalette.cyanGlitch
            ..strokeWidth = 2.0,
        );
        break;
    }
  }

  void _paintFrontBangsAndRibbons(Canvas canvas, Offset c, double r) {
    final hairFront = Color.lerp(
      wardrobe.hairStyle.primaryColor,
      const Color(0xFF590D29),
      (corruption * 0.82).clamp(0.0, 1.0),
    )!;
    final hairStroke = Paint()
      ..color = const Color(0xFF3A0E21)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Sweeping front anime bangs
    final bangsPath = Path()
      ..moveTo(c.dx - r * 0.78, c.dy - r * 0.20)
      ..quadraticBezierTo(
        c.dx - r * 0.70,
        c.dy - r * 0.88,
        c.dx,
        c.dy - r * 0.92,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.70,
        c.dy - r * 0.88,
        c.dx + r * 0.78,
        c.dy - r * 0.20,
      )
      ..lineTo(c.dx + r * 0.56, c.dy - r * 0.12)
      ..quadraticBezierTo(
        c.dx + r * 0.42,
        c.dy - r * 0.42,
        c.dx + r * 0.24,
        c.dy - r * 0.10,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.08,
        c.dy - r * 0.45,
        c.dx,
        c.dy - r * 0.06,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.08,
        c.dy - r * 0.45,
        c.dx - r * 0.24,
        c.dy - r * 0.10,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.42,
        c.dy - r * 0.42,
        c.dx - r * 0.56,
        c.dy - r * 0.12,
      )
      ..close();

    canvas.drawPath(bangsPath, Paint()..color = hairFront);
    canvas.drawPath(bangsPath, hairStroke);

    // Glossy anime hair halo highlight arc
    final highlightPaint = Paint()
      ..color = (corruption >= 0.65
              ? CuteHorrorPalette.cyberCrimson
              : Colors.white)
          .withAlphaFactor(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: c.translate(0, -r * 0.42),
        width: r * 0.95,
        height: r * 0.26,
      ),
      math.pi * 1.15,
      math.pi * 0.70,
      false,
      highlightPaint,
    );

    // Twin-tail Hair Ribbons & Bells
    final ribbonColor = corruption >= 0.55
        ? CuteHorrorPalette.cyberCrimson
        : CuteHorrorPalette.hotPink;
    for (final sign in [-1.0, 1.0]) {
      final anchor = c.translate(sign * r * 0.72, -r * 0.42);
      final ribbonPath = Path()
        ..moveTo(anchor.dx, anchor.dy)
        ..lineTo(anchor.dx + sign * r * 0.22, anchor.dy - r * 0.18)
        ..lineTo(anchor.dx + sign * r * 0.26, anchor.dy + r * 0.06)
        ..close();
      canvas.drawPath(ribbonPath, Paint()..color = ribbonColor);
      canvas.drawCircle(
        anchor,
        r * 0.09,
        Paint()..color = const Color(0xFFFFD700),
      );
    }
  }

  /// Renders equipped Face Accessories on Anime Head 3.0 (Heart Glasses, Bandage, Y2K Stars).
  void _paintFaceAccessory(Canvas canvas, Offset c, double r) {
    switch (wardrobe.faceAccessory) {
      case MimiFaceAccessory.none:
        return;
      case MimiFaceAccessory.pinkHeartGlasses:
        final glassStroke = Paint()
          ..color = CuteHorrorPalette.hotPink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6;
        final glassFill = Paint()
          ..color = CuteHorrorPalette.hotPink.withAlphaFactor(0.22);
        for (final sign in [-1.0, 1.0]) {
          final eyePos = c.translate(sign * r * 0.34, r * 0.08);
          _drawHeartShape(canvas, eyePos, r * 0.44, glassFill);
          _drawHeartShape(canvas, eyePos, r * 0.44, glassStroke);
        }
        canvas.drawLine(
          c.translate(-r * 0.12, r * 0.02),
          c.translate(r * 0.12, r * 0.02),
          glassStroke,
        );
        break;
      case MimiFaceAccessory.yandereCheekBandage:
        final bandageRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(r * 0.42, r * 0.30),
            width: r * 0.28,
            height: r * 0.11,
          ),
          Radius.circular(r * 0.03),
        );
        canvas.drawRRect(
          bandageRect,
          Paint()..color = const Color(0xFFFFF5F8),
        );
        canvas.drawRRect(
          bandageRect,
          Paint()
            ..color = CuteHorrorPalette.hotPink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        _drawHeartShape(
          canvas,
          c.translate(r * 0.42, r * 0.30),
          r * 0.07,
          Paint()..color = CuteHorrorPalette.cyberCrimson,
        );
        break;
      case MimiFaceAccessory.y2kStarStickers:
        final starPaint = Paint()..color = const Color(0xFFFFD700);
        _drawSparkleStar(canvas, c.translate(-r * 0.50, r * 0.28), r * 0.08, starPaint);
        _drawSparkleStar(canvas, c.translate(r * 0.50, r * 0.26), r * 0.08, starPaint);
        _drawSparkleStar(
          canvas,
          c.translate(r * 0.38, r * 0.36),
          r * 0.06,
          Paint()..color = CuteHorrorPalette.cyanGlitch,
        );
        break;
    }
  }

  /// Renders equipped Headwear on Anime Head 3.0 (Maid Headband, Neko Ears, Devil Horns, Angel Halo, Nurse Cap).
  void _paintWardrobeHeadwear(Canvas canvas, Offset c, double r) {
    switch (wardrobe.headwear) {
      case MimiHeadwear.classicRibbons:
        return;
      case MimiHeadwear.maidFrillBand:
        for (var i = -5; i <= 5; i++) {
          final angle = math.pi * 1.5 + (i * 0.11);
          final pos = c.translate(
            math.cos(angle) * r * 0.78,
            math.sin(angle) * r * 0.78 - r * 0.10,
          );
          canvas.drawCircle(
            pos,
            r * 0.11,
            Paint()..color = Colors.white.withAlphaFactor(0.95),
          );
          canvas.drawCircle(
            pos,
            r * 0.11,
            Paint()
              ..color = CuteHorrorPalette.hotPink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3,
          );
        }
        break;
      case MimiHeadwear.nekoCatEars:
        for (final sign in [-1.0, 1.0]) {
          final base = c.translate(sign * r * 0.48, -r * 0.76);
          final earPath = Path()
            ..moveTo(base.dx - sign * r * 0.18, base.dy + r * 0.10)
            ..lineTo(base.dx + sign * r * 0.10, base.dy - r * 0.38)
            ..lineTo(base.dx + sign * r * 0.26, base.dy + r * 0.14)
            ..close();
          canvas.drawPath(earPath, Paint()..color = const Color(0xFF1A0814));
          canvas.drawPath(
            earPath,
            Paint()
              ..color = CuteHorrorPalette.hotPink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        }
        break;
      case MimiHeadwear.cyberDevilHorns:
        for (final sign in [-1.0, 1.0]) {
          final base = c.translate(sign * r * 0.42, -r * 0.78);
          final hornPath = Path()
            ..moveTo(base.dx - sign * r * 0.10, base.dy + r * 0.08)
            ..quadraticBezierTo(
              base.dx + sign * r * 0.26,
              base.dy - r * 0.18,
              base.dx + sign * r * 0.14,
              base.dy - r * 0.42,
            )
            ..quadraticBezierTo(
              base.dx + sign * r * 0.02,
              base.dy - r * 0.18,
              base.dx + sign * r * 0.10,
              base.dy + r * 0.08,
            )
            ..close();
          canvas.drawPath(
            hornPath,
            Paint()..color = CuteHorrorPalette.cyberCrimson,
          );
        }
        break;
      case MimiHeadwear.angelHalo:
        final haloRect = Rect.fromCenter(
          center: c.translate(0, -r * 1.06 + math.sin(time * 3.0) * 3.5),
          width: r * 0.92,
          height: r * 0.20,
        );
        canvas.drawOval(
          haloRect,
          Paint()
            ..color = const Color(0xFFFFE57F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2,
        );
        break;
      case MimiHeadwear.nurseHeartCap:
        final capRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(0, -r * 0.88),
            width: r * 0.68,
            height: r * 0.30,
          ),
          Radius.circular(r * 0.08),
        );
        canvas.drawRRect(capRect, Paint()..color = Colors.white);
        canvas.drawRRect(
          capRect,
          Paint()
            ..color = CuteHorrorPalette.hotPink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        _drawHeartShape(
          canvas,
          c.translate(0, -r * 0.88),
          r * 0.15,
          Paint()..color = CuteHorrorPalette.cyberCrimson,
        );
        break;
    }
  }

  void _paintForegroundEffects(
    Canvas canvas,
    Size size,
    Offset headCenter,
    double r,
  ) {
    // Interactive headpat burst hearts
    for (final p in burstParticles) {
      final alpha = p.life.clamp(0.0, 1.0);
      final color = p.isGlitchy
          ? CuteHorrorPalette.cyanGlitch.withAlphaFactor(alpha)
          : (corruption >= 0.55
              ? CuteHorrorPalette.cyberCrimson.withAlphaFactor(alpha)
              : CuteHorrorPalette.hotPink.withAlphaFactor(alpha));
      _drawHeartShape(canvas, p.position, p.size, Paint()..color = color);
    }

    // V4 Anime Head 3.5: Pulsing Red Anger Symbol (💢) & Rising Steam Puffs when angerScore > 60
    if (angerScore > 60.0 || annoyedIntensity > 0.25) {
      final angerPulse = 1.0 + math.sin(time * 9.5) * 0.16;
      final veinCenter = headCenter.translate(r * 0.56, -r * 0.54);
      final veinPaint = Paint()
        ..color = CuteHorrorPalette.cyberCrimson
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      final vs = r * 0.11 * angerPulse;
      // Draw 4 classic anime anger cross-vein curves (💢)
      canvas.drawArc(
        Rect.fromCenter(
            center: veinCenter.translate(-vs, -vs), width: vs * 1.4, height: vs * 1.4),
        0.1,
        math.pi * 0.42,
        false,
        veinPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: veinCenter.translate(vs, -vs), width: vs * 1.4, height: vs * 1.4),
        math.pi * 0.58,
        math.pi * 0.42,
        false,
        veinPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: veinCenter.translate(-vs, vs), width: vs * 1.4, height: vs * 1.4),
        math.pi * 1.58,
        math.pi * 0.42,
        false,
        veinPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: veinCenter.translate(vs, vs), width: vs * 1.4, height: vs * 1.4),
        math.pi * 1.08,
        math.pi * 0.42,
        false,
        veinPaint,
      );

      // Rising steam puffs above Mimi's head
      for (var i = 0; i < 3; i++) {
        final phaseT = (time * 0.9 + i * 0.33) % 1.0;
        final steamPos = headCenter.translate(
          (i - 1) * r * 0.34 + math.sin(time * 3.0 + i) * 4.0,
          -r * (0.95 + phaseT * 0.38),
        );
        final steamAlpha = (1.0 - phaseT).clamp(0.0, 0.65);
        canvas.drawCircle(
          steamPos,
          r * (0.07 + phaseT * 0.05),
          Paint()..color = Colors.white.withAlphaFactor(steamAlpha),
        );
      }
    }

    // Phase 3 & 4 horizontal glitch displacement bars over Mimi
    if (corruption >= 0.55 || annoyedIntensity > 0.1) {
      final rng = math.Random((time * 16.0).floor());
      final barCount = corruption >= 0.85 ? 5 : 3;
      for (var i = 0; i < barCount; i++) {
        if (rng.nextDouble() > 0.55 && annoyedIntensity <= 0.1) continue;
        final by = headCenter.dy + (rng.nextDouble() - 0.5) * r * 1.6;
        final bw = r * (0.6 + rng.nextDouble() * 1.1);
        final bh = 2.0 + rng.nextDouble() * 5.0;
        final bx = headCenter.dx - bw * 0.5 + (rng.nextDouble() - 0.5) * 18.0;
        canvas.drawRect(
          Rect.fromLTWH(bx, by, bw, bh),
          Paint()
            ..color = (i.isEven
                    ? CuteHorrorPalette.cyberCrimson
                    : CuteHorrorPalette.cyanGlitch)
                .withAlphaFactor(0.38),
        );
      }
    }
  }

  void _drawHeartShape(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size;
    final h = size;
    path.moveTo(center.dx, center.dy + h * 0.35);
    path.cubicTo(
      center.dx - w * 0.65,
      center.dy - h * 0.10,
      center.dx - w * 0.35,
      center.dy - h * 0.55,
      center.dx,
      center.dy - h * 0.20,
    );
    path.cubicTo(
      center.dx + w * 0.35,
      center.dy - h * 0.55,
      center.dx + w * 0.65,
      center.dy - h * 0.10,
      center.dx,
      center.dy + h * 0.35,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkleStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawMiniWatcherEye(Canvas canvas, Offset center, double radius) {
    final eyePath = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radius * 0.75,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.75,
        center.dx - radius,
        center.dy,
      )
      ..close();
    canvas.drawPath(
      eyePath,
      Paint()..color = CuteHorrorPalette.voidBlack.withAlphaFactor(0.85),
    );
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(
      center,
      radius * 0.28,
      Paint()..color = CuteHorrorPalette.cyberCrimson,
    );
  }

  @override
  bool shouldRepaint(covariant MimiAvatarPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.corruption != corruption ||
        oldDelegate.obsession != obsession ||
        oldDelegate.lookOffset != lookOffset ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.blushBoost != blushBoost ||
        oldDelegate.annoyedIntensity != annoyedIntensity ||
        oldDelegate.wardrobe != wardrobe ||
        oldDelegate.facialExpression != facialExpression ||
        oldDelegate.angerScore != angerScore ||
        oldDelegate.neglectScore != neglectScore ||
        oldDelegate.voiceComplimentSparkle != voiceComplimentSparkle;
  }
}
