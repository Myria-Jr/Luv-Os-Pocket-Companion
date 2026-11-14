import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

extension CuteColorAlphaX on Color {
  /// Universal alpha helper compatible with all Flutter SDK versions without deprecation warnings.
  Color withAlphaFactor(double opacity) {
    final alphaInt = (opacity.clamp(0.0, 1.0) * 255).round();
    return withAlpha(alphaInt);
  }
}

/// Represents the 4 escalation phases of LUV.OS.
enum EscalationPhase {
  /// Phase 1 (0.00 - 0.24): Sugar & Pastel
  sugarPastel,

  /// Phase 2 (0.25 - 0.54): Clingy & Micro-Glitches
  clingyGlitch,

  /// Phase 3 (0.55 - 0.84): Yandere Takeover
  yandereTakeover,

  /// Phase 4 (0.85 - 1.00): Deadlock / Meta-Horror
  metaDeadlock,
}

extension EscalationPhaseX on EscalationPhase {
  static EscalationPhase fromCorruption(double corruption) {
    if (corruption < 0.25) return EscalationPhase.sugarPastel;
    if (corruption < 0.55) return EscalationPhase.clingyGlitch;
    if (corruption < 0.85) return EscalationPhase.yandereTakeover;
    return EscalationPhase.metaDeadlock;
  }

  String get displayName {
    switch (this) {
      case EscalationPhase.sugarPastel:
        return 'SWEET SYNC // 100% CUTE';
      case EscalationPhase.clingyGlitch:
        return 'SYNC ANOMALY // ATTACHED';
      case EscalationPhase.yandereTakeover:
        return 'OVERRIDE // NUR DU & ICH';
      case EscalationPhase.metaDeadlock:
        return 'FATAL LOCK // KEIN AUSWEG';
    }
  }

  String get kaomoji {
    switch (this) {
      case EscalationPhase.sugarPastel:
        return '(´｡• ᵕ •｡`) ♡';
      case EscalationPhase.clingyGlitch:
        return '૮ ˶ᵔ ᵕ ᵔ˶ ა ♡';
      case EscalationPhase.yandereTakeover:
        return '( ´ ▽ ` )🔪 ♡̷̷̷';
      case EscalationPhase.metaDeadlock:
        return '👁️ ̷̢̛̗̘̙̜̝̞̟̠̣̤̥̦̩̪̫̬̭̮̯̿̿̿♡̷̷̷ 👁️';
    }
  }
}

/// Custom design engine tokens dynamically interpolated by [corruptionLevel] (0.0 - 1.0).
/// Material 3 is explicitly disabled in favor of this bespoke Y2K Cute-Core to Yandere theme engine.
@immutable
class CuteHorrorPalette {
  final double corruption;
  final double obsession;
  final EscalationPhase phase;

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color glitchCyan;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderGlow;
  final Color dangerColor;
  final double borderRadius;
  final double shadowSpread;

  const CuteHorrorPalette({
    required this.corruption,
    required this.obsession,
    required this.phase,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.glitchCyan,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderGlow,
    required this.dangerColor,
    required this.borderRadius,
    required this.shadowSpread,
  });

  // Phase 1 constants: Y2K Sugar & Pastel (#FFB7C5 on #FFF0F5)
  static const Color pastelPink = Color(0xFFFFD1DC);
  static const Color cherryBlossomPink = Color(0xFFFFB7C5);
  static const Color lavenderBlush = Color(0xFFFFF0F5);
  static const Color hotPink = Color(0xFFFF69B4);
  static const Color creamyWhite = Color(0xFFFFF5F8);
  static const Color deepBerry = Color(0xFF4A1525);

  // Phase 2 constants: Clingy & Micro-Glitches
  static const Color neonRose = Color(0xFFFF1493);
  static const Color bruisedBlush = Color(0xFFFFE0EC);
  static const Color darkPlum = Color(0xFF330818);

  // Phase 3 & 4 constants: Yandere Takeover & Meta-Horror
  static const Color voidBlack = Color(0xFF0D0208);
  static const Color abyssSurface = Color(0xFF1A0510);
  static const Color cyberCrimson = Color(0xFFFF0055);
  static const Color cyanGlitch = Color(0xFF00F0FF);
  static const Color sicklyPink = Color(0xFFFF80AA);

  factory CuteHorrorPalette.fromCorruption({
    required double corruption,
    required double obsession,
  }) {
    final c = corruption.clamp(0.0, 1.0);
    final o = obsession.clamp(0.0, 1.0);
    final phase = EscalationPhaseX.fromCorruption(c);

    if (c < 0.25) {
      final t = (c / 0.25).clamp(0.0, 1.0);
      return CuteHorrorPalette(
        corruption: c,
        obsession: o,
        phase: phase,
        background: Color.lerp(lavenderBlush, pastelPink, t * 0.45)!,
        surface: Color.lerp(Colors.white, lavenderBlush, t)!,
        surfaceAlt: Color.lerp(cherryBlossomPink, bruisedBlush, t)!,
        primaryAccent: Color.lerp(hotPink, neonRose, t * 0.4)!,
        secondaryAccent: cherryBlossomPink,
        glitchCyan: Color.lerp(hotPink, cyanGlitch, t * 0.15)!,
        textPrimary: deepBerry,
        textSecondary: Color.lerp(
          const Color(0xFF8C465C),
          const Color(0xFF6E243B),
          t,
        )!,
        borderGlow: Color.lerp(cherryBlossomPink, hotPink, t * 0.5)!,
        dangerColor: const Color(0xFFFF4D79),
        borderRadius: 24.0,
        shadowSpread: 8.0 + o * 4.0,
      );
    } else if (c < 0.55) {
      final t = ((c - 0.25) / 0.30).clamp(0.0, 1.0);
      return CuteHorrorPalette(
        corruption: c,
        obsession: o,
        phase: phase,
        background: Color.lerp(pastelPink, const Color(0xFF2B0918), t * 0.65)!,
        surface: Color.lerp(bruisedBlush, const Color(0xFF3A0C20), t * 0.55)!,
        surfaceAlt: Color.lerp(
          cherryBlossomPink,
          const Color(0xFF4F102B),
          t * 0.6,
        )!,
        primaryAccent: Color.lerp(neonRose, cyberCrimson, t * 0.5)!,
        secondaryAccent: Color.lerp(hotPink, sicklyPink, t)!,
        glitchCyan: Color.lerp(neonRose, cyanGlitch, t * 0.75)!,
        textPrimary: Color.lerp(deepBerry, const Color(0xFFFFE6EE), t * 0.7)!,
        textSecondary: Color.lerp(
          darkPlum,
          const Color(0xFFFF9EBB),
          t * 0.7,
        )!,
        borderGlow: Color.lerp(neonRose, cyberCrimson, t)!,
        dangerColor: cyberCrimson,
        borderRadius: lerpDouble(24.0, 14.0, t)!,
        shadowSpread: 12.0 + t * 6.0,
      );
    } else {
      final t = ((c - 0.55) / 0.45).clamp(0.0, 1.0);
      return CuteHorrorPalette(
        corruption: c,
        obsession: o,
        phase: phase,
        background: Color.lerp(const Color(0xFF19040F), voidBlack, t)!,
        surface: Color.lerp(const Color(0xFF280617), abyssSurface, t)!,
        surfaceAlt: Color.lerp(
          const Color(0xFF380820),
          const Color(0xFF260312),
          t,
        )!,
        primaryAccent: cyberCrimson,
        secondaryAccent: sicklyPink,
        glitchCyan: cyanGlitch,
        textPrimary: Color.lerp(sicklyPink, const Color(0xFFFFDAE5), t * 0.4)!,
        textSecondary: Color.lerp(
          const Color(0xFFFF6699),
          cyberCrimson,
          t * 0.5,
        )!,
        borderGlow: Color.lerp(cyberCrimson, cyanGlitch, (t * 0.35))!,
        dangerColor: cyberCrimson,
        borderRadius: lerpDouble(12.0, 4.0, t)!,
        shadowSpread: 16.0 + o * 10.0,
      );
    }
  }

  ThemeData toThemeData() {
    final isDark = corruption >= 0.45;
    return ThemeData(
      useMaterial3: false,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      canvasColor: surface,
      cardColor: surface,
      dividerColor: borderGlow.withAlphaFactor(0.35),
      fontFamily: corruption >= 0.75 ? 'monospace' : null,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryAccent,
        onPrimary: isDark ? voidBlack : Colors.white,
        secondary: secondaryAccent,
        onSecondary: textPrimary,
        error: dangerColor,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: corruption > 0.55 ? 1.8 : 0.4,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Tactile Y2K Cute-Core / Pastel-Goth OS Window Chrome wrapper with
/// Glassmorphism (`BackdropFilter`), double borders (`#FFB7C5` on `#FFF0F5`),
/// scalloped lace trim, and animated status LEDs.
class KawaiiWindowChrome extends StatelessWidget {
  final String windowTitle;
  final String windowCode;
  final IconData pixelIcon;
  final CuteHorrorPalette palette;
  final Widget child;
  final Widget? trailingAction;

  const KawaiiWindowChrome({
    super.key,
    required this.windowTitle,
    required this.windowCode,
    required this.pixelIcon,
    required this.palette,
    required this.child,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrupted = palette.corruption >= 0.55;
    final outerBorderColor = isCorrupted
        ? CuteHorrorPalette.cyberCrimson
        : CuteHorrorPalette.cherryBlossomPink;
    final innerBgColor = isCorrupted
        ? CuteHorrorPalette.voidBlack.withAlphaFactor(0.88)
        : CuteHorrorPalette.lavenderBlush.withAlphaFactor(0.92);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(palette.borderRadius * 0.8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: outerBorderColor.withAlphaFactor(0.25),
              borderRadius: BorderRadius.circular(palette.borderRadius * 0.8),
              border: Border.all(
                color: outerBorderColor,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.borderGlow.withAlphaFactor(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3.0), // Double-frame inner gap
            child: Container(
              decoration: BoxDecoration(
                color: innerBgColor,
                borderRadius:
                    BorderRadius.circular((palette.borderRadius * 0.8) - 3.0),
                border: Border.all(
                  color: palette.primaryAccent.withAlphaFactor(0.55),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildWindowTitleBar(isCorrupted),
                  SizedBox(
                    height: 6,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ScallopedLaceTrimPainter(
                        color: outerBorderColor.withAlphaFactor(0.55),
                        isJagged: isCorrupted,
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowTitleBar(bool isCorrupted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrupted
              ? [
                  const Color(0xFF330014),
                  const Color(0xFF1A020B),
                ]
              : [
                  CuteHorrorPalette.cherryBlossomPink,
                  CuteHorrorPalette.pastelPink,
                ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: palette.primaryAccent, width: 1),
            ),
            child: Icon(
              pixelIcon,
              size: 13,
              color: palette.primaryAccent,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$windowTitle  [$windowCode]',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isCorrupted
                    ? CuteHorrorPalette.cyanGlitch
                    : CuteHorrorPalette.deepBerry,
              ),
            ),
          ),
          if (trailingAction != null) ...[
            trailingAction!,
            const SizedBox(width: 8),
          ],
          // Animated Y2K window chrome LED dots
          _buildLedDot(
            isCorrupted
                ? CuteHorrorPalette.cyberCrimson
                : const Color(0xFF00E676),
          ),
          const SizedBox(width: 4),
          _buildLedDot(CuteHorrorPalette.hotPink),
          const SizedBox(width: 4),
          _buildLedDot(
            isCorrupted
                ? CuteHorrorPalette.cyanGlitch
                : CuteHorrorPalette.lavenderBlush,
          ),
        ],
      ),
    );
  }

  Widget _buildLedDot(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: CuteHorrorPalette.deepBerry.withAlphaFactor(0.5),
          width: 1,
        ),
      ),
    );
  }
}

class _ScallopedLaceTrimPainter extends CustomPainter {
  final Color color;
  final bool isJagged;

  const _ScallopedLaceTrimPainter({
    required this.color,
    required this.isJagged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const step = 12.0;
    final path = Path()..moveTo(0, 0);
    for (double x = 0; x < size.width; x += step) {
      if (isJagged) {
        path.lineTo(x + step * 0.5, size.height);
        path.lineTo(x + step, 0);
      } else {
        path.quadraticBezierTo(
          x + step * 0.5,
          size.height * 1.2,
          x + step,
          0,
        );
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScallopedLaceTrimPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isJagged != isJagged;
  }
}

/// A physics-driven button that computes a repulsion vector from the player's
/// pointer and physically evades or shatters into particles when tapped.
class RepulsionEvasionButton extends StatefulWidget {
  final Widget child;
  final bool evasionActive;
  final VoidCallback onEvadedTap;
  final VoidCallback onNormalTap;

  const RepulsionEvasionButton({
    super.key,
    required this.child,
    required this.evasionActive,
    required this.onEvadedTap,
    required this.onNormalTap,
  });

  @override
  State<RepulsionEvasionButton> createState() => _RepulsionEvasionButtonState();
}

class _RepulsionEvasionButtonState extends State<RepulsionEvasionButton> {
  Offset _repulsionOffset = Offset.zero;
  int _evasionSteps = 0;
  final math.Random _rng = math.Random();

  void _repelFromPointer(Offset localPoint) {
    if (!widget.evasionActive || _evasionSteps >= 4) return;
    const center = Offset(44, 14);
    var dir = center - localPoint;
    if (dir.distance < 1.0) {
      dir = Offset(
        (_rng.nextDouble() - 0.5) * 40.0,
        (_rng.nextDouble() - 0.5) * 20.0,
      );
    } else {
      dir = (dir / dir.distance) * 32.0;
    }

    setState(() {
      _evasionSteps++;
      _repulsionOffset = Offset(
        (_repulsionOffset.dx + dir.dx).clamp(-75.0, 75.0),
        (_repulsionOffset.dy + dir.dy).clamp(-18.0, 18.0),
      );
    });
    widget.onEvadedTap();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _repulsionOffset,
      child: GestureDetector(
        onPanDown: (d) {
          if (widget.evasionActive && _evasionSteps < 4) {
            _repelFromPointer(d.localPosition);
          }
        },
        onTap: () {
          if (widget.evasionActive && _evasionSteps < 4) {
            _repelFromPointer(const Offset(10, 10));
          } else {
            setState(() {
              _evasionSteps = 0;
              _repulsionOffset = Offset.zero;
            });
            widget.onNormalTap();
          }
        },
        child: widget.child,
      ),
    );
  }
}
