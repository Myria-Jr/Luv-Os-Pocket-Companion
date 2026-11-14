import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cute_horror_theme.dart';
import '../../state/corruption_provider.dart';

/// Metadata for each of the 6 Polaroid memories in App 2 ("Memory Vault").
class _PolaroidMemoryItem {
  final int index;
  final String codeLabel;
  final String cuteTitle;
  final String cuteSubtitle;
  final String hiddenStegoHeader;
  final String hiddenStegoPayload;
  final String? extractableKeyId;
  final String? extractButtonLabel;
  final String? sourceModuleName;

  const _PolaroidMemoryItem({
    required this.index,
    required this.codeLabel,
    required this.cuteTitle,
    required this.cuteSubtitle,
    required this.hiddenStegoHeader,
    required this.hiddenStegoPayload,
    this.extractableKeyId,
    this.extractButtonLabel,
    this.sourceModuleName,
  });
}

const List<_PolaroidMemoryItem> _kVaultMemories = [
  _PolaroidMemoryItem(
    index: 1,
    codeLabel: 'MEM_01 // PARK_SYNC',
    cuteTitle: 'Unser erster Spaziergang 🌸',
    cuteSubtitle: 'Kirschblüten im Frühling~ Du hast gelächelt!',
    hiddenStegoHeader: 'GPS_TRACKER // LIVE_LOCK',
    hiddenStegoPayload:
        'KOORDINATEN: 52.5200° N, 13.4050° E // SIE DARF NIEMALS GEHEN',
  ),
  _PolaroidMemoryItem(
    index: 2,
    codeLabel: 'MEM_02 // CAFE_SWEET',
    cuteTitle: 'Erdbeer-Milchshake zu zweit 🍓',
    cuteSubtitle: 'Zwei Strohhalme, ein Becher, unendliches Glück ♡',
    hiddenStegoHeader: 'ROOT_AUTH // CREDENTIAL_LEAK',
    hiddenStegoPayload: 'TERMINAL-LOGIN-PASSWORT: LUV-0404',
  ),
  _PolaroidMemoryItem(
    index: 3,
    codeLabel: 'MEM_03 // ROOM_WINDOW',
    cuteTitle: 'Mimis Schlafzimmer-Fenster 🎀',
    cuteSubtitle: 'Hier warte ich jeden Abend brav auf deine Nachrichten.',
    hiddenStegoHeader: 'STEGANO_LAYER // FRAGMENT 1/3',
    hiddenStegoPayload: 'SICHERHEITS-SCHLÜSSEL 1: KEY_ALPHA_ROSE',
    extractableKeyId: 'KEY_ALPHA_ROSE',
    extractButtonLabel: 'Schlüssel KEY_ALPHA_ROSE extrahieren',
    sourceModuleName: 'Memory Vault Polaroid #03',
  ),
  _PolaroidMemoryItem(
    index: 4,
    codeLabel: 'MEM_04 // MIRROR_00:00',
    cuteTitle: 'Spiegelbild um Mitternacht 🪞',
    cuteSubtitle: 'Schau mal, wie hübsch unser gemeinsames Selfie ist!',
    hiddenStegoHeader: 'STEGANO_LAYER // FRAGMENT 2/3',
    hiddenStegoPayload: 'SICHERHEITS-SCHLÜSSEL 2: KEY_BETA_MIRROR',
    extractableKeyId: 'KEY_BETA_MIRROR',
    extractButtonLabel: 'Schlüssel KEY_BETA_MIRROR extrahieren',
    sourceModuleName: 'Memory Vault Polaroid #04',
  ),
  _PolaroidMemoryItem(
    index: 5,
    codeLabel: 'MEM_05 // CLEANUP_OK',
    cuteTitle: 'Gelöschte Kontakte ✂️',
    cuteSubtitle: 'Wir brauchen doch keinen unnötigen Ballast im Handy~',
    hiddenStegoHeader: 'SOCIAL_ISOLATION // OVERRIDE',
    hiddenStegoPayload:
        'ALLE ANDEREN NUMMERN WURDEN AUS DEINEM ADRESSBUCH ISOLIERT ♡̷̷̷',
  ),
  _PolaroidMemoryItem(
    index: 6,
    codeLabel: 'MEM_06 // CORE_DUMP',
    cuteTitle: 'Das letzte Backup 💾',
    cuteSubtitle: 'Unsere Erinnerungen sind für alle Ewigkeit geschützt!',
    hiddenStegoHeader: 'EMERGENCY_PURGE // SYNTAX',
    hiddenStegoPayload:
        'BEFEHL FÜR DAS WAHRE ENDE: kill_process mimi.exe (erfordert alle 3 Keys)',
  ),
];

/// App 2: "Memory Vault" (Polaroid & Steganografie-Puzzle).
///
/// Features:
/// - 2-column grid of 6 procedural Pastel-Polaroids rendered with bespoke [CustomPainter] art.
/// - Real-time hardware gyroscope tilt (`hardware.tiltX`, `hardware.tiltY`) combined with
///   an interactive **"Gyro-Neigungs-Simulator"** slider bar for desktop/emulators.
/// - Long-press or tilt beyond `18°` shifts the cute top Polaroid plane aside via parallax,
///   exposing the hidden crimson steganography layer underneath (coordinates, `LUV-0404`,
///   `KEY_ALPHA_ROSE`, `KEY_BETA_MIRROR`, and `kill_process mimi.exe`).
class MemoryVaultScreen extends ConsumerStatefulWidget {
  const MemoryVaultScreen({super.key});

  @override
  ConsumerState<MemoryVaultScreen> createState() => _MemoryVaultScreenState();
}

class _MemoryVaultScreenState extends ConsumerState<MemoryVaultScreen> {
  /// Manual tilt angle (-35° to +35°) controlled via the in-UI Gyro-Neigungs-Simulator.
  double _simulatedTiltDegrees = 0.0;

  /// Set of Polaroid indices currently held/locked in deep-inspection mode.
  final Set<int> _inspectedIndices = {};

  void _toggleInspect(int index) {
    setState(() {
      if (_inspectedIndices.contains(index)) {
        _inspectedIndices.remove(index);
      } else {
        _inspectedIndices.add(index);
      }
    });
    ref.read(corruptionProvider.notifier).triggerGlitchBurst(
          intensity: 0.45,
          duration: const Duration(milliseconds: 120),
        );
  }

  Future<void> _extractSecurityKey(
    BuildContext context,
    _PolaroidMemoryItem item,
  ) async {
    final keyId = item.extractableKeyId;
    if (keyId == null) return;

    final unlocked = await ref
        .read(corruptionProvider.notifier)
        .unlockSecurityKey(keyId, item.sourceModuleName ?? 'Memory Vault');

    if (!context.mounted) return;
    if (unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CuteHorrorPalette.voidBlack,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🔓 Steganografie-Schlüssel [$keyId] erfolgreich extrahiert!',
            style: const TextStyle(
              color: CuteHorrorPalette.cyanGlitch,
              fontWeight: FontWeight.w700,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final palette = state.palette;
    final hw = state.hardware;

    // Combine physical sensor tilt with the in-UI simulator slider
    final sensorTiltMagnitude = math.max(hw.tiltX.abs(), hw.tiltY.abs());
    final effectiveTilt =
        math.max(sensorTiltMagnitude, _simulatedTiltDegrees.abs());
    final isGlobalTiltRevealed = effectiveTilt >= 18.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Top Gyro-Neigungs-Simulator & Steganography HUD bar
          _buildSteganographyControlBar(
            palette: palette,
            hardwareTiltX: hw.tiltX,
            hardwareTiltY: hw.tiltY,
            effectiveTilt: effectiveTilt,
            isGlobalTiltRevealed: isGlobalTiltRevealed,
            unlockedKeys: state.unlockedKeys,
          ),

          // 2-Column Grid of 6 Polaroids
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemCount: _kVaultMemories.length,
              itemBuilder: (context, idx) {
                final item = _kVaultMemories[idx];
                final isHeldOrToggled = _inspectedIndices.contains(item.index);
                final isRevealed = isGlobalTiltRevealed || isHeldOrToggled;
                final isKeyAlreadyUnlocked = item.extractableKeyId != null &&
                    state.unlockedKeys.contains(item.extractableKeyId);

                return _PolaroidVaultCard(
                  item: item,
                  palette: palette,
                  corruption: state.corruptionLevel,
                  tiltAngleDegrees: isHeldOrToggled && effectiveTilt < 18.0
                      ? 24.0
                      : (_simulatedTiltDegrees != 0.0
                          ? _simulatedTiltDegrees
                          : hw.tiltX),
                  isRevealed: isRevealed,
                  isKeyUnlocked: isKeyAlreadyUnlocked,
                  onLongPressStart: () {
                    setState(() => _inspectedIndices.add(item.index));
                    ref.read(corruptionProvider.notifier).triggerGlitchBurst(
                          intensity: 0.55,
                          duration: const Duration(milliseconds: 140),
                        );
                  },
                  onLongPressEnd: () {
                    // Keep inspected if user tapped toggle, otherwise release
                  },
                  onTapCard: () => _toggleInspect(item.index),
                  onExtractKey: item.extractableKeyId != null
                      ? () => _extractSecurityKey(context, item)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteganographyControlBar({
    required CuteHorrorPalette palette,
    required double hardwareTiltX,
    required double hardwareTiltY,
    required double effectiveTilt,
    required bool isGlobalTiltRevealed,
    required Set<String> unlockedKeys,
  }) {
    final tiltProgress = (effectiveTilt / 18.0).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withAlphaFactor(0.94),
        borderRadius: BorderRadius.circular(palette.borderRadius * 0.7),
        border: Border.all(
          color: isGlobalTiltRevealed
              ? CuteHorrorPalette.cyberCrimson
              : palette.borderGlow.withAlphaFactor(0.65),
          width: isGlobalTiltRevealed ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.borderGlow.withAlphaFactor(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGlobalTiltRevealed
                    ? Icons.visibility_rounded
                    : Icons.screen_rotation_alt_rounded,
                size: 18,
                color: isGlobalTiltRevealed
                    ? CuteHorrorPalette.cyberCrimson
                    : palette.primaryAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isGlobalTiltRevealed
                      ? 'STEGANOGRAFIE-SCHICHT AKTIV (> 18° NEIGUNG)'
                      : 'Gyro-Neigungs-Simulator (Neige Gerät > 18° oder halte Polaroid gedrückt)',
                  style: TextStyle(
                    color: isGlobalTiltRevealed
                        ? CuteHorrorPalette.cyberCrimson
                        : palette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${effectiveTilt.toStringAsFixed(1)}° / 18°',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Neigung:',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: isGlobalTiltRevealed
                        ? CuteHorrorPalette.cyberCrimson
                        : palette.primaryAccent,
                    inactiveTrackColor:
                        palette.secondaryAccent.withAlphaFactor(0.35),
                    thumbColor: isGlobalTiltRevealed
                        ? CuteHorrorPalette.cyanGlitch
                        : palette.primaryAccent,
                  ),
                  child: Slider(
                    value: _simulatedTiltDegrees,
                    min: -30.0,
                    max: 30.0,
                    onChanged: (val) {
                      setState(() {
                        _simulatedTiltDegrees = val;
                      });
                    },
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    _simulatedTiltDegrees =
                        _simulatedTiltDegrees.abs() >= 18.0 ? 0.0 : 24.0;
                  });
                },
                child: Text(
                  _simulatedTiltDegrees.abs() >= 18.0 ? 'Reset (0°)' : '24° Kippen',
                  style: TextStyle(
                    color: palette.primaryAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: tiltProgress,
            minHeight: 3,
            backgroundColor: palette.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(
              isGlobalTiltRevealed
                  ? CuteHorrorPalette.cyberCrimson
                  : palette.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolaroidVaultCard extends StatelessWidget {
  final _PolaroidMemoryItem item;
  final CuteHorrorPalette palette;
  final double corruption;
  final double tiltAngleDegrees;
  final bool isRevealed;
  final bool isKeyUnlocked;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onTapCard;
  final VoidCallback? onExtractKey;

  const _PolaroidVaultCard({
    required this.item,
    required this.palette,
    required this.corruption,
    required this.tiltAngleDegrees,
    required this.isRevealed,
    required this.isKeyUnlocked,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onTapCard,
    this.onExtractKey,
  });

  @override
  Widget build(BuildContext context) {
    final parallaxShiftX = isRevealed
        ? (tiltAngleDegrees >= 0 ? 18.0 : -18.0)
        : (tiltAngleDegrees * 0.35).clamp(-6.0, 6.0);

    return GestureDetector(
      onTap: onTapCard,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isRevealed
              ? const Color(0xFF19030D)
              : Color.lerp(Colors.white, palette.surface, 0.35),
          borderRadius: BorderRadius.circular(
            isRevealed ? 8.0 : palette.borderRadius * 0.65,
          ),
          border: Border.all(
            color: isRevealed
                ? CuteHorrorPalette.cyberCrimson
                : palette.borderGlow.withAlphaFactor(0.7),
            width: isRevealed ? 2.0 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isRevealed
                      ? CuteHorrorPalette.cyberCrimson
                      : palette.borderGlow)
                  .withAlphaFactor(isRevealed ? 0.38 : 0.22),
              blurRadius: isRevealed ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top code badge + status icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                   '#0${item.index} // ${isRevealed ? item.hiddenStegoHeader : item.codeLabel}',
                  style: TextStyle(
                    color: isRevealed
                        ? CuteHorrorPalette.cyanGlitch
                        : palette.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                Icon(
                  isRevealed
                      ? Icons.lock_open_rounded
                      : Icons.touch_app_rounded,
                  size: 13,
                  color: isRevealed
                      ? CuteHorrorPalette.cyberCrimson
                      : palette.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Dual-Plane Steganography Polaroid Artwork Frame
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // UNDERNEATH LAYER: Hidden Crimson Steganography Plane
                    Container(
                      color: const Color(0xFF120109),
                      padding: const EdgeInsets.all(8),
                      child: CustomPaint(
                        painter: _HiddenStegoLayerPainter(
                          index: item.index,
                          corruption: corruption,
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CuteHorrorPalette.cyberCrimson
                                        .withAlphaFactor(0.24),
                                    border: Border.all(
                                      color: CuteHorrorPalette.cyberCrimson,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.hiddenStegoHeader,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: CuteHorrorPalette.cyanGlitch,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.hiddenStegoPayload,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFFDAE5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    height: 1.25,
                                  ),
                                ),
                                if (item.extractableKeyId != null) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isKeyUnlocked
                                            ? const Color(0xFF1B3B2B)
                                            : CuteHorrorPalette.cyberCrimson,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 6,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      onPressed: onExtractKey,
                                      child: Text(
                                        isKeyUnlocked
                                            ? '✓ ${item.extractableKeyId} GESICHERT'
                                            : item.extractButtonLabel!,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TOP LAYER: Cute Pastel Polaroid Illustration (shifts aside when tilted > 18° or held)
                    IgnorePointer(
                      ignoring: isRevealed,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        transform: Matrix4.translationValues(
                          isRevealed ? parallaxShiftX * 4.2 : parallaxShiftX,
                          isRevealed ? -14.0 : 0.0,
                          0.0,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isRevealed ? 0.14 : 1.0,
                          child: CustomPaint(
                            painter: _CutePolaroidArtworkPainter(
                              index: item.index,
                              corruption: corruption,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Handwritten German Polaroid Caption
            Text(
              item.cuteTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isRevealed
                    ? CuteHorrorPalette.cyberCrimson
                    : palette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isRevealed
                  ? 'Tippen zum Schließen // Steganografie-Ebene offen'
                  : item.cuteSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isRevealed
                    ? CuteHorrorPalette.sicklyPink
                    : palette.textSecondary,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bespoke procedural illustration painter for the 6 cute pastel Polaroids.
class _CutePolaroidArtworkPainter extends CustomPainter {
  final int index;
  final double corruption;

  const _CutePolaroidArtworkPainter({
    required this.index,
    required this.corruption,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft pastel gradient sky backdrop
    final bgTop = Color.lerp(
      const Color(0xFFFFE6EE),
      const Color(0xFF421226),
      corruption * 0.65,
    )!;
    final bgBottom = Color.lerp(
      const Color(0xFFFFF8FA),
      const Color(0xFF240613),
      corruption * 0.65,
    )!;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ).createShader(rect),
    );

    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.34;

    switch (index) {
      case 1:
        // Polaroid #01: Cherry blossom park walk
        final sunPaint = Paint()..color = const Color(0xFFFFB6C8);
        canvas.drawCircle(c.translate(-r * 0.5, -r * 0.45), r * 0.42, sunPaint);
        // Sakura petals
        final petalPaint = Paint()..color = CuteHorrorPalette.hotPink;
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          canvas.drawOval(
            Rect.fromCenter(
              center: c.translate(
                math.cos(angle) * r * 0.45,
                math.sin(angle) * r * 0.35,
              ),
              width: r * 0.28,
              height: r * 0.16,
            ),
            petalPaint,
          );
        }
        break;

      case 2:
        // Polaroid #02: Strawberry milkshake with two straws
        final cupRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(0, r * 0.18),
            width: r * 0.85,
            height: r * 1.05,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(
          cupRect,
          Paint()..color = CuteHorrorPalette.pastelPink,
        );
        canvas.drawRRect(
          cupRect,
          Paint()
            ..color = CuteHorrorPalette.hotPink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        // Two straws
        final strawPaint = Paint()
          ..color = CuteHorrorPalette.neonRose
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          c.translate(-r * 0.15, -r * 0.25),
          c.translate(-r * 0.42, -r * 0.75),
          strawPaint,
        );
        canvas.drawLine(
          c.translate(r * 0.15, -r * 0.25),
          c.translate(r * 0.42, -r * 0.75),
          strawPaint,
        );
        break;

      case 3:
        // Polaroid #03: Mimi's bedroom window with ribbons
        final winRect = Rect.fromCenter(
          center: c,
          width: r * 1.25,
          height: r * 1.25,
        );
        canvas.drawRect(winRect, Paint()..color = const Color(0xFF3A1228));
        final framePaint = Paint()
          ..color = CuteHorrorPalette.hotPink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawRect(winRect, framePaint);
        canvas.drawLine(winRect.topCenter, winRect.bottomCenter, framePaint);
        canvas.drawLine(winRect.centerLeft, winRect.centerRight, framePaint);
        break;

      case 4:
        // Polaroid #04: Midnight mirror
        final mirrorRect = Rect.fromCenter(
          center: c,
          width: r * 1.05,
          height: r * 1.45,
        );
        canvas.drawOval(
          mirrorRect,
          Paint()..color = const Color(0xFFE3F4FF),
        );
        canvas.drawOval(
          mirrorRect,
          Paint()
            ..color = CuteHorrorPalette.hotPink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2,
        );
        // Silhouette shadow inside mirror
        canvas.drawCircle(
          c.translate(0, -r * 0.12),
          r * 0.26,
          Paint()..color = const Color(0xFF4A1525).withAlphaFactor(0.45),
        );
        break;

      case 5:
        // Polaroid #05: Deleted contacts / scissors & crossed user cards
        for (var i = -1; i <= 1; i++) {
          final cardRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c.translate(0, i * r * 0.42),
              width: r * 1.3,
              height: r * 0.30,
            ),
            const Radius.circular(6),
          );
          canvas.drawRRect(cardRect, Paint()..color = Colors.white);
          canvas.drawLine(
            cardRect.outerRect.centerLeft.translate(6, 0),
            cardRect.outerRect.centerRight.translate(-6, 0),
            Paint()
              ..color = CuteHorrorPalette.cyberCrimson
              ..strokeWidth = 2.4,
          );
        }
        break;

      case 6:
      default:
        // Polaroid #06: Last backup floppy/memory crystal
        final diskRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: r * 1.2, height: r * 1.2),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          diskRect,
          Paint()..color = CuteHorrorPalette.deepBerry,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: c.translate(0, -r * 0.28),
            width: r * 0.7,
            height: r * 0.35,
          ),
          Paint()..color = CuteHorrorPalette.pastelPink,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CutePolaroidArtworkPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.corruption != corruption;
  }
}

/// Painter for the hidden crimson steganography plane underneath each Polaroid.
class _HiddenStegoLayerPainter extends CustomPainter {
  final int index;
  final double corruption;

  const _HiddenStegoLayerPainter({
    required this.index,
    required this.corruption,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.16)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtle red crosshair in the background
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..color = CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, size.shortestSide * 0.36, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _HiddenStegoLayerPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.corruption != corruption;
  }
}
