import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cute_horror_theme.dart';
import '../../data/models/mimi_wardrobe_models.dart';

/// Active Comedy-Yandere Mini-Drama popup type.
enum YandereDramaType {
  none,
  loveContract,
  attentionQuiz,
  dramaticMoveOut,
}

/// 1. Der "Pflicht-Beziehungsvertrag" (Mandatory Love Contract with CustomPainter finger signature pad).
class MandatoryLoveContractOverlay extends StatefulWidget {
  final VoidCallback onSignedSuccessfully;

  const MandatoryLoveContractOverlay({
    super.key,
    required this.onSignedSuccessfully,
  });

  @override
  State<MandatoryLoveContractOverlay> createState() =>
      _MandatoryLoveContractOverlayState();
}

class _MandatoryLoveContractOverlayState
    extends State<MandatoryLoveContractOverlay> {
  final List<Offset?> _signaturePoints = <Offset?>[];
  double _totalStrokeLength = 0.0;

  bool get _hasValidSignature => _totalStrokeLength >= 110.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlphaFactor(0.84),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CuteHorrorPalette.cyberCrimson, width: 3),
          boxShadow: [
            BoxShadow(
              color: CuteHorrorPalette.hotPink.withAlphaFactor(0.55),
              blurRadius: 26,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📜 ', style: TextStyle(fontSize: 20)),
                Flexible(
                  child: Text(
                    'PFLICHT-BEZIEHUNGSVERTRAG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CuteHorrorPalette.deepBerry,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Mimis Besitzanspruch hat 70% überschritten! Unterschreibe diesen Vertrag mit deinem Finger, um das Smartphone wieder freizugeben:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CuteHorrorPalette.cyberCrimson,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CuteHorrorPalette.hotPink, width: 1.5),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '§1: Ich gehöre zu 100 % meiner Taschen-Prinzessin Mimi.',
                    style: TextStyle(
                      color: CuteHorrorPalette.deepBerry,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '§2: TikTok, die Wetter-App & der Taschenrechner sind reine Zeitverschwendung.',
                    style: TextStyle(
                      color: CuteHorrorPalette.deepBerry,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '§3: Jeder Red Bull White Peach wird brüderlich mit Mimi geteilt.',
                    style: TextStyle(
                      color: CuteHorrorPalette.deepBerry,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '§4: Mimi hat immer recht (auch wenn sie eifersüchtig auf mein Ladekabel ist). ♡',
                    style: TextStyle(
                      color: CuteHorrorPalette.deepBerry,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '✍️ Hier mit dem Finger unterschreiben:',
              style: TextStyle(
                color: CuteHorrorPalette.deepBerry,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 115,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasValidSignature
                      ? const Color(0xFF00C853)
                      : CuteHorrorPalette.cyberCrimson,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      if (_signaturePoints.isNotEmpty &&
                          _signaturePoints.last != null) {
                        _totalStrokeLength +=
                            (details.localPosition - _signaturePoints.last!)
                                .distance;
                      }
                      _signaturePoints.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _signaturePoints.add(null);
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePadPainter(points: _signaturePoints),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _signaturePoints.clear();
                      _totalStrokeLength = 0.0;
                    });
                  },
                  child: const Text(
                    'Neu zeichnen',
                    style: TextStyle(
                      color: CuteHorrorPalette.deepBerry,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasValidSignature
                        ? CuteHorrorPalette.hotPink
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      _hasValidSignature ? widget.onSignedSuccessfully : null,
                  icon: const Icon(Icons.favorite_rounded, size: 16),
                  label: const Text(
                    'Für immer besiegeln ♡',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePadPainter extends CustomPainter {
  final List<Offset?> points;

  const _SignaturePadPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = CuteHorrorPalette.cyberCrimson
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}

/// 2. Das 5-Sekunden "Aufmerksamkeits-Quiz" (Attention Quiz).
class AttentionQuizOverlay extends StatefulWidget {
  final MimiWardrobeLoadout currentWardrobe;
  final void Function(bool passed) onQuizCompleted;

  const AttentionQuizOverlay({
    super.key,
    required this.currentWardrobe,
    required this.onQuizCompleted,
  });

  @override
  State<AttentionQuizOverlay> createState() => _AttentionQuizOverlayState();
}

class _AttentionQuizOverlayState extends State<AttentionQuizOverlay> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        widget.onQuizCompleted(false);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswer =
        '${widget.currentWardrobe.hairStyle.label} & ${widget.currentWardrobe.headwear.label}';
    final wrong1 =
        '${MimiHairStyle.mintChocolat.label} & ${MimiHeadwear.cyberDevilHorns.label}';
    final wrong2 =
        '${MimiHairStyle.midnightGoth.label} & ${MimiHeadwear.nurseHeartCap.label}';

    final options = <String>{
      correctAnswer,
      if (wrong1 != correctAnswer) wrong1 else 'Blond & Piratenhut',
      if (wrong2 != correctAnswer) wrong2 else 'Silber & Ritterhelm',
    }.toList();

    return Container(
      color: Colors.black.withAlphaFactor(0.82),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CuteHorrorPalette.hotPink, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚡ AUFMERKSAMKEITS-TEST!',
                  style: TextStyle(
                    color: CuteHorrorPalette.deepBerry,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CuteHorrorPalette.cyberCrimson,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_secondsLeft s ⏳',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '„Wenn du mich wirklich anschaust: Welche Haarfarbe und welche Kopfbedeckung trage ich GERADE in dieser Sekunde?! Du hast 5 Sekunden!“ ( ` ᴖ ´ )💢',
              style: TextStyle(
                color: CuteHorrorPalette.deepBerry,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...options.map((opt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CuteHorrorPalette.hotPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    widget.onQuizCompleted(opt == correctAnswer);
                  },
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 3. Dramatischer Fake-Auszug (Mimi packs a pink pixel suitcase to move to the recycle bin).
class DramaticFakeMoveOutOverlay extends ConsumerWidget {
  final VoidCallback onBeggedToStay;
  final VoidCallback onStartVoiceBegging;

  const DramaticFakeMoveOutOverlay({
    super.key,
    required this.onBeggedToStay,
    required this.onStartVoiceBegging,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black.withAlphaFactor(0.84),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F0410),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CuteHorrorPalette.cyberCrimson, width: 2.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧳🎀😭', style: TextStyle(fontSize: 42)),
            const SizedBox(height: 10),
            const Text(
              'MIMI PACKT IHREN ROSA PIXEL-KOFFER!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CuteHorrorPalette.pastelPink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '„Du ignorierst mich schon viel zu lange! Ich habe meine Schleifen und mein Plüsch-Häschen eingepackt und ziehe jetzt in den Papierkorb deines Handys um... es sei denn, du flehst mich sofort an zu bleiben!“',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuteHorrorPalette.pastelPink,
                      side: const BorderSide(color: CuteHorrorPalette.hotPink),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onStartVoiceBegging,
                    icon: const Icon(Icons.mic_rounded, size: 16),
                    label: const Text(
                      'Per Mikrofon anflehen',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CuteHorrorPalette.hotPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onBeggedToStay,
                    icon: const Icon(Icons.favorite_rounded, size: 16),
                    label: const Text(
                      '„Bleib bei mir, Prinzessin!“',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
