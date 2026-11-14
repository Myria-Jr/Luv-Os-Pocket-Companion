import 'package:flutter_test/flutter_test.dart';
import 'package:luv_os/core/database/luv_database.dart';
import 'package:luv_os/core/services/gemini_yandere_brain.dart';
import 'package:luv_os/core/services/procedural_audio_synth.dart';
import 'package:luv_os/core/theme/cute_horror_theme.dart';
import 'package:luv_os/data/models/emotional_vector.dart';
import 'package:luv_os/data/models/mimi_wardrobe_models.dart';
import 'package:luv_os/data/models/player_psych_profile.dart';
import 'package:luv_os/data/story_graph_data.dart';
import 'package:luv_os/state/corruption_provider.dart';

void main() {
  group('LUV.OS V2 Overhaul — Deep Architecture & Telemetry Tests', () {
    test('kStoryGraph contains at least 40 interconnected AdvancedStoryNodes with valid targets', () {
      expect(kStoryGraph.length, greaterThanOrEqualTo(40));
      expect(kStoryGraph.containsKey('node_01_welcome'), isTrue);

      for (final entry in kStoryGraph.entries) {
        final node = entry.value;
        expect(node.id, equals(entry.key));
        expect(node.mimiMessages, isNotEmpty);
        expect(node.choices, isNotEmpty);

        for (final choice in node.choices) {
          expect(
            kStoryGraph.containsKey(choice.targetNodeId),
            isTrue,
            reason:
                'Node ${node.id} has choice pointing to missing target ${choice.targetNodeId}',
          );
        }
      }
    });

    test('5D EmotionalVector & PlayerPsychProfile compute nervousness and yanderePressure', () {
      const initial = EmotionalVector.initial;
      expect(initial.affection, greaterThan(0.5));
      expect(initial.yanderePressure, lessThan(0.5));

      final escalated = initial.applyDelta(
        const EmotionalVector(
          obsession: 0.75,
          mania: 0.80,
          paranoia: 0.70,
          trust: -0.60,
        ),
      );
      expect(escalated.yanderePressure, greaterThan(0.65));

      final profile = PlayerPsychProfile.initial.copyWith(
        avgHesitationMs: 9500,
        totalBackspaces: 48,
        panicTapRate: 6.5,
        silenceCount: 3,
        emotion: escalated,
      );
      expect(profile.nervousness, greaterThan(0.45));
    });

    test('ProceduralAudioSynth generates valid RIFF/WAVE PCM16 byte streams in RAM', () {
      final synth = ProceduralAudioSynth()..setMuted(true);
      final wavBytes = synth.synthesizeCharacterBleep(
        'A',
        corruption: 0.35,
        mania: 0.25,
      );

      // Verify RIFF header ('RIFF' and 'WAVE')
      expect(wavBytes.length, greaterThan(44));
      expect(String.fromCharCodes(wavBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wavBytes.sublist(8, 12)), equals('WAVE'));
      expect(synth.classifyVowelShape('a'), equals(MimiVowelShape.vowelA));
      expect(synth.classifyVowelShape('o'), equals(MimiVowelShape.vowelO));
      synth.dispose();
    });

    test('LuvDatabase computes deterministic FNV-1a mutation signatures', () {
      final sig1 = LuvDatabase.computeMutationSignature(
        eventCode: 'KEY_DECRYPTED',
        details: 'KEY_ALPHA_ROSE',
        timestampMs: 1700000000000,
      );
      final sig2 = LuvDatabase.computeMutationSignature(
        eventCode: 'KEY_DECRYPTED',
        details: 'KEY_ALPHA_ROSE',
        timestampMs: 1700000000000,
      );
      expect(sig1, equals(sig2));
      expect(sig1.length, greaterThanOrEqualTo(12));
    });

    test('CuteHorrorPalette disables Material 3 and interpolates radius & colors', () {
      final phase1Palette = CuteHorrorPalette.fromCorruption(
        corruption: 0.05,
        obsession: 0.1,
      );
      final phase4Palette = CuteHorrorPalette.fromCorruption(
        corruption: 0.95,
        obsession: 0.9,
      );

      expect(phase1Palette.toThemeData().useMaterial3, isFalse);
      expect(phase4Palette.toThemeData().useMaterial3, isFalse);
      expect(phase1Palette.borderRadius, equals(24.0));
      expect(phase4Palette.borderRadius, lessThan(10.0));
    });

    test('V3 GeminiYandereBrain locks TikTok on rival app mention and unlocks on apology', () {
      final brain = GeminiYandereBrain();
      final rageDirective = brain.evaluateLocalHeuristic(
        playerMessage: 'Ich gehe jetzt auf TikTok scrollen!',
        corruption: 0.35,
        affection: 0.70,
        obsession: 0.40,
        currentlyLocked: false,
      );

      expect(rageDirective.moodState, equals(MimiMoodState.yandereRage));
      expect(rageDirective.systemAction.lockApps, isTrue);
      expect(rageDirective.systemAction.blockedCategories, contains('TikTok'));
      expect(rageDirective.systemAction.requiredHeadpatsToUnlock, greaterThan(0));

      final forgiveDirective = brain.evaluateLocalHeuristic(
        playerMessage: 'Tut mir leid Mimi, ich hab dich lieb ♡',
        corruption: 0.35,
        affection: 0.70,
        obsession: 0.40,
        currentlyLocked: true,
      );

      expect(forgiveDirective.moodState, equals(MimiMoodState.lovestruck));
      expect(forgiveDirective.systemAction.lockApps, isFalse);

      const wardrobe = MimiWardrobeLoadout(
        hairStyle: MimiHairStyle.lavenderDream,
        headwear: MimiHeadwear.maidFrillBand,
        faceAccessory: MimiFaceAccessory.pinkHeartGlasses,
        collarStyle: MimiCollarStyle.gothLoliChoker,
      );
      final restored = MimiWardrobeLoadout.fromJson(wardrobe.toJson());
      expect(restored.hairStyle, equals(MimiHairStyle.lavenderDream));
      expect(restored.headwear, equals(MimiHeadwear.maidFrillBand));
    });

    test('V4 Yandere-Paradox-Engine formula & Comedy-Yandere triggers (Whisper, Weather, White Peach)', () {
      const calmState = CorruptionState(
        affectionScore: 75.0,
        neglectScore: 8.0,
        angerScore: 5.0,
      );
      expect(calmState.possessivenessScore, lessThan(35.0));

      const neglectedHighLoveState = CorruptionState(
        affectionScore: 100.0,
        neglectScore: 30.0,
        angerScore: 20.0,
      );
      // ((100 / 50) * (20 * 1.4 + 30 * 1.2)) = 2 * (28 + 36) = 128 -> clamped to 100.0
      expect(neglectedHighLoveState.possessivenessScore, equals(100.0));

      final brain = GeminiYandereBrain();
      final whisperDirective = brain.evaluateLocalHeuristic(
        playerMessage: 'Bist du noch wach?',
        corruption: 0.25,
        affection: 0.80,
        obsession: 0.30,
        currentlyLocked: false,
        wasWhispered: true,
      );
      expect(whisperDirective.moodState, equals(MimiMoodState.jealous));
      expect(whisperDirective.spokenText.toLowerCase(), contains('flüsterst'));

      final weatherDirective = brain.evaluateLocalHeuristic(
        playerMessage: 'Wie wird heute das Wetter draußen?',
        corruption: 0.25,
        affection: 0.80,
        obsession: 0.30,
        currentlyLocked: false,
      );
      expect(weatherDirective.systemAction.lockApps, isTrue);
      expect(
        weatherDirective.systemAction.blockedCategories,
        contains('Wetter-App'),
      );

      final whitePeachDirective = brain.evaluateLocalHeuristic(
        playerMessage: 'Hier ist ein Red Bull White Peach für dich!',
        corruption: 0.35,
        affection: 0.80,
        obsession: 0.50,
        currentlyLocked: true,
      );
      expect(whitePeachDirective.moodState, equals(MimiMoodState.lovestruck));
      expect(whitePeachDirective.systemAction.lockApps, isFalse);
      expect(
        kMimiGiftCatalog.any((g) => g.id == 'gift_white_peach_energy'),
        isTrue,
      );
    });
  });
}
