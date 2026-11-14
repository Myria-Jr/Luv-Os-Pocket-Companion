import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a real-time phoneme & lip-sync frame emitted by the synthesizer
/// whenever Mimi speaks a character.
enum MimiVowelShape {
  closed,
  vowelA, // wide open 'A'
  vowelE, // wide smile 'E'
  vowelI, // narrow 'I'
  vowelO, // round 'O'
  vowelU, // pursed 'U'
}

@immutable
class VoiceBleepFrame {
  final String character;
  final MimiVowelShape vowelShape;
  final double mouthOpenness; // 0.0 - 1.0
  final double doublemouthWidthFactor; // 0.7 - 1.3
  final double instantaneousFreqHz;
  final Uint8List wavBytes;

  const VoiceBleepFrame({
    required this.character,
    required this.vowelShape,
    required this.mouthOpenness,
    required this.doublemouthWidthFactor,
    required this.instantaneousFreqHz,
    required this.wavBytes,
  });
}

final proceduralAudioSynthProvider = Provider<ProceduralAudioSynth>((ref) {
  final synth = ProceduralAudioSynth();
  ref.onDispose(synth.dispose);
  return synth;
});

/// Real-Time Procedural PCM/WAV Audio Synthesizer in pure Dart (Zero External Assets).
///
/// Synthesizes 16-bit mono PCM `.wav` byte streams in RAM with RIFF/WAVE headers:
/// - **Mimi Voice Bleeps**: Sine/Square hybrid waveforms with vowel formant pitching
///   (inspired by Undertale / Animal Crossing dialogue bleeps).
/// - **Dynamic Detuning**: Pitch drift, bitcrushing, FM ring modulation, and
///   sub-bass heartbeat synthesis controlled by `corruptionLevel` and `mania`.
/// - **UI Sound Effects**: Click, Heart-Pop, Error-Glitch, Terminal-Beep, and
///   Incoming Call Ringtone bursts.
class ProceduralAudioSynth {
  static const int sampleRate = 22050;

  final StreamController<VoiceBleepFrame> _voiceFrameController =
      StreamController<VoiceBleepFrame>.broadcast();

  final math.Random _rng = math.Random();
  bool _isDisposed = false;
  bool _isMuted = false;

  /// Holds the most recently synthesized normalized PCM samples (-1.0..1.0)
  /// for real-time oscilloscope / waveform visualization.
  List<double> _lastWaveformPreview = const <double>[];

  Stream<VoiceBleepFrame> get voiceFrameStream => _voiceFrameController.stream;
  List<double> get lastWaveformPreview => _lastWaveformPreview;
  bool get isMuted => _isMuted;

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// Classifies a single character into a vowel mouth shape (`A/E/I/O/U`)
  /// for procedural Lip-Sync and formant pitch shifting.
  MimiVowelShape classifyVowelShape(String ch) {
    if (ch.isEmpty) return MimiVowelShape.closed;
    final lower = ch.toLowerCase();
    if ('aäàáâ'.contains(lower)) return MimiVowelShape.vowelA;
    if ('eéèê'.contains(lower)) return MimiVowelShape.vowelE;
    if ('iïíìy'.contains(lower)) return MimiVowelShape.vowelI;
    if ('oöóòô'.contains(lower)) return MimiVowelShape.vowelO;
    if ('uüúùûw'.contains(lower)) return MimiVowelShape.vowelU;
    if ('.,!?:;…- '.contains(lower)) return MimiVowelShape.closed;
    // Consonants map to partial mouth openings based on codeUnit
    final bucket = lower.codeUnitAt(0) % 5;
    switch (bucket) {
      case 0:
        return MimiVowelShape.vowelE;
      case 1:
        return MimiVowelShape.vowelI;
      case 2:
        return MimiVowelShape.vowelA;
      case 3:
        return MimiVowelShape.vowelO;
      default:
        return MimiVowelShape.vowelU;
    }
  }

  /// Synthesizes a single character voice bleep for Mimi and broadcasts a
  /// [VoiceBleepFrame] for synchronous Lip-Sync on the 2.5D avatar rig.
  Uint8List synthesizeCharacterBleep(
    String char, {
    required double corruption,
    double mania = 0.1,
  }) {
    final shape = classifyVowelShape(char);
    if (shape == MimiVowelShape.closed) {
      final silentWav = _encodeMonoPcm16ToWav(Int16List(220));
      if (!_isDisposed) {
        _voiceFrameController.add(
          VoiceBleepFrame(
            character: char,
            vowelShape: MimiVowelShape.closed,
            mouthOpenness: 0.04,
            doublemouthWidthFactor: 1.0,
            instantaneousFreqHz: 0.0,
            wavBytes: silentWav,
          ),
        );
      }
      return silentWav;
    }

    // Base frequency in Hz: Phase 1 is bright & cute (640-820 Hz);
    // Phase 3-4 detunes downward with erratic FM ring-modulation.
    double baseFreq;
    double openness;
    double widthFactor;
    switch (shape) {
      case MimiVowelShape.vowelA:
        baseFreq = 720.0;
        openness = 0.92;
        widthFactor = 1.05;
        break;
      case MimiVowelShape.vowelE:
        baseFreq = 790.0;
        openness = 0.65;
        widthFactor = 1.24;
        break;
      case MimiVowelShape.vowelI:
        baseFreq = 850.0;
        openness = 0.42;
        widthFactor = 1.28;
        break;
      case MimiVowelShape.vowelO:
        baseFreq = 640.0;
        openness = 0.84;
        widthFactor = 0.76;
        break;
      case MimiVowelShape.vowelU:
        baseFreq = 590.0;
        openness = 0.52;
        widthFactor = 0.70;
        break;
      case MimiVowelShape.closed:
        baseFreq = 0.0;
        openness = 0.05;
        widthFactor = 1.0;
        break;
    }

    final c = corruption.clamp(0.0, 1.0);
    final m = mania.clamp(0.0, 1.0);

    // Dynamic detuning: lower pitch & add micro-semitone jitter as corruption grows
    final detuneFactor = 1.0 - (c * 0.28) + ((_rng.nextDouble() - 0.5) * 0.14 * (c + m));
    final freq = (baseFreq * detuneFactor).clamp(180.0, 1300.0);

    const durationSec = 0.048; // 48ms crisp voice bleep
    final numSamples = (sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);
    final preview = <double>[];

    // Bitcrushing quantization levels (smooth 32767 in Phase 1 -> gritty 6 levels in Phase 4)
    final crushSteps = c > 0.45 ? (32.0 - c * 26.0).clamp(4.0, 32.0) : 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = _adsrEnvelope(i / numSamples, attack: 0.12, release: 0.35);

      // FM vibrato + ring modulation when corrupted
      final fmMod = math.sin(2.0 * math.pi * (18.0 + m * 35.0) * t) * (c * 45.0);
      final phase = 2.0 * math.pi * (freq + fmMod) * t;

      // Blend pure sweet sine wave (Phase 1) with harmonic square wave (Phase 3/4)
      final sine = math.sin(phase);
      final square = sine >= 0.0 ? 0.8 : -0.8;
      var sample = sine * (1.0 - c * 0.55) + square * (c * 0.55);

      // Ring modulator tremor in Phase 3 & 4
      if (c >= 0.50) {
        final ringMod = math.sin(2.0 * math.pi * 64.0 * t);
        sample = sample * (1.0 - (c - 0.4) * 0.65) + (sample * ringMod) * ((c - 0.4) * 0.65);
      }

      // Sub-bass heartbeat undertone in Phase 3 & 4
      if (c >= 0.55) {
        sample += math.sin(2.0 * math.pi * 54.0 * t) * 0.32 * c;
      }

      sample = (sample * env).clamp(-1.0, 1.0);

      // Apply bitcrushing if active
      if (crushSteps > 0) {
        sample = (sample * crushSteps).round() / crushSteps;
      }

      if (i % 12 == 0) {
        preview.add(sample);
      }
      pcm[i] = (sample * 28000).round().clamp(-32768, 32767);
    }

    _lastWaveformPreview = preview;
    final wavBytes = _encodeMonoPcm16ToWav(pcm);

    if (!_isDisposed) {
      _voiceFrameController.add(
        VoiceBleepFrame(
          character: char,
          vowelShape: shape,
          mouthOpenness: openness,
          doublemouthWidthFactor: widthFactor,
          instantaneousFreqHz: freq,
          wavBytes: wavBytes,
        ),
      );
    }

    _dispatchTactileAudioPulse(corruption: c, isGlitch: c > 0.72 && _rng.nextDouble() < 0.25);
    return wavBytes;
  }

  /// Streams a full sentence character-by-character so Mimi's mouth and voice
  /// bleeps animate synchronously across the string.
  Future<void> playSpeechSentence(
    String text, {
    required double corruption,
    double mania = 0.1,
  }) async {
    if (_isDisposed || text.isEmpty) return;
    final maxChars = math.min(text.length, 42);
    for (var i = 0; i < maxChars; i++) {
      if (_isDisposed) return;
      final ch = text[i];
      synthesizeCharacterBleep(ch, corruption: corruption, mania: mania);
      await Future<void>.delayed(const Duration(milliseconds: 34));
    }
    // Close mouth at the end of the utterance
    if (!_isDisposed) {
      _voiceFrameController.add(
        VoiceBleepFrame(
          character: '',
          vowelShape: MimiVowelShape.closed,
          mouthOpenness: 0.0,
          doublemouthWidthFactor: 1.0,
          instantaneousFreqHz: 0.0,
          wavBytes: _encodeMonoPcm16ToWav(Int16List(64)),
        ),
      );
    }
  }

  /// Procedurally generates a cute pastel UI click or heart-pop WAV sound.
  Uint8List playCuteHeartPop({double corruption = 0.1}) {
    const durationSec = 0.075;
    final numSamples = (sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = i / numSamples;
      // Upward pitch chirp from 520 Hz to 1040 Hz
      final freq = (520.0 + progress * 560.0) * (1.0 - corruption * 0.22);
      final env = _adsrEnvelope(progress, attack: 0.08, release: 0.5);
      final sample = math.sin(2.0 * math.pi * freq * t) * env;
      pcm[i] = (sample * 26000).round().clamp(-32768, 32767);
    }

    _dispatchTactileAudioPulse(corruption: corruption, isGlitch: false);
    return _encodeMonoPcm16ToWav(pcm);
  }

  /// Procedurally generates a harsh digital glitch/error burst WAV sound.
  Uint8List playErrorGlitchBurst({double corruption = 0.8}) {
    const durationSec = 0.14;
    final numSamples = (sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = i / numSamples;
      final env = _adsrEnvelope(progress, attack: 0.03, release: 0.25);
      final carrier = math.sin(2.0 * math.pi * 195.0 * t);
      final noise = (_rng.nextDouble() * 2.0 - 1.0) * 0.55;
      final bitcrushed = ((carrier + noise) * 4.0).round() / 4.0;
      pcm[i] = (bitcrushed * env * 30000).round().clamp(-32768, 32767);
    }

    _dispatchTactileAudioPulse(corruption: corruption, isGlitch: true);
    return _encodeMonoPcm16ToWav(pcm);
  }

  /// Procedurally generates a retro terminal beep WAV sound.
  Uint8List playTerminalBeep({bool isSuccess = true}) {
    const durationSec = 0.06;
    final numSamples = (sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);
    final freq = isSuccess ? 980.0 : 240.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sq = math.sin(2.0 * math.pi * freq * t) >= 0 ? 0.7 : -0.7;
      final env = _adsrEnvelope(i / numSamples, attack: 0.05, release: 0.3);
      pcm[i] = (sq * env * 24000).round().clamp(-32768, 32767);
    }

    _dispatchTactileAudioPulse(corruption: isSuccess ? 0.1 : 0.7, isGlitch: !isSuccess);
    return _encodeMonoPcm16ToWav(pcm);
  }

  /// Procedurally generates a dual-tone Yandere FaceTime ringtone pulse WAV.
  Uint8List playIncomingCallRingtonePulse({double corruption = 0.75}) {
    const durationSec = 0.22;
    final numSamples = (sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = i / numSamples;
      final f1 = progress < 0.5 ? 659.25 : 880.0; // E5 -> A5 interval
      final detune = math.sin(2.0 * math.pi * 12.0 * t) * (corruption * 22.0);
      final tone = math.sin(2.0 * math.pi * (f1 + detune) * t);
      final subBeat = math.sin(2.0 * math.pi * 55.0 * t) * 0.35 * corruption;
      final env = _adsrEnvelope(progress, attack: 0.08, release: 0.25);
      pcm[i] = ((tone * 0.7 + subBeat) * env * 28000).round().clamp(-32768, 32767);
    }

    _dispatchTactileAudioPulse(corruption: corruption, isGlitch: true);
    return _encodeMonoPcm16ToWav(pcm);
  }

  double _adsrEnvelope(
    double normalizedPos, {
    required double attack,
    required double release,
  }) {
    if (normalizedPos < attack) {
      return (normalizedPos / attack).clamp(0.0, 1.0);
    }
    if (normalizedPos > 1.0 - release) {
      return ((1.0 - normalizedPos) / release).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  void _dispatchTactileAudioPulse({
    required double corruption,
    required bool isGlitch,
  }) {
    if (_isMuted) return;
    try {
      SystemSound.play(SystemSoundType.click);
      if (isGlitch) {
        HapticFeedback.heavyImpact();
      } else if (corruption > 0.45) {
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      // Ignore in headless test runners
    }
  }

  /// Wraps raw 16-bit signed mono PCM samples into a complete RIFF/WAVE binary stream.
  Uint8List _encodeMonoPcm16ToWav(Int16List samples) {
    final dataByteLength = samples.length * 2;
    final totalFileLength = 44 + dataByteLength;
    final byteData = ByteData(totalFileLength);

    // "RIFF" chunk descriptor
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, totalFileLength - 8, Endian.little);

    // "WAVE" format
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // "fmt " subchunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little); // NumChannels (1 = mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // "data" subchunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataByteLength, Endian.little);

    var offset = 44;
    for (var i = 0; i < samples.length; i++) {
      byteData.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  void dispose() {
    _isDisposed = true;
    _voiceFrameController.close();
  }
}
