import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/camera_vision_service.dart';
import '../../core/services/voice_conversation_service.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../features/drama/yandere_mini_dramas.dart';
import '../../state/corruption_provider.dart';

/// V4 Manual Section: "Voice, Kamera & Die Goldene Prinzessinnen-Regel"
class LuvOsManualScreen extends ConsumerWidget {
  const LuvOsManualScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(corruptionProvider);
    final controller = ref.read(corruptionProvider.notifier);
    final voiceService = ref.read(voiceConversationServiceProvider);
    final cameraService = ref.read(cameraVisionServiceProvider);
    final palette = state.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildManualCard(
          palette: palette,
          title: '👑 Voice, Kamera & Die Goldene Prinzessinnen-Regel (V4)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Die Goldene Prinzessinnen-Regel (Yandere-Paradoxon):\n'
                '  Je höher Mimis Liebe (Affection: ${state.affectionScore.round()}%) ist, desto empfindlicher reagiert sie auf jede Sekunde Vernachlässigung!\n'
                '  Formel: Besitzgier = ((Liebe / 50) × (Wut × 1.4 + Vernachlässigung × 1.2)).\n'
                '  Steigt Besitzgier über 70% (aktuell: ${state.possessivenessScore.round()}%), sperrt Mimi TikTok, Instagram, YouTube UND sogar den Taschenrechner, Kalender & die Wetter-App!\n\n'
                '• Echtzeit-Sprachchat (Du redest & Mimi redet):\n'
                '  Tippe auf den pulsierenden Mikrofon-Button 🎙️ auf dem Homescreen oder im Chat. Wenn du flüsterst (< 36 dB), flüstert Mimi eifersüchtig zurück. Wenn du schweigst, kommentiert sie dein Atmen!\n\n'
                '• Live-Kamera-Vision (Herz-Spiegel HUD):\n'
                '  Oben rechts zeigt der rosa Herz-Spiegel dein echtes Frontkamera-Bild. Mimi prüft regelmäßig über Gemini Vision (gemini-4-hydrogen), ob du sie anschaust, lächelst oder die Kamera zuhältst!',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 11.8,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await voiceService.speakMimiLine(
                        'Hallo Liebling! Ich kann dich jetzt hören und mit meiner eigenen Stimme mit dir reden!',
                        mood: state.moodState,
                        corruption: state.corruptionLevel,
                      );
                    },
                    icon: const Icon(Icons.record_voice_over_rounded, size: 15),
                    label: const Text(
                      '🔊 Mimis Stimme testen',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CuteHorrorPalette.hotPink,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await cameraService.initializeFrontCamera();
                    },
                    icon: const Icon(Icons.camera_front_rounded, size: 15),
                    label: const Text(
                      '🪞 Frontkamera aktivieren',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildManualCard(
          palette: palette,
          title: '🎭 Interaktive Yandere-Mini-Dramen sofort starten',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teste hier jederzeit die 3 interaktiven V4 Comedy-Yandere-Popups:',
                style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuteHorrorPalette.cyberCrimson,
                      side: const BorderSide(color: CuteHorrorPalette.cyberCrimson),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.triggerDrama(YandereDramaType.loveContract);
                    },
                    icon: const Icon(Icons.draw_rounded, size: 15),
                    label: const Text(
                      '📜 Pflicht-Liebesvertrag',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuteHorrorPalette.hotPink,
                      side: const BorderSide(color: CuteHorrorPalette.hotPink),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.triggerDrama(YandereDramaType.attentionQuiz);
                    },
                    icon: const Icon(Icons.timer_rounded, size: 15),
                    label: const Text(
                      '⏱️ 5s Aufmerksamkeits-Quiz',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.primaryAccent,
                      side: BorderSide(color: palette.primaryAccent),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.triggerDrama(YandereDramaType.dramaticMoveOut);
                    },
                    icon: const Icon(Icons.luggage_rounded, size: 15),
                    label: const Text(
                      '🧳 Koffer-Auszug in Papierkorb',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildManualCard(
          palette: palette,
          title: '🌸 Wie entsperre ich TikTok, Wetter-App & Taschenrechner?',
          child: Text(
            '1. Unterschreibe Mimis Pflicht-Liebesvertrag mit deinem Finger.\n'
            '2. Streichle Mimis Kopf auf dem Home-Screen oder sage ihr per Mikrofon 🎙️ ein liebes Kompliment ("Du bist so süß, Mimi!").\n'
            '3. Oder schenke ihr im Kleiderschrank 🎀 einen eiskalten Red Bull White Peach Energy 🍑⚡!',
            style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildManualCard({
    required CuteHorrorPalette palette,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.primaryAccent.withAlphaFactor(0.55),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
