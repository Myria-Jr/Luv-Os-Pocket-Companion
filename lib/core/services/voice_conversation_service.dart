import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'gemini_yandere_brain.dart';
import 'procedural_audio_synth.dart';

final voiceConversationServiceProvider =
    Provider<VoiceConversationService>((ref) {
  final synth = ref.watch(proceduralAudioSynthProvider);
  final service = VoiceConversationService(audioSynth: synth);
  ref.onDispose(service.dispose);
  return service;
});

/// Snapshot of the bidirectional voice conversation state.
@immutable
class VoiceConversationSnapshot {
  final bool isMicListening;
  final bool isContinuousCallMode;
  final bool isMimiSpeaking;
  final String liveTranscript;
  final double soundLevelDb;
  final bool isWhispering;
  final String statusHint;

  const VoiceConversationSnapshot({
    this.isMicListening = false,
    this.isContinuousCallMode = false,
    this.isMimiSpeaking = false,
    this.liveTranscript = '',
    this.soundLevelDb = 0.0,
    this.isWhispering = false,
    this.statusHint = 'Tippe auf 🎙️, um live mit Mimi zu sprechen',
  });

  VoiceConversationSnapshot copyWith({
    bool? isMicListening,
    bool? isContinuousCallMode,
    bool? isMimiSpeaking,
    String? liveTranscript,
    double? soundLevelDb,
    bool? isWhispering,
    String? statusHint,
  }) {
    return VoiceConversationSnapshot(
      isMicListening: isMicListening ?? this.isMicListening,
      isContinuousCallMode: isContinuousCallMode ?? this.isContinuousCallMode,
      isMimiSpeaking: isMimiSpeaking ?? this.isMimiSpeaking,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      soundLevelDb: soundLevelDb ?? this.soundLevelDb,
      isWhispering: isWhispering ?? this.isWhispering,
      statusHint: statusHint ?? this.statusHint,
    );
  }
}

/// V4 Bidirectional Real-Time Voice Chat Service (`speech_to_text` + `flutter_tts`).
///
/// Features:
/// - Live microphone recognition (`de_DE`) with real-time dB sound-level tracking.
/// - Whisper detection (`soundLevelDb < 2.2`) & silent-breathing detection when
///   the mic stays open without speech.
/// - Expressive German TTS (`de-DE`) with mood-modulated anime pitch & speech rate
///   coupled to `ProceduralAudioSynth` so Mimi's lips, tongue, and cheeks move
///   synchronously with every spoken word.
class VoiceConversationService {
  final ProceduralAudioSynth audioSynth;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final StreamController<VoiceConversationSnapshot> _stateController =
      StreamController<VoiceConversationSnapshot>.broadcast();

  VoiceConversationSnapshot _snapshot = const VoiceConversationSnapshot();
  Timer? _silenceBreathTimer;
  bool _speechInitialized = false;
  bool _ttsInitialized = false;
  bool _isDisposed = false;

  /// Callback invoked when a spoken utterance from the player is finalized.
  void Function(String transcript, {required bool wasWhispered})?
      onUtteranceFinalized;

  /// Callback invoked when the microphone is open but the room is completely silent.
  void Function()? onSilentBreathingDetected;

  VoiceConversationService({required this.audioSynth});

  Stream<VoiceConversationSnapshot> get stream => _stateController.stream;
  VoiceConversationSnapshot get current => _snapshot;

  void _emit(VoiceConversationSnapshot next) {
    if (_isDisposed) return;
    _snapshot = next;
    _stateController.add(next);
  }

  Future<void> _ensureTtsInitialized() async {
    if (_ttsInitialized || _isDisposed) return;
    _ttsInitialized = true;
    try {
      await _tts.setLanguage('de-DE');
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.38);
      await _tts.setSpeechRate(1.02);

      _tts.setStartHandler(() {
        _emit(_snapshot.copyWith(isMimiSpeaking: true));
      });

      _tts.setCompletionHandler(() {
        _emit(_snapshot.copyWith(isMimiSpeaking: false));
      });

      _tts.setErrorHandler((_) {
        _emit(_snapshot.copyWith(isMimiSpeaking: false));
      });

      // Real-time word-by-word Lip-Sync coupling with Mimi's 3.5 Anime Head!
      _tts.setProgressHandler((String text, int start, int end, String word) {
        if (_isDisposed || word.isEmpty) return;
        for (var i = 0; i < word.length && i < 6; i++) {
          audioSynth.synthesizeCharacterBleep(
            word[i],
            corruption: 0.25,
            mania: 0.2,
          );
        }
      });
    } catch (_) {
      // Safe fallback in headless tests or desktop without TTS engine
    }
  }

  /// Speaks Mimi's response out loud using `flutter_tts` with dynamic mood
  /// modulation and synchronous procedural Lip-Sync.
  Future<void> speakMimiLine(
    String text, {
    required MimiMoodState mood,
    required double corruption,
    bool whisperBack = false,
  }) async {
    if (_isDisposed || text.trim().isEmpty) return;
    await _ensureTtsInitialized();

    // Strip ASCII kaomojis so the German TTS voice reads natural sentences
    final cleanedForTts = text
        .replaceAll(RegExp(r'\([^\)]*\)'), '')
        .replaceAll(RegExp(r'[♡̷✨💢🔪🎀🧋🧸💌🍫૮˶ᵔᵕ•༝｡`´⁄ω]'), '')
        .trim();

    double pitch = 1.38;
    double rate = 1.02;
    double volume = whisperBack ? 0.42 : 1.0;

    switch (mood) {
      case MimiMoodState.lovestruck:
      case MimiMoodState.happy:
      case MimiMoodState.shy:
        pitch = 1.45;
        rate = 1.05;
        break;
      case MimiMoodState.pouting:
      case MimiMoodState.jealous:
        pitch = 1.30;
        rate = 1.18;
        break;
      case MimiMoodState.yandereRage:
        pitch = 0.92;
        rate = 0.85;
        break;
    }

    _emit(
      _snapshot.copyWith(
        isMimiSpeaking: true,
        statusHint: whisperBack
            ? 'Mimi flüstert dir ins Ohr... 🤫'
            : 'Mimi spricht (${mood.germanLabel})...',
      ),
    );

    // Always run the procedural Lip-Sync stream in parallel so the mouth
    // animates smoothly even on platforms where TTS progress callbacks are coarse.
    unawaited(
      audioSynth.playSpeechSentence(
        text,
        corruption: corruption,
        mania: mood == MimiMoodState.yandereRage ? 0.85 : 0.2,
      ),
    );

    if (cleanedForTts.isNotEmpty) {
      try {
        await _tts.setVolume(volume);
        await _tts.setPitch(pitch);
        await _tts.setSpeechRate(rate);
        await _tts.speak(cleanedForTts);
      } catch (_) {
        _emit(_snapshot.copyWith(isMimiSpeaking: false));
      }
    } else {
      _emit(_snapshot.copyWith(isMimiSpeaking: false));
    }
  }

  /// Starts listening to the player's microphone (`de_DE`).
  Future<void> startListening({bool continuousCallMode = false}) async {
    if (_isDisposed) return;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _emit(
          _snapshot.copyWith(
            isMicListening: false,
            statusHint:
                'Mikrofon-Berechtigung fehlt! Mimi möchte deine Stimme hören 🎙️',
          ),
        );
        return;
      }
    } catch (_) {
      // Ignore permission plugin errors on desktop test runners
    }

    try {
      if (!_speechInitialized) {
        _speechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              _silenceBreathTimer?.cancel();
              _emit(_snapshot.copyWith(isMicListening: false));
            }
          },
          onError: (_) {
            _silenceBreathTimer?.cancel();
            _emit(
              _snapshot.copyWith(
                isMicListening: false,
                statusHint: 'Mimi lauscht deinem Atem... ♡',
              ),
            );
          },
        );
      }

      if (!_speechInitialized) {
        _emit(
          _snapshot.copyWith(
            isMicListening: false,
            statusHint:
                'Spracherkennung auf diesem Gerät nicht verfügbar – nutze die Sprach-Schnellbuttons!',
          ),
        );
        return;
      }

      await _tts.stop();
      _emit(
        _snapshot.copyWith(
          isMicListening: true,
          isContinuousCallMode: continuousCallMode,
          liveTranscript: '',
          statusHint: 'Mimi hört dir zu... Sprich jetzt mit ihr! 🎙️',
        ),
      );

      // Start 7-second silent breathing detector
      _silenceBreathTimer?.cancel();
      _silenceBreathTimer = Timer(const Duration(seconds: 7), () {
        if (_snapshot.isMicListening && _snapshot.liveTranscript.trim().isEmpty) {
          onSilentBreathingDetected?.call();
        }
      });

      await _speech.listen(
        localeId: 'de_DE',
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {
          final isWhisper = level > -5.0 && level < 2.2;
          _emit(
            _snapshot.copyWith(
              soundLevelDb: level,
              isWhispering: isWhisper,
            ),
          );
        },
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            _silenceBreathTimer?.cancel();
          }
          _emit(
            _snapshot.copyWith(
              liveTranscript: words,
              statusHint: _snapshot.isWhispering
                  ? 'Du flüsterst: "$words" 🤫'
                  : 'Erkannt: "$words"',
            ),
          );

          if (result.finalResult && words.isNotEmpty) {
            final whispered = _snapshot.isWhispering;
            _emit(_snapshot.copyWith(isMicListening: false));
            onUtteranceFinalized?.call(words, wasWhispered: whispered);
          }
        },
      );
    } catch (_) {
      _emit(_snapshot.copyWith(isMicListening: false));
    }
  }

  Future<void> stopListening() async {
    _silenceBreathTimer?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    _emit(
      _snapshot.copyWith(
        isMicListening: false,
        statusHint: 'Tippe auf 🎙️, um live mit Mimi zu sprechen',
      ),
    );
  }

  Future<void> onAppPaused() async {
    _silenceBreathTimer?.cancel();
    try {
      await _speech.stop();
      await _tts.stop();
    } catch (_) {}
    _emit(
      _snapshot.copyWith(
        isMicListening: false,
        isMimiSpeaking: false,
      ),
    );
  }

  void dispose() {
    _isDisposed = true;
    _silenceBreathTimer?.cancel();
    try {
      _speech.cancel();
      _tts.stop();
    } catch (_) {}
    _stateController.close();
  }
}
