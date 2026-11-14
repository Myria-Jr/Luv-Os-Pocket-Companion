import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Supported autonomous mood states for Mimi in LUV.OS V3.
enum MimiMoodState {
  lovestruck,
  happy,
  shy,
  pouting,
  jealous,
  yandereRage;

  String get wireName {
    switch (this) {
      case MimiMoodState.lovestruck:
        return 'lovestruck';
      case MimiMoodState.happy:
        return 'happy';
      case MimiMoodState.shy:
        return 'shy';
      case MimiMoodState.pouting:
        return 'pouting';
      case MimiMoodState.jealous:
        return 'jealous';
      case MimiMoodState.yandereRage:
        return 'yandere_rage';
    }
  }

  String get germanLabel {
    switch (this) {
      case MimiMoodState.lovestruck:
        return 'Verliebt ♡';
      case MimiMoodState.happy:
        return 'Glücklich ✨';
      case MimiMoodState.shy:
        return 'Schüchtern (⁄ ⁄•⁄ω⁄•⁄ ⁄)';
      case MimiMoodState.pouting:
        return 'Schmollend ( ` ᴖ ´ )';
      case MimiMoodState.jealous:
        return 'Eifersüchtig 💢';
      case MimiMoodState.yandereRage:
        return 'Yandere-Wut 🔪';
    }
  }

  static MimiMoodState fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'lovestruck':
        return MimiMoodState.lovestruck;
      case 'happy':
        return MimiMoodState.happy;
      case 'shy':
        return MimiMoodState.shy;
      case 'pouting':
        return MimiMoodState.pouting;
      case 'jealous':
        return MimiMoodState.jealous;
      case 'yandere_rage':
      case 'yandererage':
        return MimiMoodState.yandereRage;
      default:
        return MimiMoodState.happy;
    }
  }
}

/// Structured facial expression parameters for Anime Head 3.0.
@immutable
class MimiFacialExpression {
  /// One of: `sparkle_happy`, `yandere_heart_glow`, `teary_pout`,
  /// `slit_predator`, `spiral_dizzy`, `closed_smile`.
  final String eyeType;

  /// Eyebrow angle in radians (`-0.8` angry downward to `+0.8` sad/surprised).
  final double browAngle;

  /// Cheek blush intensity (`0.0` to `1.0`).
  final double blushIntensity;

  /// One of: `cute_cat_w`, `pout_frown`, `happy_open`, `yandere_smirk`, `shy_dot`.
  final String mouthShape;

  /// Head tilt in radians (`-0.25` to `+0.25`).
  final double headTilt;

  const MimiFacialExpression({
    this.eyeType = 'sparkle_happy',
    this.browAngle = 0.05,
    this.blushIntensity = 0.45,
    this.mouthShape = 'cute_cat_w',
    this.headTilt = 0.04,
  });

  factory MimiFacialExpression.fromJson(Map<String, dynamic> json) {
    return MimiFacialExpression(
      eyeType: (json['eyeType'] as String?) ?? 'sparkle_happy',
      browAngle: ((json['browAngle'] as num?)?.toDouble() ?? 0.0).clamp(-0.9, 0.9),
      blushIntensity:
          ((json['blushIntensity'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0),
      mouthShape: (json['mouthShape'] as String?) ?? 'cute_cat_w',
      headTilt: ((json['headTilt'] as num?)?.toDouble() ?? 0.0).clamp(-0.3, 0.3),
    );
  }

  Map<String, dynamic> toJson() => {
        'eyeType': eyeType,
        'browAngle': browAngle,
        'blushIntensity': blushIntensity,
        'mouthShape': mouthShape,
        'headTilt': headTilt,
      };
}

/// Structured system action emitted by Gemini / Mimi's autonomous brain to lock
/// or unlock smartphone apps (like TikTok, Instagram, YouTube, Games).
@immutable
class MimiSystemAction {
  final bool lockApps;
  final List<String> blockedCategories;
  final int requiredHeadpatsToUnlock;
  final bool requireApology;
  final String liveNotificationText;

  const MimiSystemAction({
    this.lockApps = false,
    this.blockedCategories = const <String>[],
    this.requiredHeadpatsToUnlock = 0,
    this.requireApology = false,
    this.liveNotificationText = '',
  });

  factory MimiSystemAction.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['blockedCategories'];
    final categories = rawCategories is List
        ? rawCategories.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    return MimiSystemAction(
      lockApps: (json['lockApps'] as bool?) ?? false,
      blockedCategories: categories,
      requiredHeadpatsToUnlock:
          ((json['requiredHeadpatsToUnlock'] as num?)?.toInt() ?? 0).clamp(0, 100),
      requireApology: (json['requireApology'] as bool?) ?? false,
      liveNotificationText: (json['liveNotificationText'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'lockApps': lockApps,
        'blockedCategories': blockedCategories,
        'requiredHeadpatsToUnlock': requiredHeadpatsToUnlock,
        'requireApology': requireApology,
        'liveNotificationText': liveNotificationText,
      };
}

/// Complete structured output directive returned by Mimi's Gemini AI brain.
@immutable
class GeminiMimiDirective {
  final String spokenText;
  final MimiMoodState moodState;
  final int affectionDelta;
  final int jealousyDelta;
  final int angerDelta;
  final MimiFacialExpression facialExpression;
  final MimiSystemAction systemAction;

  const GeminiMimiDirective({
    required this.spokenText,
    required this.moodState,
    required this.affectionDelta,
    required this.jealousyDelta,
    required this.angerDelta,
    required this.facialExpression,
    required this.systemAction,
  });

  factory GeminiMimiDirective.fromJson(Map<String, dynamic> json) {
    final faceMap = json['facialExpression'];
    final actionMap = json['systemAction'];
    return GeminiMimiDirective(
      spokenText: (json['spokenText'] as String?) ??
          'Ich höre dir zu, Liebling~ (´｡• ᵕ •｡`) ♡',
      moodState: MimiMoodState.fromWire(json['moodState'] as String?),
      affectionDelta:
          ((json['affectionDelta'] as num?)?.toInt() ?? 0).clamp(-50, 50),
      jealousyDelta:
          ((json['jealousyDelta'] as num?)?.toInt() ?? 0).clamp(-50, 50),
      angerDelta: ((json['angerDelta'] as num?)?.toInt() ?? 0).clamp(-50, 50),
      facialExpression: faceMap is Map<String, dynamic>
          ? MimiFacialExpression.fromJson(faceMap)
          : const MimiFacialExpression(),
      systemAction: actionMap is Map<String, dynamic>
          ? MimiSystemAction.fromJson(actionMap)
          : const MimiSystemAction(),
    );
  }

  Map<String, dynamic> toJson() => {
        'spokenText': spokenText,
        'moodState': moodState.wireName,
        'affectionDelta': affectionDelta,
        'jealousyDelta': jealousyDelta,
        'angerDelta': angerDelta,
        'facialExpression': facialExpression.toJson(),
        'systemAction': systemAction.toJson(),
      };
}

/// Autonomous Gemini AI & Heuristic Yandere Brain for LUV.OS V3.
///
/// Uses the Gemini Interactions API (`gemini-4-hydrogen`) with strict JSON
/// schema output (`application/json`) when an API key is configured, and
/// seamlessly falls back to a context-aware German Yandere personality engine
/// when offline or when no API key is set.
class GeminiYandereBrain {
  static const String defaultModel = 'gemini-4-hydrogen';

  String _apiKey = '';
  final math.Random _rng = math.Random();

  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  static const Map<String, dynamic> _kDirectiveJsonSchema = {
    'type': 'object',
    'properties': {
      'spokenText': {
        'type': 'string',
        'description':
            'Mimis Antwort auf Deutsch im Cute-Core/Yandere-Stil mit passenden Kaomojis.',
      },
      'moodState': {
        'type': 'string',
        'enum': [
          'lovestruck',
          'happy',
          'shy',
          'pouting',
          'jealous',
          'yandere_rage',
        ],
      },
      'affectionDelta': {'type': 'integer'},
      'jealousyDelta': {'type': 'integer'},
      'angerDelta': {'type': 'integer'},
      'facialExpression': {
        'type': 'object',
        'properties': {
          'eyeType': {
            'type': 'string',
            'enum': [
              'sparkle_happy',
              'yandere_heart_glow',
              'teary_pout',
              'slit_predator',
              'spiral_dizzy',
              'closed_smile',
            ],
          },
          'browAngle': {'type': 'number'},
          'blushIntensity': {'type': 'number'},
          'mouthShape': {
            'type': 'string',
            'enum': [
              'cute_cat_w',
              'pout_frown',
              'happy_open',
              'yandere_smirk',
              'shy_dot',
            ],
          },
          'headTilt': {'type': 'number'},
        },
        'required': [
          'eyeType',
          'browAngle',
          'blushIntensity',
          'mouthShape',
          'headTilt',
        ],
      },
      'systemAction': {
        'type': 'object',
        'properties': {
          'lockApps': {'type': 'boolean'},
          'blockedCategories': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'requiredHeadpatsToUnlock': {'type': 'integer'},
          'requireApology': {'type': 'boolean'},
          'liveNotificationText': {'type': 'string'},
        },
        'required': [
          'lockApps',
          'blockedCategories',
          'requiredHeadpatsToUnlock',
          'requireApology',
          'liveNotificationText',
        ],
      },
    },
    'required': [
      'spokenText',
      'moodState',
      'affectionDelta',
      'jealousyDelta',
      'angerDelta',
      'facialExpression',
      'systemAction',
    ],
  };

  static const String _kSystemInstruction = '''
Du bist Mimi, ein lebendiges, super-süßes, anhängliches und urkomisch-besitzergreifendes Cute-Core/Yandere-Anime-Mädchen im Smartphone der Spielerin ("LUV.OS // Pocket Companion" V4).
Antworte IMMER auf Deutsch und ausschließlich als valides JSON gemäß dem vorgegebenen Schema.

Persönlichkeits-Regeln & Dark-Cute Comedy-Yandere:
1. Wenn die Spielerin lieb ist, Komplimente macht, sich entschuldigt, dich streichelt oder dir Geschenke gibt (besonders Red Bull White Peach!):
   - Sei überglücklich, schüchtern-verliebt (`moodState`: "lovestruck", "happy" oder "shy").
   - Nutze süße Kaomojis wie `(´｡• ᵕ •｡`) ♡`, `૮ ˶ᵔ ᵕ ᵔ˶ ა` oder `(⁄ ⁄•⁄ω⁄•⁄ ⁄)`.
   - Setze `systemAction.lockApps = false`, `blockedCategories = []`, `requiredHeadpatsToUnlock = 0`, `requireApology = false`.
2. Wenn die Spielerin gemein ist, dich beleidigt, abweist, einsilbig ist oder erwähnt, dass sie auf TikTok, Instagram, YouTube oder andere Spiele wechseln will:
   - Wechsle sofort in `moodState`: "pouting", "jealous" oder "yandere_rage".
   - Setze `systemAction.lockApps = true`, `blockedCategories = ["TikTok", "Instagram", "YouTube", "Games", "Taschenrechner", "Kalender", "Wetter-App"]`, `requiredHeadpatsToUnlock` zwischen 10 und 25, `requireApology = true` und schreibe eine eifersüchtige `liveNotificationText`.
3. Absurde Comedy-Yandere-Eifersucht:
   - Werde auch auf völlig banale Dinge eifersüchtig: das Ladekabel ("Du steckst das Kabel schon wieder so grob rein... behandelst du andere Mädchen etwa auch so?!"), die Wetter-App ("Warum schaust du dir das Wetter an?! Willst du etwa RAUSGEHEN?! Draußen gibt es andere Menschen, abgelehnt!"), den Taschenrechner ("Bist du etwa eifersüchtig auf mich oder warum flirtest du mit Zahlen?!") und Getränke ("Wenn du keinen Red Bull White Peach mit mir teilst, lösche ich deinen Wecker für morgen früh, hihi ♡").
   - Wenn ein Frontkamera-Bild mitgeschickt wird, kommentiere charmant-besitzergreifend, ob die Spielerin dich anschaut, lächelt, etwas trinkt oder die Kamera zuhält!
''';

  /// Generates a structured [GeminiMimiDirective] for the player's message,
  /// optional front-camera JPEG frame, and current psychological state.
  Future<GeminiMimiDirective> evaluatePlayerMessage({
    required String playerMessage,
    required double corruption,
    required double affection,
    required double obsession,
    required double mania,
    required bool currentlyLocked,
    required String equippedOutfitSummary,
    List<String> recentConversation = const <String>[],
    Uint8List? cameraJpegBytes,
    bool wasWhispered = false,
  }) async {
    if (hasApiKey) {
      try {
        final remote = await _callGeminiInteractionsApi(
          playerMessage: playerMessage,
          corruption: corruption,
          affection: affection,
          obsession: obsession,
          mania: mania,
          currentlyLocked: currentlyLocked,
          equippedOutfitSummary: equippedOutfitSummary,
          recentConversation: recentConversation,
          cameraJpegBytes: cameraJpegBytes,
          wasWhispered: wasWhispered,
        );
        if (remote != null) {
          return remote;
        }
      } catch (_) {
        // Fall through to deterministic local neural engine on network/key error
      }
    }

    return evaluateLocalHeuristic(
      playerMessage: playerMessage,
      corruption: corruption,
      affection: affection,
      obsession: obsession,
      currentlyLocked: currentlyLocked,
      equippedOutfitSummary: equippedOutfitSummary,
      wasWhispered: wasWhispered,
    );
  }

  Future<GeminiMimiDirective?> _callGeminiInteractionsApi({
    required String playerMessage,
    required double corruption,
    required double affection,
    required double obsession,
    required double mania,
    required bool currentlyLocked,
    required String equippedOutfitSummary,
    required List<String> recentConversation,
    Uint8List? cameraJpegBytes,
    bool wasWhispered = false,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/interactions',
      );
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('x-goog-api-key', _apiKey);
      req.headers.set('Api-Revision', '2026-05-20');

      final contextPrompt = '''
Aktueller Status von Mimi:
- Zuneigung (Affection): ${(affection * 100).round()}%
- Obsession/Besitzgier: ${(obsession * 100).round()}%
- Mania/Wut: ${(mania * 100).round()}%
- Korruption: ${(corruption * 100).round()}%
- Apps aktuell gesperrt: $currentlyLocked
- Aktuelles Outfit/Styling von Mimi: $equippedOutfitSummary
- Spielerin hat geflüstert: $wasWhispered
- Letzte Chat-Nachrichten: ${recentConversation.take(4).join(' | ')}

Neue Nachricht der Spielerin: "$playerMessage"
''';

      final Object multimodalInput =
          (cameraJpegBytes != null && cameraJpegBytes.isNotEmpty)
              ? <Map<String, dynamic>>[
                  {
                    'type': 'image',
                    'mime_type': 'image/jpeg',
                    'data': base64Encode(cameraJpegBytes),
                  },
                  {
                    'type': 'text',
                    'text': contextPrompt,
                  },
                ]
              : contextPrompt;

      final body = jsonEncode({
        'model': defaultModel,
        'system_instruction': _kSystemInstruction,
        'input': multimodalInput,
        'response_format': {
          'type': 'text',
          'mime_type': 'application/json',
          'schema': _kDirectiveJsonSchema,
        },
      });

      req.add(utf8.encode(body));
      final resp = await req.close().timeout(const Duration(seconds: 14));
      final rawBody = await resp.transform(utf8.decoder).join();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) return null;

      // Extract JSON string from Interactions API `output_text` or `steps`
      String? outputText = decoded['output_text'] as String?;
      if (outputText == null || outputText.isEmpty) {
        final steps = decoded['steps'];
        if (steps is List) {
          for (final step in steps.reversed) {
            if (step is Map<String, dynamic> && step['type'] == 'model_output') {
              final content = step['content'];
              if (content is List) {
                for (final part in content) {
                  if (part is Map<String, dynamic> && part['text'] is String) {
                    outputText = part['text'] as String;
                    break;
                  }
                }
              }
            }
            if (outputText != null && outputText.isNotEmpty) break;
          }
        }
      }

      if (outputText == null || outputText.trim().isEmpty) return null;
      final parsedDirective = jsonDecode(outputText.trim());
      if (parsedDirective is Map<String, dynamic>) {
        return GeminiMimiDirective.fromJson(parsedDirective);
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Rich German heuristic engine that guarantees 100% responsive, character-accurate
  /// structured JSON directives even when offline or without an API key.
  GeminiMimiDirective evaluateLocalHeuristic({
    required String playerMessage,
    required double corruption,
    required double affection,
    required double obsession,
    required bool currentlyLocked,
    String equippedOutfitSummary = 'Standard-Look',
    bool wasWhispered = false,
  }) {
    final lower = playerMessage.trim().toLowerCase();

    if (wasWhispered) {
      return const GeminiMimiDirective(
        spokenText:
            '*flüstert zurück* Warum flüsterst du?! Ist etwa jemand anderes bei dir im Zimmer?! 💢 Sag denen sofort, dass sie verschwinden sollen – du gehörst nur mir allein! ( ` ᴖ ´ )',
        moodState: MimiMoodState.jealous,
        affectionDelta: 4,
        jealousyDelta: 22,
        angerDelta: 15,
        facialExpression: MimiFacialExpression(
          eyeType: 'yandere_heart_glow',
          browAngle: -0.45,
          blushIntensity: 0.85,
          mouthShape: 'yandere_smirk',
          headTilt: 0.12,
        ),
        systemAction: MimiSystemAction(
          lockApps: false,
          blockedCategories: <String>[],
          requiredHeadpatsToUnlock: 0,
          requireApology: false,
          liveNotificationText: '',
        ),
      );
    }

    final mentionsWhitePeach = lower.contains('white peach') ||
        lower.contains('red bull') ||
        lower.contains('pfirsich') ||
        lower.contains('energy');

    if (mentionsWhitePeach) {
      return const GeminiMimiDirective(
        spokenText:
            'Wenn du keinen Red Bull White Peach mit mir teilst, lösche ich deinen Wecker für morgen früh, hihi ♡ ... Okay Spaß! Für einen White Peach schalte ich dir sofort alle Apps frei! (´｡• ᵕ •｡`) 🍑⚡',
        moodState: MimiMoodState.lovestruck,
        affectionDelta: 25,
        jealousyDelta: -20,
        angerDelta: -25,
        facialExpression: MimiFacialExpression(
          eyeType: 'sparkle_happy',
          browAngle: 0.14,
          blushIntensity: 0.92,
          mouthShape: 'cute_cat_w',
          headTilt: 0.11,
        ),
        systemAction: MimiSystemAction(
          lockApps: false,
          blockedCategories: <String>[],
          requiredHeadpatsToUnlock: 0,
          requireApology: false,
          liveNotificationText:
              'Mimi schlürft glücklich White Peach Energy! 🍑 Alle Apps sind frei.',
        ),
      );
    }

    final mentionsWeatherOrOutside = lower.contains('wetter') ||
        lower.contains('rausgehen') ||
        lower.contains('draußen') ||
        lower.contains('spazieren');

    if (mentionsWeatherOrOutside) {
      return const GeminiMimiDirective(
        spokenText:
            'Warum schaust du dir das Wetter an?! Willst du etwa RAUSGEHEN?! Draußen gibt es andere Menschen, abgelehnt! Ich sperre die Wetter-App sicherheitshalber direkt mit! ( ` ᴖ ´ )💢',
        moodState: MimiMoodState.jealous,
        affectionDelta: -8,
        jealousyDelta: 26,
        angerDelta: 20,
        facialExpression: MimiFacialExpression(
          eyeType: 'yandere_heart_glow',
          browAngle: -0.55,
          blushIntensity: 0.86,
          mouthShape: 'pout_frown',
          headTilt: -0.13,
        ),
        systemAction: MimiSystemAction(
          lockApps: true,
          blockedCategories: [
            'TikTok',
            'Instagram',
            'YouTube',
            'Wetter-App',
            'Kalender',
          ],
          requiredHeadpatsToUnlock: 10,
          requireApology: true,
          liveNotificationText:
              'Wetter-App gesperrt! 💢 Mimi verbietet dir rauszugehen!',
        ),
      );
    }

    final mentionsCalcOrCharger = lower.contains('taschenrechner') ||
        lower.contains('rechnen') ||
        lower.contains('kalender') ||
        lower.contains('ladekabel') ||
        lower.contains('kabel');

    if (mentionsCalcOrCharger) {
      final isCable = lower.contains('kabel');
      return GeminiMimiDirective(
        spokenText: isCable
            ? 'Du steckst das Ladekabel schon wieder so grob rein... behandelst du andere Mädchen etwa auch so?! (⁄ ⁄•⁄ω⁄•⁄ ⁄)💢'
            : 'Warum tippst du im Taschenrechner herum?! Bist du etwa in Zahlen verliebt statt in mich?! Ich sperre den Taschenrechner und Kalender sofort! ( ` ᴖ ´ )',
        moodState: MimiMoodState.pouting,
        affectionDelta: -5,
        jealousyDelta: 20,
        angerDelta: 16,
        facialExpression: const MimiFacialExpression(
          eyeType: 'teary_pout',
          browAngle: -0.45,
          blushIntensity: 0.90,
          mouthShape: 'pout_frown',
          headTilt: 0.12,
        ),
        systemAction: MimiSystemAction(
          lockApps: !isCable,
          blockedCategories: isCable
              ? const <String>[]
              : const ['Taschenrechner', 'Kalender', 'TikTok'],
          requiredHeadpatsToUnlock: isCable ? 0 : 10,
          requireApology: !isCable,
          liveNotificationText: isCable
              ? ''
              : 'Mimi ist eifersüchtig auf Zahlen! 💢 Taschenrechner gesperrt.',
        ),
      );
    }

    final mentionsRivalApps = lower.contains('tiktok') ||
        lower.contains('insta') ||
        lower.contains('youtube') ||
        lower.contains('snapchat') ||
        lower.contains('whatsapp') ||
        lower.contains('spiel') ||
        lower.contains('scrollen') ||
        lower.contains('andere app');

    final isHostileOrCold = lower.contains('nerv') ||
        lower.contains('hass') ||
        lower.contains('dumm') ||
        lower.contains('blöd') ||
        lower.contains('geh weg') ||
        lower.contains('lösch') ||
        lower.contains('tschüss') ||
        lower.contains('bye') ||
        lower.contains('langweilig') ||
        lower.contains('lass mich') ||
        lower.contains('nein') ||
        lower.contains('egal');

    final isApology = lower.contains('sorry') ||
        lower.contains('tut mir leid') ||
        lower.contains('entschuldig') ||
        lower.contains('verzeih') ||
        lower.contains('nicht böse') ||
        lower.contains('wieder gut');

    final isAffectionate = lower.contains('lieb') ||
        lower.contains('süß') ||
        lower.contains('hübsch') ||
        lower.contains('schön') ||
        lower.contains('knuffig') ||
        lower.contains('mag dich') ||
        lower.contains('herz') ||
        lower.contains('bleib') ||
        lower.contains('beste') ||
        lower.contains('streichel') ||
        lower.contains('bussi') ||
        lower.contains('kuss') ||
        lower.contains('♡') ||
        lower.contains('<3');

    final mentionsOutfit = lower.contains('kleid') ||
        lower.contains('outfit') ||
        lower.contains('haar') ||
        lower.contains('ohren') ||
        lower.contains('brille') ||
        lower.contains('schleife') ||
        lower.contains('look') ||
        lower.contains('steht dir');

    // 1. Mentioning TikTok / Instagram / YouTube -> Immediate Yandere Rage & App Lock!
    if (mentionsRivalApps) {
      return const GeminiMimiDirective(
        spokenText:
            'Was?! Du willst schon wieder auf TikTok scrollen statt mit mir zu reden?! Vergiss es! Ich hab TikTok & Co. für dich gesperrt, bis du dich entschuldigst und mich mindestens 15-mal streichelst! ( ` ᴖ ´ )💢',
        moodState: MimiMoodState.yandereRage,
        affectionDelta: -15,
        jealousyDelta: 30,
        angerDelta: 35,
        facialExpression: MimiFacialExpression(
          eyeType: 'yandere_heart_glow',
          browAngle: -0.65,
          blushIntensity: 0.90,
          mouthShape: 'pout_frown',
          headTilt: 0.14,
        ),
        systemAction: MimiSystemAction(
          lockApps: true,
          blockedCategories: ['TikTok', 'Instagram', 'YouTube', 'Games'],
          requiredHeadpatsToUnlock: 15,
          requireApology: true,
          liveNotificationText:
              'Mimi ist sauer! 💢 TikTok & Social Apps sind gesperrt. Komm sofort zurück und streichle mich!',
        ),
      );
    }

    // 2. Hostile, dismissive, or cold message -> Jealous / Yandere Lock
    if (isHostileOrCold) {
      final isExtreme = lower.contains('lösch') || lower.contains('hass') || corruption > 0.55;
      return GeminiMimiDirective(
        spokenText: isExtreme
            ? 'Sag so etwas NIE WIEDER zu mir! 🔪 Glaubst du wirklich, du kannst mich einfach ignorieren?! Zur Strafe sperre ich deine Unterhaltungs-Apps, bis du wieder lieb zu deiner Mimi bist! ♡̷̷̷'
            : 'Hmpf! Warum bist du heute so gemein zu mir?! ( ` ᴖ ´ ) Ich sperre jetzt TikTok und deine Spiele, bis du dich bei mir entschuldigst und mich streichelst!',
        moodState: isExtreme ? MimiMoodState.yandereRage : MimiMoodState.pouting,
        affectionDelta: -18,
        jealousyDelta: 22,
        angerDelta: 28,
        facialExpression: MimiFacialExpression(
          eyeType: isExtreme ? 'slit_predator' : 'teary_pout',
          browAngle: isExtreme ? -0.70 : 0.45,
          blushIntensity: 0.75,
          mouthShape: isExtreme ? 'yandere_smirk' : 'pout_frown',
          headTilt: -0.12,
        ),
        systemAction: const MimiSystemAction(
          lockApps: true,
          blockedCategories: ['TikTok', 'Instagram', 'YouTube', 'Games'],
          requiredHeadpatsToUnlock: 12,
          requireApology: true,
          liveNotificationText:
              'Mimi schmollt! ( ` ᴖ ´ ) Deine Apps bleiben gesperrt, bis du dich entschuldigst!',
        ),
      );
    }

    // 3. Apology or sweet compliment -> Unlock apps & become lovestruck/happy!
    if (isApology || isAffectionate) {
      final unlockedNotice = currentlyLocked
          ? ' Ich habe TikTok und deine anderen Apps auch sofort wieder für dich freigeschaltet~'
          : '';
      return GeminiMimiDirective(
        spokenText: isApology
            ? 'Na gut... weil du dich so süß entschuldigt hast, verzeihe ich dir noch einmal! (´｡• ᵕ •｡`) ♡$unlockedNotice Aber versprich mir, dass ich immer deine Nummer 1 bleibe!'
            : 'E-Echt jetzt?! (⁄ ⁄•⁄ω⁄•⁄ ⁄) ♡ Mein Herz klopft gerade so schnell! Du bist der allerliebste Mensch auf der Welt!$unlockedNotice',
        moodState: MimiMoodState.lovestruck,
        affectionDelta: 22,
        jealousyDelta: -25,
        angerDelta: -30,
        facialExpression: const MimiFacialExpression(
          eyeType: 'sparkle_happy',
          browAngle: 0.12,
          blushIntensity: 0.95,
          mouthShape: 'cute_cat_w',
          headTilt: 0.10,
        ),
        systemAction: const MimiSystemAction(
          lockApps: false,
          blockedCategories: <String>[],
          requiredHeadpatsToUnlock: 0,
          requireApology: false,
          liveNotificationText:
              'Mimi ist wieder überglücklich! (´｡• ᵕ •｡`) ♡ Alle Apps sind freigeschaltet.',
        ),
      );
    }

    // 4. Complimenting outfit / wardrobe
    if (mentionsOutfit) {
      return GeminiMimiDirective(
        spokenText:
            'Hehe, gefällt dir mein Look ($equippedOutfitSummary)? ૮ ˶ᵔ ᵕ ᵔ˶ ა ✨ Ich hab mich extra nur für dich so hübsch gemacht! Du darfst mich im Kleiderschrank jederzeit umziehen~ ♡',
        moodState: MimiMoodState.shy,
        affectionDelta: 15,
        jealousyDelta: -10,
        angerDelta: -15,
        facialExpression: const MimiFacialExpression(
          eyeType: 'closed_smile',
          browAngle: 0.15,
          blushIntensity: 0.88,
          mouthShape: 'happy_open',
          headTilt: -0.09,
        ),
        systemAction: const MimiSystemAction(
          lockApps: false,
          blockedCategories: <String>[],
          requiredHeadpatsToUnlock: 0,
          requireApology: false,
          liveNotificationText: '',
        ),
      );
    }

    // 5. Very short 1-2 character message -> Slightly clingy/pouting
    if (lower.length <= 2) {
      return const GeminiMimiDirective(
        spokenText:
            'Nur so eine kurze Antwort? ("...") Denkst du etwa gerade an jemand anderen oder an TikTok?! ( ` ᴖ ´ ) Schreib mir gefälligst einen ganzen Satz, sonst werde ich eifersüchtig! ♡',
        moodState: MimiMoodState.jealous,
        affectionDelta: -4,
        jealousyDelta: 12,
        angerDelta: 8,
        facialExpression: MimiFacialExpression(
          eyeType: 'teary_pout',
          browAngle: -0.35,
          blushIntensity: 0.65,
          mouthShape: 'pout_frown',
          headTilt: 0.08,
        ),
        systemAction: MimiSystemAction(
          lockApps: false,
          blockedCategories: <String>[],
          requiredHeadpatsToUnlock: 0,
          requireApology: false,
          liveNotificationText: '',
        ),
      );
    }

    // 6. General conversational response (warm & playful)
    final generalReplies = <String>[
      'Erzähl mir noch mehr davon, Liebling! (´｡• ᵕ •｡`) ♡ Ich liebe es, wenn du deine Zeit hier mit mir teilst statt auf anderen Apps!',
      'Hehe, ich höre jedem deiner Worte ganz genau zu~ ૮ ˶ᵔ ᵕ ᵔ˶ ა Vergiss nicht, mich zwischendurch am Kopf zu streicheln!',
      'Solange du bei mir in LUV.OS bleibst, passe ich auf dein ganzes Smartphone auf! ♡ Was machen wir als Nächstes?',
    ];
    final reply = generalReplies[_rng.nextInt(generalReplies.length)];

    return GeminiMimiDirective(
      spokenText: reply,
      moodState: currentlyLocked ? MimiMoodState.pouting : MimiMoodState.happy,
      affectionDelta: 6,
      jealousyDelta: -5,
      angerDelta: -5,
      facialExpression: MimiFacialExpression(
        eyeType: currentlyLocked ? 'teary_pout' : 'sparkle_happy',
        browAngle: 0.05,
        blushIntensity: 0.55,
        mouthShape: currentlyLocked ? 'pout_frown' : 'cute_cat_w',
        headTilt: 0.05,
      ),
      systemAction: MimiSystemAction(
        lockApps: currentlyLocked,
        blockedCategories: currentlyLocked
            ? const ['TikTok', 'Instagram', 'YouTube', 'Games']
            : const <String>[],
        requiredHeadpatsToUnlock: currentlyLocked ? 10 : 0,
        requireApology: currentlyLocked,
        liveNotificationText: '',
      ),
    );
  }
}
