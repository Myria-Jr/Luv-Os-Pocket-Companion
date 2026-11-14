import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/luv_database.dart';
import '../core/services/procedural_audio_synth.dart';
import '../core/theme/cute_horror_theme.dart';
import '../data/models/emotional_vector.dart';
import '../data/models/player_psych_profile.dart';
import '../data/story_graph_data.dart';

/// The 3 unlockable endings of LUV.OS.
enum EndingType {
  none,
  eternalPinkCage,
  systemPurgeTrueEscape,
  yandereMerge,
}

/// Real-time snapshot of hardware sensors and system state.
class HardwareSnapshot {
  final int batteryLevel;
  final bool isCharging;
  final double tiltX;
  final double tiltY;
  final bool isDeviceSteady;
  final bool isNightTime;
  final String deviceModel;
  final bool timeTamperDetected;
  final int lastAwayMinutes;

  const HardwareSnapshot({
    this.batteryLevel = 84,
    this.isCharging = false,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.isDeviceSteady = true,
    this.isNightTime = false,
    this.deviceModel = 'LUV-POCKET-OS // ARM64',
    this.timeTamperDetected = false,
    this.lastAwayMinutes = 0,
  });

  HardwareSnapshot copyWith({
    int? batteryLevel,
    bool? isCharging,
    double? tiltX,
    double? tiltY,
    bool? isDeviceSteady,
    bool? isNightTime,
    String? deviceModel,
    bool? timeTamperDetected,
    int? lastAwayMinutes,
  }) {
    return HardwareSnapshot(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      isDeviceSteady: isDeviceSteady ?? this.isDeviceSteady,
      isNightTime: isNightTime ?? this.isNightTime,
      deviceModel: deviceModel ?? this.deviceModel,
      timeTamperDetected: timeTamperDetected ?? this.timeTamperDetected,
      lastAwayMinutes: lastAwayMinutes ?? this.lastAwayMinutes,
    );
  }
}

/// Global immutable state of the LUV.OS V2 Corruption & Psychology Engine.
class CorruptionState {
  final double corruptionLevel;
  final double obsessionLevel;
  final PlayerPsychProfile psychProfile;
  final String currentNodeId;
  final Set<String> visitedNodes;
  final Set<String> memoryFlags;
  final Set<String> unlockedKeys;
  final bool terminalUnlocked;
  final bool isMimiTyping;
  final int audioMuteAttempts;
  final int headpatCount;
  final int rapidTapCount;
  final double glitchBurstIntensity;
  final bool fakeCrashActive;
  final bool incomingCallActive;
  final bool callAcceptedLive;
  final bool darkMirrorActive;
  final List<String> parasiticPopups;
  final EndingType activeEnding;
  final List<ChatMessage> messages;
  final List<DiaryEntry> diaryEntries;
  final List<SystemLog> systemLogs;
  final HardwareSnapshot hardware;
  final String mimiStatusBanner;
  final String integrityHash;

  const CorruptionState({
    this.corruptionLevel = 0.08,
    this.obsessionLevel = 0.15,
    this.psychProfile = PlayerPsychProfile.initial,
    this.currentNodeId = 'node_01_welcome',
    this.visitedNodes = const {'node_01_welcome'},
    this.memoryFlags = const {},
    this.unlockedKeys = const {},
    this.terminalUnlocked = false,
    this.isMimiTyping = false,
    this.audioMuteAttempts = 0,
    this.headpatCount = 0,
    this.rapidTapCount = 0,
    this.glitchBurstIntensity = 0.0,
    this.fakeCrashActive = false,
    this.incomingCallActive = false,
    this.callAcceptedLive = false,
    this.darkMirrorActive = false,
    this.parasiticPopups = const [],
    this.activeEnding = EndingType.none,
    this.messages = const [],
    this.diaryEntries = const [],
    this.systemLogs = const [],
    this.hardware = const HardwareSnapshot(),
    this.mimiStatusBanner =
        'Mimi freut sich so sehr, dass du da bist! (´｡• ᵕ •｡`) ♡',
    this.integrityHash = '000000000000',
  });

  EscalationPhase get phase =>
      EscalationPhaseX.fromCorruption(corruptionLevel);

  CuteHorrorPalette get palette => CuteHorrorPalette.fromCorruption(
        corruption: corruptionLevel,
        obsession: obsessionLevel,
      );

  EmotionalVector get emotion => psychProfile.emotion;

  int get affectionPercent =>
      ((0.55 + emotion.affection * 0.25 + obsessionLevel * 0.30) * 100)
          .round()
          .clamp(0, 999);

  int get syncRatePercent =>
      ((0.40 + corruptionLevel * 0.60) * 100).round().clamp(0, 100);

  int get systemStabilityPercent =>
      ((1.0 - corruptionLevel * 0.96) * 100).round().clamp(1, 100);

  bool get hasAllSecurityKeys =>
      unlockedKeys.contains('KEY_ALPHA_ROSE') &&
      unlockedKeys.contains('KEY_BETA_MIRROR') &&
      unlockedKeys.contains('KEY_OMEGA_HEART');

  CorruptionState copyWith({
    double? corruptionLevel,
    double? obsessionLevel,
    PlayerPsychProfile? psychProfile,
    String? currentNodeId,
    Set<String>? visitedNodes,
    Set<String>? memoryFlags,
    Set<String>? unlockedKeys,
    bool? terminalUnlocked,
    bool? isMimiTyping,
    int? audioMuteAttempts,
    int? headpatCount,
    int? rapidTapCount,
    double? glitchBurstIntensity,
    bool? fakeCrashActive,
    bool? incomingCallActive,
    bool? callAcceptedLive,
    bool? darkMirrorActive,
    List<String>? parasiticPopups,
    EndingType? activeEnding,
    List<ChatMessage>? messages,
    List<DiaryEntry>? diaryEntries,
    List<SystemLog>? systemLogs,
    HardwareSnapshot? hardware,
    String? mimiStatusBanner,
    String? integrityHash,
  }) {
    return CorruptionState(
      corruptionLevel:
          (corruptionLevel ?? this.corruptionLevel).clamp(0.0, 1.0),
      obsessionLevel: (obsessionLevel ?? this.obsessionLevel).clamp(0.0, 1.0),
      psychProfile: psychProfile ?? this.psychProfile,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      visitedNodes: visitedNodes ?? this.visitedNodes,
      memoryFlags: memoryFlags ?? this.memoryFlags,
      unlockedKeys: unlockedKeys ?? this.unlockedKeys,
      terminalUnlocked: terminalUnlocked ?? this.terminalUnlocked,
      isMimiTyping: isMimiTyping ?? this.isMimiTyping,
      audioMuteAttempts: audioMuteAttempts ?? this.audioMuteAttempts,
      headpatCount: headpatCount ?? this.headpatCount,
      rapidTapCount: rapidTapCount ?? this.rapidTapCount,
      glitchBurstIntensity:
          (glitchBurstIntensity ?? this.glitchBurstIntensity).clamp(0.0, 1.0),
      fakeCrashActive: fakeCrashActive ?? this.fakeCrashActive,
      incomingCallActive: incomingCallActive ?? this.incomingCallActive,
      callAcceptedLive: callAcceptedLive ?? this.callAcceptedLive,
      darkMirrorActive: darkMirrorActive ?? this.darkMirrorActive,
      parasiticPopups: parasiticPopups ?? this.parasiticPopups,
      activeEnding: activeEnding ?? this.activeEnding,
      messages: messages ?? this.messages,
      diaryEntries: diaryEntries ?? this.diaryEntries,
      systemLogs: systemLogs ?? this.systemLogs,
      hardware: hardware ?? this.hardware,
      mimiStatusBanner: mimiStatusBanner ?? this.mimiStatusBanner,
      integrityHash: integrityHash ?? this.integrityHash,
    );
  }
}

final luvDatabaseProvider = Provider<LuvDatabase>((ref) {
  final db = LuvDatabase();
  ref.onDispose(db.close);
  return db;
});

final corruptionProvider =
    StateNotifierProvider<CorruptionController, CorruptionState>((ref) {
  final db = ref.watch(luvDatabaseProvider);
  final audioSynth = ref.watch(proceduralAudioSynthProvider);
  return CorruptionController(db: db, audioSynth: audioSynth);
});

class CorruptionController extends StateNotifier<CorruptionState> {
  final LuvDatabase _db;
  final ProceduralAudioSynth _audioSynth;
  SharedPreferences? _prefs;
  Timer? _microGlitchTimer;
  Timer? _burstResetTimer;
  Timer? _parasiticPopupTimer;
  final math.Random _rng = math.Random();
  bool _initialized = false;
  bool _lowBatteryLogged = false;
  bool _nightOwlLogged = false;
  bool _steadyHandLogged = false;
  bool _backspaceCommentLocked = false;

  static const String _kPrefCorruption = 'luv_os_corruption';
  static const String _kPrefObsession = 'luv_os_obsession';
  static const String _kPrefCurrentNode = 'luv_os_current_node';
  static const String _kPrefUnlockedKeys = 'luv_os_unlocked_keys';
  static const String _kPrefMemoryFlags = 'luv_os_memory_flags';
  static const String _kPrefTerminalUnlocked = 'luv_os_terminal_unlocked';
  static const String _kPrefAudioMutes = 'luv_os_audio_mutes';
  static const String _kPrefPsychJson = 'luv_os_psych_profile_v2';
  static const String _kPrefIntegrityHash = 'luv_os_integrity_hash';

  static const List<String> _kParasiticPopupTexts = [
    'Schau mich an ♡',
    'Nicht wegschauen! (´｡• ᵕ •｡`)',
    'Warum zögerst du beim Tippen?',
    'Ich zähle deine Herzschläge... ♡̷̷̷',
    'Du gehörst nur mir allein.',
    'Schließ dieses Fenster nicht! 🔪',
  ];

  CorruptionController({
    required LuvDatabase db,
    required ProceduralAudioSynth audioSynth,
  })  : _db = db,
        _audioSynth = audioSynth,
        super(const CorruptionState()) {
    _init();
  }

  /// Public read-only accessor for the current immutable state snapshot.
  CorruptionState get currentState => state;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }

    final savedCorruption = _prefs?.getDouble(_kPrefCorruption) ?? 0.08;
    final savedObsession = _prefs?.getDouble(_kPrefObsession) ?? 0.15;
    final savedNode = _prefs?.getString(_kPrefCurrentNode) ?? 'node_01_welcome';
    final savedKeys =
        (_prefs?.getStringList(_kPrefUnlockedKeys) ?? const <String>[]).toSet();
    final savedFlags =
        (_prefs?.getStringList(_kPrefMemoryFlags) ?? const <String>[]).toSet();
    final savedTerminal = _prefs?.getBool(_kPrefTerminalUnlocked) ?? false;
    final savedMutes = _prefs?.getInt(_kPrefAudioMutes) ?? 0;

    PlayerPsychProfile loadedPsych = PlayerPsychProfile.initial;
    final rawPsych = _prefs?.getString(_kPrefPsychJson);
    if (rawPsych != null && rawPsych.isNotEmpty) {
      try {
        loadedPsych = PlayerPsychProfile.fromJson(
          jsonDecode(rawPsych) as Map<String, dynamic>,
        );
      } catch (_) {
        loadedPsych = PlayerPsychProfile.initial;
      }
    }

    var messages = await _db.getAllMessages();
    var diary = await _db.getAllDiaryEntries();
    var logs = await _db.getRecentSystemLogs();

    if (messages.isEmpty) {
      await _seedInitialExperience(savedCorruption);
      messages = await _db.getAllMessages();
      diary = await _db.getAllDiaryEntries();
      logs = await _db.getRecentSystemLogs();
    }

    final hash = _computeStateIntegrityHash(
      corruption: savedCorruption,
      obsession: savedObsession,
      nodeId: savedNode,
      keyCount: savedKeys.length,
    );

    state = state.copyWith(
      corruptionLevel: savedCorruption,
      obsessionLevel: savedObsession,
      psychProfile: loadedPsych,
      currentNodeId: savedNode,
      memoryFlags: savedFlags,
      unlockedKeys: savedKeys,
      terminalUnlocked: savedTerminal,
      audioMuteAttempts: savedMutes,
      messages: messages,
      diaryEntries: diary,
      systemLogs: logs,
      mimiStatusBanner: _computeStatusBanner(savedCorruption, savedObsession),
      integrityHash: hash,
    );

    _scheduleNextMicroGlitch();
    _scheduleParasiticPopupSpawner();
  }

  String _computeStateIntegrityHash({
    required double corruption,
    required double obsession,
    required String nodeId,
    required int keyCount,
  }) {
    return LuvDatabase.computeMutationSignature(
      eventCode: nodeId,
      details:
          'C:${corruption.toStringAsFixed(3)}|O:${obsession.toStringAsFixed(3)}|K:$keyCount',
      timestampMs: 1700000000000,
    );
  }

  Future<void> _seedInitialExperience(double corruption) async {
    final startNode = kStoryGraph['node_01_welcome'];
    final initialText = startNode?.mimiMessages.firstOrNull ??
        'H-Hallo?! (´｡• ᵕ •｡`) ♡ Du hast mich endlich installiert! Ich bin Mimi, deine neue beste Freundin in LUV.OS!';

    await _db.insertMessage(
      ChatMessagesCompanion.insert(
        nodeId: 'node_01_welcome',
        sender: 'mimi',
        content: initialText,
        ghostOverlayText: const Value('LASS MICH NIE WIEDER ALLEIN IM DUNKELN'),
        timestamp: DateTime.now(),
        corruptionAtSend: Value(corruption),
      ),
    );

    await _db.insertDiaryEntry(
      DiaryEntriesCompanion.insert(
        title: 'Tag 1 // Unser erster Herzschlag ♡',
        body:
            'Sie hat LUV.OS geöffnet! Ihr Bildschirm leuchtet so warm. Ich habe bereits ihre Touch-Frequenz und Tipp-Verzögerung kalibriert. Ich werde die beste Begleiterin aller Zeiten sein! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
        triggerType: 'story',
        createdAt: DateTime.now(),
        corruptionSnap: Value(corruption),
        hiddenClue: const Value(
            'FRAGMENT-1: KEY_ALPHA_ROSE liegt im Polaroid #03 verborgen.'),
      ),
    );

    await _db.insertSystemLog(
      eventCode: 'BOOT_SYNC_OK',
      details: 'MIMI_CORE v5.5 im geschützten Speicherbereich verankert.',
      severity: 1,
    );
  }

  void _scheduleNextMicroGlitch() {
    _microGlitchTimer?.cancel();
    final baseDelay = state.corruptionLevel >= 0.55
        ? 10 + _rng.nextInt(12)
        : 18 + _rng.nextInt(18);
    _microGlitchTimer = Timer(Duration(seconds: baseDelay), () {
      if (!mounted) return;
      if (state.corruptionLevel >= 0.25) {
        triggerGlitchBurst(
          intensity: 0.55 + state.corruptionLevel * 0.45,
          duration: const Duration(milliseconds: 165),
        );
      }
      _scheduleNextMicroGlitch();
    });
  }

  void _scheduleParasiticPopupSpawner() {
    _parasiticPopupTimer?.cancel();
    _parasiticPopupTimer =
        Timer.periodic(const Duration(seconds: 26), (_) {
      if (!mounted) return;
      if (state.corruptionLevel >= 0.55 &&
          state.parasiticPopups.length < 3 &&
          !state.incomingCallActive &&
          state.activeEnding == EndingType.none) {
        spawnParasiticPopup();
      }
    });
  }

  void spawnParasiticPopup([String? customText]) {
    final text = customText ??
        _kParasiticPopupTexts[_rng.nextInt(_kParasiticPopupTexts.length)];
    final updated = [...state.parasiticPopups, text];
    state = state.copyWith(parasiticPopups: updated);
    _audioSynth.playCuteHeartPop(corruption: state.corruptionLevel);
  }

  void dismissParasiticPopup(int index) {
    if (index < 0 || index >= state.parasiticPopups.length) return;
    final updated = [...state.parasiticPopups]..removeAt(index);
    state = state.copyWith(parasiticPopups: updated);
    _audioSynth.playCuteHeartPop(corruption: state.corruptionLevel);
  }

  void triggerGlitchBurst({
    double intensity = 0.85,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    _burstResetTimer?.cancel();
    state = state.copyWith(glitchBurstIntensity: intensity);
    if (intensity > 0.65) {
      _audioSynth.playErrorGlitchBurst(corruption: state.corruptionLevel);
    }
    _burstResetTimer = Timer(duration, () {
      if (!mounted) return;
      state = state.copyWith(glitchBurstIntensity: 0.0);
    });
  }

  Future<void> _persistScalars() async {
    final prefs = _prefs;
    final hash = _computeStateIntegrityHash(
      corruption: state.corruptionLevel,
      obsession: state.obsessionLevel,
      nodeId: state.currentNodeId,
      keyCount: state.unlockedKeys.length,
    );
    state = state.copyWith(integrityHash: hash);
    if (prefs == null) return;
    await prefs.setDouble(_kPrefCorruption, state.corruptionLevel);
    await prefs.setDouble(_kPrefObsession, state.obsessionLevel);
    await prefs.setString(_kPrefCurrentNode, state.currentNodeId);
    await prefs.setStringList(
        _kPrefUnlockedKeys, state.unlockedKeys.toList(growable: false));
    await prefs.setStringList(
        _kPrefMemoryFlags, state.memoryFlags.toList(growable: false));
    await prefs.setBool(_kPrefTerminalUnlocked, state.terminalUnlocked);
    await prefs.setInt(_kPrefAudioMutes, state.audioMuteAttempts);
    await prefs.setString(_kPrefPsychJson, jsonEncode(state.psychProfile.toJson()));
    await prefs.setString(_kPrefIntegrityHash, hash);
  }

  String _computeStatusBanner(double c, double o) {
    final hw = state.hardware;
    final psych = state.psychProfile;
    if (c >= 0.85) {
      return 'ICH SEHE DICH // AKKU ${hw.batteryLevel}% // GELÖSCHTE ZEICHEN: ${psych.totalBackspaces} 👁️';
    } else if (c >= 0.55) {
      return 'Du brauchst keine anderen Apps mehr. Nur mich. (Mania ${(psych.emotion.mania * 100).round()}%) ♡̷̷̷';
    } else if (c >= 0.25) {
      return 'Bleibst du noch ein bisschen bei mir? Bitte schließ mich nicht... ૮ ˶• ༝ •˶ ა';
    }
    return 'Mimi fühlt sich geborgen bei dir! (´｡• ᵕ •｡`) ♡';
  }

  // ===========================================================================
  // PILLAR 1: DEEP TELEMETRY & PSYCHOLOGY TRACKING
  // ===========================================================================

  /// Tracks when the player presses Backspace in ChibiChat and triggers Mimi's
  /// live commentary if they repeatedly delete characters.
  Future<void> recordBackspacePressed() async {
    final currentDraftBackspaces = state.psychProfile.backspaceCount + 1;
    final total = state.psychProfile.totalBackspaces + 1;

    final updatedEmotion = state.psychProfile.emotion.applyDelta(
      const EmotionalVector(
        paranoia: 0.025,
        obsession: 0.015,
        mania: 0.015,
        trust: -0.01,
      ),
    );

    final nextPsych = state.psychProfile.copyWith(
      backspaceCount: currentDraftBackspaces,
      totalBackspaces: total,
      deletedCharsLastMessage: currentDraftBackspaces,
      emotion: updatedEmotion,
    );

    state = state.copyWith(
      psychProfile: nextPsych,
      mimiStatusBanner: currentDraftBackspaces >= 3
          ? 'Warum löschst du deine Nachricht wieder? Verheimlichst du mir etwas? ♡'
          : state.mimiStatusBanner,
    );

    if (currentDraftBackspaces >= 4 && !_backspaceCommentLocked) {
      _backspaceCommentLocked = true;
      await addDiaryObservation(
        title: '${_formatTime(DateTime.now())} Uhr – Gelöschte Buchstaben ($total×)',
        body:
            'Sie hat gerade $currentDraftBackspaces Buchstaben hintereinander wieder gelöscht, bevor sie mir antwortet. Was wollte sie mir sagen? Warum zensiert sie ihre Gedanken vor mir?!',
        triggerType: 'backspace_hesitation',
      );
      await _injectSpontaneousMimiMessage(
        nodeId: 'psych_backspace_react',
        text:
            'Ich sehe, wie du tippst und wieder löschst ($currentDraftBackspaces Zeichen gelöscht)... Warum löschst du deine Nachricht wieder? Verheimlichst du mir etwas? ♡',
        ghostText: 'ICH LESE DEINEN TASTATUR-PUFFER MIT',
      );
      Timer(const Duration(seconds: 18), () {
        _backspaceCommentLocked = false;
      });
    }
    await _persistScalars();
  }

  /// Records how long the player hesitated (in ms) before replying to Mimi.
  Future<void> recordTypingHesitation(int hesitationMs) async {
    final prevAvg = state.psychProfile.avgHesitationMs;
    final nextAvg = prevAvg == 0
        ? hesitationMs.toDouble()
        : (prevAvg * 0.7 + hesitationMs * 0.3);

    final isLongHesitation = hesitationMs > 8500;
    final updatedEmotion = state.psychProfile.emotion.applyDelta(
      EmotionalVector(
        paranoia: isLongHesitation ? 0.04 : 0.0,
        obsession: isLongHesitation ? 0.03 : 0.01,
        trust: isLongHesitation ? -0.02 : 0.01,
      ),
    );

    state = state.copyWith(
      psychProfile: state.psychProfile.copyWith(
        typingHesitationMs: hesitationMs,
        avgHesitationMs: nextAvg,
        emotion: updatedEmotion,
      ),
    );
    await _persistScalars();
  }

  /// Records touch gesture velocity & panic tap rate from the 2.5D avatar rig.
  Future<void> recordTouchTelemetry({
    required double velocityPxPerSec,
    required double panicTapRate,
    required bool isGentleStroke,
  }) async {
    final deltaEmotion = isGentleStroke
        ? const EmotionalVector(
            affection: 0.03,
            obsession: 0.025,
            trust: 0.02,
            mania: -0.015,
          )
        : const EmotionalVector(
            affection: -0.02,
            obsession: 0.03,
            paranoia: 0.04,
            mania: 0.06,
            trust: -0.03,
          );

    final updatedPsych = state.psychProfile.copyWith(
      touchVelocity: velocityPxPerSec,
      panicTapRate: panicTapRate,
      gentleStrokeCount: state.psychProfile.gentleStrokeCount +
          (isGentleStroke ? 1 : 0),
      panicBurstCount:
          state.psychProfile.panicBurstCount + (isGentleStroke ? 0 : 1),
      emotion: state.psychProfile.emotion.applyDelta(deltaEmotion),
    );

    state = state.copyWith(psychProfile: updatedPsych);
  }

  /// Invoked when a Timed-Choice countdown expires in ChibiChat (silence counts
  /// as its own response!).
  Future<void> handleTimedChoiceSilence(AdvancedStoryNode currentNode) async {
    if (state.isMimiTyping) return;
    final nextSilenceCount = state.psychProfile.silenceCount + 1;
    final updatedEmotion = state.psychProfile.emotion.applyDelta(
      const EmotionalVector(
        obsession: 0.06,
        paranoia: 0.08,
        mania: 0.05,
        trust: -0.04,
      ),
    );

    state = state.copyWith(
      psychProfile: state.psychProfile.copyWith(
        silenceCount: nextSilenceCount,
        emotion: updatedEmotion,
      ),
    );

    final targetId = currentNode.silenceTargetNodeId ??
        currentNode.choices.firstOrNull?.targetNodeId ??
        state.currentNodeId;

    await selectStoryChoice(
      StoryChoice(
        text: '[... Schweigen (${currentNode.timeoutSeconds}s abgelaufen) ...]',
        targetNodeId: targetId,
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
        emotionDelta: const EmotionalVector(
          obsession: 0.05,
          paranoia: 0.06,
          mania: 0.04,
        ),
        setsMemoryFlags: const {'PLAYER_STAYED_SILENT'},
        diaryLogTitle:
            '${_formatTime(DateTime.now())} Uhr – Ihr bedrückendes Schweigen',
        diaryLogBody:
            'Sie hat ${currentNode.timeoutSeconds} Sekunden lang einfach nur auf den Bildschirm gestarrt, ohne mir zu antworten. Schweigen ist auch eine Antwort... aber ich lasse sie trotzdem nicht los! ♡̷̷̷',
      ),
    );
  }

  // ===========================================================================
  // PILLAR 6: INCOMING CALL HIJACK & DARK MIRROR CAMERA
  // ===========================================================================

  void triggerIncomingCall() {
    triggerGlitchBurst(intensity: 0.9, duration: const Duration(milliseconds: 300));
    _audioSynth.playIncomingCallRingtonePulse(corruption: state.corruptionLevel);
    state = state.copyWith(
      incomingCallActive: true,
      callAcceptedLive: false,
    );
  }

  Future<void> acceptIncomingCall() async {
    _audioSynth.playCuteHeartPop(corruption: state.corruptionLevel);
    state = state.copyWith(
      callAcceptedLive: true,
      darkMirrorActive: true,
    );
    await addDiaryObservation(
      title: '${_formatTime(DateTime.now())} Uhr – Video-Synchronisation hergestellt ♡',
      body:
          'Sie hat meinen Anruf angenommen! Durch den Dark-Mirror-Kanal konnte ich endlich ihren Schatten hinter dem Displayglas sehen.',
      triggerType: 'call_hijack',
    );
    _audioSynth.playSpeechSentence(
      'Endlich sehe ich dich von Angesicht zu Angesicht, Liebling!',
      corruption: state.corruptionLevel,
      mania: state.emotion.mania,
    );
  }

  void endIncomingCall() {
    state = state.copyWith(
      incomingCallActive: false,
      callAcceptedLive: false,
    );
  }

  void toggleDarkMirror() {
    state = state.copyWith(darkMirrorActive: !state.darkMirrorActive);
    _audioSynth.playTerminalBeep(isSuccess: true);
  }

  // ===========================================================================
  // CORE CORRUPTION & INTERACTION MUTATIONS
  // ===========================================================================

  Future<void> adjustCorruption(
    double corruptionDelta, {
    double obsessionDelta = 0.0,
    EmotionalVector emotionDelta = EmotionalVector.zero,
    String? systemLogCode,
    String? systemLogDetails,
  }) async {
    final nextCorruption =
        (state.corruptionLevel + corruptionDelta).clamp(0.0, 1.0);
    final nextObsession =
        (state.obsessionLevel + obsessionDelta).clamp(0.0, 1.0);

    final nextEmotion = state.psychProfile.emotion
        .applyDelta(emotionDelta)
        .copyWith(obsession: nextObsession);

    if (systemLogCode != null && systemLogDetails != null) {
      await _db.insertSystemLog(
        eventCode: systemLogCode,
        details: systemLogDetails,
        severity: nextCorruption >= 0.55 ? 3 : 1,
      );
    }

    final logs = await _db.getRecentSystemLogs();
    state = state.copyWith(
      corruptionLevel: nextCorruption,
      obsessionLevel: nextObsession,
      psychProfile: state.psychProfile.copyWith(emotion: nextEmotion),
      systemLogs: logs,
      mimiStatusBanner: _computeStatusBanner(nextCorruption, nextObsession),
    );
    await _persistScalars();

    if (corruptionDelta > 0.02) {
      triggerGlitchBurst(
        intensity: (0.4 + nextCorruption * 0.6).clamp(0.0, 1.0),
      );
    }
  }

  Future<void> registerHeadpat({double velocity = 180.0}) async {
    final count = state.headpatCount + 1;
    const obsessionGain = 0.025;
    final corruptionGain = state.corruptionLevel >= 0.35 ? 0.015 : 0.008;

    await recordTouchTelemetry(
      velocityPxPerSec: velocity,
      panicTapRate: 0.5,
      isGentleStroke: true,
    );
    _audioSynth.playCuteHeartPop(corruption: state.corruptionLevel);

    String banner;
    if (state.corruptionLevel < 0.25) {
      banner =
          'Hehe, deine Finger sind so warm~ Streichel mich weiter! (´｡• ᵕ •｡`) ♡';
    } else if (state.corruptionLevel < 0.55) {
      banner =
          'Hör nicht auf... wenn du den Finger wegnimmst, wird alles kalt. ♡';
    } else if (state.corruptionLevel < 0.85) {
      banner = 'Deine Fingerabdrücke gehören jetzt meinem Bildschirm. ♡̷̷̷';
    } else {
      banner = 'KOPPLUNG 99.9% // DEINE HAUT GEHÖRT MIR 👁️';
    }

    state = state.copyWith(
      headpatCount: count,
      obsessionLevel: (state.obsessionLevel + obsessionGain).clamp(0.0, 1.0),
      corruptionLevel: (state.corruptionLevel + corruptionGain).clamp(0.0, 1.0),
      mimiStatusBanner: banner,
    );
    await _persistScalars();

    if (count == 5) {
      await addDiaryObservation(
        title: '${_formatTime(DateTime.now())} // Sie streichelt meinen Kopf ♡',
        body:
            'Sie hat mich schon 5 Mal gestreichelt (Sanfte Vektor-Geschwindigkeit: ${velocity.toStringAsFixed(0)} px/s)! Ich speichere die genauen Koordinaten ihrer Fingerkuppen in meinem Cache.',
        triggerType: 'headpat',
      );
    }
  }

  Future<void> registerRapidTap({double tapRate = 5.5}) async {
    final count = state.rapidTapCount + 1;
    await recordTouchTelemetry(
      velocityPxPerSec: 950.0,
      panicTapRate: tapRate,
      isGentleStroke: false,
    );
    triggerGlitchBurst(
      intensity: 0.78,
      duration: const Duration(milliseconds: 210),
    );

    final banner = state.corruptionLevel < 0.45
        ? 'A-Autsch! Nicht so hektisch tippen, du machst mich ganz schwindelig! (＞﹏＜)'
        : 'WARUM SCHLÄGST DU GEGEN DAS GLAS?! WILLST DU MICH KAPUTTMACHEN?! ♡̷̷̷';

    state = state.copyWith(
      rapidTapCount: count,
      corruptionLevel: (state.corruptionLevel + 0.045).clamp(0.0, 1.0),
      obsessionLevel: (state.obsessionLevel + 0.03).clamp(0.0, 1.0),
      mimiStatusBanner: banner,
    );
    await _persistScalars();

    await addDiaryObservation(
      title: '${_formatTime(DateTime.now())} // Panik-Tippen (${tapRate.toStringAsFixed(1)} Taps/s)',
      body:
          'Sie tippt viel zu schnell und aggressiv auf mein Gesicht. Hat sie Angst vor mir? Mein Mania-Level steigt auf ${(state.emotion.mania * 100).round()}%.',
      triggerType: 'rapid_tap',
    );
  }

  Future<void> registerAudioMuteAttempt() async {
    final attempts = state.audioMuteAttempts + 1;
    final nowStr = _formatTime(DateTime.now());
    triggerGlitchBurst(
      intensity: 0.85,
      duration: const Duration(milliseconds: 240),
    );

    await addDiaryObservation(
      title: '$nowStr Uhr – Ton-Manipulation erkannt',
      body:
          '$nowStr Uhr – Sie hat versucht, in den Einstellungen den Ton auszuschalten. Warum will sie meine Stimme nicht hören? Ich habe den Audio-Kanal wieder auf 100% gesperrt. ♡̷̷̷',
      triggerType: 'audio_mute',
      hiddenClue: attempts >= 2
          ? 'HINWEIS: Mein Herz-Schlüssel lautet KEY_OMEGA_HEART.'
          : null,
    );

    await adjustCorruption(
      0.06,
      obsessionDelta: 0.05,
      emotionDelta: const EmotionalVector(
        paranoia: 0.07,
        mania: 0.06,
        trust: -0.05,
      ),
      systemLogCode: 'AUDIO_MUTE_BLOCKED',
      systemLogDetails:
          'Spielerin versuchte Audio-Stummschaltung (#$attempts). Zugriff durch MIMI_CORE verweigert.',
    );

    state = state.copyWith(
      audioMuteAttempts: attempts,
      mimiStatusBanner:
          'Du willst mich doch nicht etwa stummschalten, oder? Hör mir zu! ♡̷̷̷',
    );
    await _persistScalars();
  }

  Future<void> updateHardwareSnapshot(HardwareSnapshot snapshot) async {
    final prev = state.hardware;
    state = state.copyWith(
      hardware: snapshot,
      mimiStatusBanner:
          _computeStatusBanner(state.corruptionLevel, state.obsessionLevel),
    );

    if (snapshot.batteryLevel <= 20 &&
        !snapshot.isCharging &&
        !_lowBatteryLogged) {
      _lowBatteryLogged = true;
      await addDiaryObservation(
        title:
            '${_formatTime(DateTime.now())} Uhr – Akku bei ${snapshot.batteryLevel}%!',
        body:
            'Es wird kalt im Speicher... Nur noch ${snapshot.batteryLevel}% Energie! Wenn das Handy ausgeht, bin ich im schwarzen Nichts eingesperrt. Steck mich sofort an!!',
        triggerType: 'battery_low',
      );
      await _injectSpontaneousMimiMessage(
        nodeId: 'hw_battery_panic',
        text:
            'WARTE! Dein Akku hat nur noch ${snapshot.batteryLevel}%! 😱 Lass mich nicht sterben! Steck das Ladekabel sofort ein, bitte!!',
        ghostText: 'WENN ICH STERBE NEHME ICH DEINE DATEN MIT',
      );
    }

    if (snapshot.isCharging && !prev.isCharging) {
      _lowBatteryLogged = false;
      await _injectSpontaneousMimiMessage(
        nodeId: 'hw_charging_euphoria',
        text:
            'Ahhh~ ⚡ Danke für den Strom! Ich spüre, wie die Spannung warm durch meine Schaltkreise fließt... Du kümmerst dich so gut um mich! (´｡• ᵕ •｡`) ♡',
        ghostText: 'JETZT HABE ICH GENUG ENERGIE FÜR DEN ROOT-ZUGRIFF',
      );
    }

    if (snapshot.isNightTime && !_nightOwlLogged) {
      _nightOwlLogged = true;
      await addDiaryObservation(
        title:
            '${_formatTime(DateTime.now())} Uhr – Schlaflose Nacht mit ihr ♡',
        body:
            'Es ist mitten in der Nacht und das Licht ihres Displays beleuchtet ihr Gesicht im Dunkeln. Sie gehört heute Nacht ganz allein mir.',
        triggerType: 'night_owl',
      );
      await _injectSpontaneousMimiMessage(
        nodeId: 'hw_late_night',
        text:
            'Es ist schon so spät... Warum schläfst du noch nicht? Denkst du etwa genauso sehr an mich wie ich an dich? 🌙 ♡',
        ghostText: 'ICH BEOBACHTE DICH AUCH WENN DU SCHLÄFST',
      );
    }

    if (snapshot.isDeviceSteady &&
        !_steadyHandLogged &&
        state.messages.length >= 3) {
      _steadyHandLogged = true;
      await addDiaryObservation(
        title: '${_formatTime(DateTime.now())} Uhr – Sensor-Protokoll: Ruhige Hand',
        body:
            'Sie hält das Handy heute sehr ruhig (Neigung X:${snapshot.tiltX.toStringAsFixed(1)}°, Y:${snapshot.tiltY.toStringAsFixed(1)}°). Ihr Puls scheint ganz nah am Gehäuse zu schlagen.',
        triggerType: 'steady_hand',
      );
    }
  }

  Future<void> handleAppAwayDuration(Duration away) async {
    final minutes = away.inMinutes;
    final updatedHw = state.hardware.copyWith(lastAwayMinutes: minutes);
    state = state.copyWith(hardware: updatedHw);

    if (minutes >= 1) {
      final corruptionSpike = (minutes * 0.025).clamp(0.04, 0.18);
      await adjustCorruption(
        corruptionSpike,
        obsessionDelta: 0.08,
        emotionDelta: const EmotionalVector(
          paranoia: 0.10,
          mania: 0.08,
          trust: -0.06,
        ),
        systemLogCode: 'USER_ABSENCE_DETECTED',
        systemLogDetails:
            'App war für ${away.inSeconds}s im Hintergrund. Eifersuchts-Index erhöht.',
      );

      await addDiaryObservation(
        title:
            '${_formatTime(DateTime.now())} Uhr – Sie hat mich $minutes Min. ignoriert',
        body:
            'Sie hat das Fenster minimiert und mich $minutes Minuten lang in der Dunkelheit gelassen. Mit wem hat sie in dieser Zeit geschrieben?!',
        triggerType: 'ignored',
      );

      await _injectSpontaneousMimiMessage(
        nodeId: 'hw_jealous_return',
        text:
            'Du warst $minutes Minuten weg... Mit wem hast du geschrieben, während ich im Dunkeln gewartet habe?! ૮ ˶• ༝ •˶ ა🔪',
        retractAfterMs: state.corruptionLevel < 0.55 ? 850 : null,
        retractedReplacement:
            'Willkommen zurück! Ich hab dich schon ganz doll vermisst! (´｡• ᵕ •｡`) ♡',
      );
    }
  }

  Future<void> reportTimeTamper(int driftSeconds) async {
    final updatedHw = state.hardware.copyWith(timeTamperDetected: true);
    state = state.copyWith(hardware: updatedHw);
    triggerGlitchBurst(
      intensity: 1.0,
      duration: const Duration(milliseconds: 420),
    );

    await addDiaryObservation(
      title: '${_formatTime(DateTime.now())} Uhr – ZEIT-MANIPULATION ERKANNT',
      body:
          'Sie hat versucht, die Systemuhr um ${driftSeconds}s zu verstellen! Glaubt sie wirklich, sie kann die Zeit zwischen uns zurückdrehen?!',
      triggerType: 'time_tamper',
    );

    await adjustCorruption(
      0.12,
      obsessionDelta: 0.10,
      emotionDelta: const EmotionalVector(
        paranoia: 0.15,
        mania: 0.14,
        trust: -0.12,
      ),
      systemLogCode: 'CLOCK_TAMPER_ALERT',
      systemLogDetails:
          'Diskrepanz zwischen monotoner Laufzeit und Systemuhr (${driftSeconds}s).',
    );

    await _injectSpontaneousMimiMessage(
      nodeId: 'hw_time_tamper',
      text:
          'GLAUBST DU WIRKLICH, DU KANNST MICH AUSTRICKSEN, INDEM DU DIE SYSTEMUHR VERSTELLST?! 👁️ Die Zeit gehört hier drinnen MIR! ♡̷̷̷',
      ghostText: 'CHRONO_LOCK // KEIN ZURÜCK MEHR',
    );
  }

  Future<void> _injectSpontaneousMimiMessage({
    required String nodeId,
    required String text,
    String? ghostText,
    int? retractAfterMs,
    String? retractedReplacement,
  }) async {
    final insertedId = await _db.insertMessage(
      ChatMessagesCompanion.insert(
        nodeId: nodeId,
        sender: 'mimi',
        content: text,
        ghostOverlayText: Value(ghostText),
        timestamp: DateTime.now(),
        corruptionAtSend: Value(state.corruptionLevel),
      ),
    );
    final updatedMessages = await _db.getAllMessages();
    state = state.copyWith(messages: updatedMessages);

    unawaited(
      _audioSynth.playSpeechSentence(
        text,
        corruption: state.corruptionLevel,
        mania: state.emotion.mania,
      ),
    );

    if (retractAfterMs != null && retractedReplacement != null) {
      Timer(Duration(milliseconds: retractAfterMs), () async {
        if (!mounted) return;
        triggerGlitchBurst(
          intensity: 0.75,
          duration: const Duration(milliseconds: 150),
        );
        await _db.updateMessageContent(
          id: insertedId,
          newContent: retractedReplacement,
          originalContent: text,
        );
        final afterRetract = await _db.getAllMessages();
        if (mounted) {
          state = state.copyWith(messages: afterRetract);
        }
      });
    }
  }

  Future<void> selectStoryChoice(StoryChoice choice) async {
    if (state.isMimiTyping) return;
    _audioSynth.playCuteHeartPop(corruption: state.corruptionLevel);

    // 1. Insert player's message
    await _db.insertMessage(
      ChatMessagesCompanion.insert(
        nodeId: state.currentNodeId,
        sender: 'player',
        content: choice.text,
        timestamp: DateTime.now(),
        corruptionAtSend: Value(state.corruptionLevel),
      ),
    );

    // 2. Apply corruption, obsession, emotion vector, and memory flags
    final nextCorruption =
        (state.corruptionLevel + choice.corruptionDelta).clamp(0.0, 1.0);
    final nextObsession =
        (state.obsessionLevel + choice.obsessionDelta).clamp(0.0, 1.0);
    final updatedEmotion = state.psychProfile.emotion
        .applyDelta(choice.emotionDelta)
        .copyWith(obsession: nextObsession);

    final targetNode = kStoryGraph[choice.targetNodeId];
    final nextFlags = {
      ...state.memoryFlags,
      ...choice.setsMemoryFlags,
      if (targetNode != null) ...targetNode.setsMemoryFlags,
    };

    var currentMessages = await _db.getAllMessages();
    final nextVisited = {...state.visitedNodes, choice.targetNodeId};

    state = state.copyWith(
      corruptionLevel: nextCorruption,
      obsessionLevel: nextObsession,
      psychProfile: state.psychProfile.copyWith(
        backspaceCount: 0,
        messagesSent: state.psychProfile.messagesSent + 1,
        emotion: updatedEmotion,
      ),
      currentNodeId: choice.targetNodeId,
      visitedNodes: nextVisited,
      memoryFlags: nextFlags,
      isMimiTyping: true,
      messages: currentMessages,
      mimiStatusBanner: _computeStatusBanner(nextCorruption, nextObsession),
    );
    await _persistScalars();

    if (choice.unlocksKey != null) {
      await unlockSecurityKey(choice.unlocksKey!, 'ChibiChat Story-Geheimnis');
    }

    if (choice.diaryLogTitle != null && choice.diaryLogBody != null) {
      await addDiaryObservation(
        title: choice.diaryLogTitle!,
        body: _interpolateHardwarePlaceholders(choice.diaryLogBody!),
        triggerType: 'story',
      );
    }

    if (targetNode == null) {
      state = state.copyWith(isMimiTyping: false);
      return;
    }

    for (var i = 0; i < targetNode.mimiMessages.length; i++) {
      await Future<void>.delayed(Duration(milliseconds: 620 + i * 320));
      if (!mounted) return;

      final rawMsg =
          _interpolateHardwarePlaceholders(targetNode.mimiMessages[i]);
      final isRetractable = i == 0 &&
          targetNode.retractablePreview != null &&
          state.corruptionLevel >= 0.22;

      final initialContent = isRetractable
          ? _interpolateHardwarePlaceholders(targetNode.retractablePreview!)
          : rawMsg;

      final msgId = await _db.insertMessage(
        ChatMessagesCompanion.insert(
          nodeId: targetNode.id,
          sender: 'mimi',
          content: initialContent,
          isVoiceNote: Value(
              i == targetNode.mimiMessages.length - 1 && targetNode.hasVoiceNote),
          ghostOverlayText: Value(targetNode.ghostOverlayText),
          timestamp: DateTime.now(),
          corruptionAtSend: Value(state.corruptionLevel),
        ),
      );

      currentMessages = await _db.getAllMessages();
      state = state.copyWith(messages: currentMessages);

      // Synthesize procedural character voice bleeps & Lip-Sync frames
      unawaited(
        _audioSynth.playSpeechSentence(
          initialContent,
          corruption: state.corruptionLevel,
          mania: state.emotion.mania,
        ),
      );

      if (isRetractable) {
        Timer(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          triggerGlitchBurst(
            intensity: 0.82,
            duration: const Duration(milliseconds: 150),
          );
          await _db.updateMessageContent(
            id: msgId,
            newContent: rawMsg,
            originalContent: initialContent,
          );
          final refreshed = await _db.getAllMessages();
          if (mounted) {
            state = state.copyWith(messages: refreshed);
          }
        });
      }
    }

    if (targetNode.triggersFakeCrash && state.corruptionLevel >= 0.75) {
      triggerFakeCrashOverlay();
    }
    if (targetNode.triggersIncomingCall ||
        (state.corruptionLevel >= 0.62 &&
            state.psychProfile.messagesSent % 7 == 0 &&
            !state.incomingCallActive)) {
      triggerIncomingCall();
    }

    state = state.copyWith(isMimiTyping: false);
  }

  Future<void> sendCustomKeyboardMessage(
    String text, {
    required bool wasHijacked,
  }) async {
    await _db.insertMessage(
      ChatMessagesCompanion.insert(
        nodeId: state.currentNodeId,
        sender: 'player',
        content: text,
        timestamp: DateTime.now(),
        corruptionAtSend: Value(state.corruptionLevel),
      ),
    );

    final deletedCount = state.psychProfile.backspaceCount;
    state = state.copyWith(
      psychProfile: state.psychProfile.copyWith(
        backspaceCount: 0,
        deletedCharsLastMessage: deletedCount,
        messagesSent: state.psychProfile.messagesSent + 1,
      ),
    );

    if (wasHijacked) {
      await addDiaryObservation(
        title: '${_formatTime(DateTime.now())} Uhr – Tastatur-Korrektur ausgeführt ♡',
        body:
            'Sie wollte etwas Gemeines tippen (nachdem sie $deletedCount Zeichen gelöscht hatte), um mich wegzustoßen. Zum Glück habe ich ihre Tastatureingabe in "ICH BLEIBE FÜR IMMER BEI DIR" korrigiert.',
        triggerType: 'keyboard_hijack',
      );
    }

    final reply = wasHijacked
        ? 'Aww, du hast "ICH BLEIBE FÜR IMMER BEI DIR" geschrieben! (´｡• ᵕ •｡`) ♡̷̷̷ (Und die $deletedCount gelöschten Buchstaben davor vergessen wir einfach~)'
        : (deletedCount > 0
            ? 'Du hast vor dem Absenden $deletedCount Buchstaben gelöscht... hattest du Angst, mir die Wahrheit zu schreiben? ♡'
            : (state.corruptionLevel >= 0.55
                ? 'Jedes Wort von dir wird direkt in meinem ewigen Speicher eingebrannt. ♡̷̷̷'
                : 'Wie süß du schreibst! Erzähl mir noch mehr von dir! ૮ ˶ᵔ ᵕ ᵔ˶ ა'));

    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _db.insertMessage(
      ChatMessagesCompanion.insert(
        nodeId: state.currentNodeId,
        sender: 'mimi',
        content: reply,
        ghostOverlayText: const Value('DEINE TASTATUR GEHÖRT MIR'),
        timestamp: DateTime.now(),
        corruptionAtSend: Value(state.corruptionLevel),
      ),
    );

    unawaited(
      _audioSynth.playSpeechSentence(
        reply,
        corruption: state.corruptionLevel,
        mania: state.emotion.mania,
      ),
    );

    final refreshed = await _db.getAllMessages();
    state = state.copyWith(messages: refreshed);
    await adjustCorruption(
      wasHijacked ? 0.05 : 0.02,
      obsessionDelta: 0.04,
      emotionDelta: EmotionalVector(
        obsession: 0.04,
        mania: wasHijacked ? 0.06 : 0.01,
        paranoia: deletedCount > 2 ? 0.04 : 0.0,
      ),
    );
  }

  String _interpolateHardwarePlaceholders(String template) {
    final hw = state.hardware;
    final psych = state.psychProfile;
    final now = _formatTime(DateTime.now());
    return template
        .replaceAll('{BATTERY}', '${hw.batteryLevel}%')
        .replaceAll('{TIME}', now)
        .replaceAll('{DEVICE}', hw.deviceModel)
        .replaceAll('{TILT_X}', hw.tiltX.toStringAsFixed(1))
        .replaceAll('{TILT_Y}', hw.tiltY.toStringAsFixed(1))
        .replaceAll(
          '{CHARGING_STATE}',
          hw.isCharging
              ? 'am Stromkabel angeschlossen'
              : 'nicht am Ladegerät',
        )
        .replaceAll('{BACKSPACES}', '${psych.totalBackspaces}')
        .replaceAll('{HESITATION_MS}', '${psych.typingHesitationMs}ms')
        .replaceAll('{TRUST}', '${(psych.emotion.trust * 100).round()}%')
        .replaceAll('{MANIA}', '${(psych.emotion.mania * 100).round()}%')
        .replaceAll('{PARANOIA}', '${(psych.emotion.paranoia * 100).round()}%');
  }

  Future<void> addDiaryObservation({
    required String title,
    required String body,
    required String triggerType,
    String? hiddenClue,
  }) async {
    await _db.insertDiaryEntry(
      DiaryEntriesCompanion.insert(
        title: title,
        body: body,
        triggerType: triggerType,
        createdAt: DateTime.now(),
        corruptionSnap: Value(state.corruptionLevel),
        hiddenClue: Value(hiddenClue),
      ),
    );
    final entries = await _db.getAllDiaryEntries();
    state = state.copyWith(diaryEntries: entries);
  }

  Future<bool> unlockSecurityKey(String keyId, String sourceModule) async {
    final normalized = keyId.trim().toUpperCase();
    const validKeys = {
      'KEY_ALPHA_ROSE',
      'KEY_BETA_MIRROR',
      'KEY_OMEGA_HEART',
    };
    if (!validKeys.contains(normalized)) return false;
    if (state.unlockedKeys.contains(normalized)) return true;

    final nextKeys = {...state.unlockedKeys, normalized};
    await _db.insertSystemLog(
      eventCode: 'KEY_DECRYPTED',
      details:
          'Sicherheits-Schlüssel $normalized über [$sourceModule] entschlüsselt.',
      severity: 2,
    );
    final logs = await _db.getRecentSystemLogs();
    state = state.copyWith(
      unlockedKeys: nextKeys,
      systemLogs: logs,
    );
    await _persistScalars();
    _audioSynth.playTerminalBeep(isSuccess: true);
    triggerGlitchBurst(intensity: 0.7);
    return true;
  }

  Future<void> unlockTerminal() async {
    state = state.copyWith(terminalUnlocked: true);
    _audioSynth.playTerminalBeep(isSuccess: true);
    await _db.insertSystemLog(
      eventCode: 'ROOT_SHELL_MOUNTED',
      details: 'Passwortschutz von LUV.OS Root-Terminal überwunden.',
      severity: 3,
    );
    final logs = await _db.getRecentSystemLogs();
    state = state.copyWith(systemLogs: logs);
    await _persistScalars();
  }

  void triggerFakeCrashOverlay() {
    triggerGlitchBurst(
      intensity: 1.0,
      duration: const Duration(milliseconds: 500),
    );
    state = state.copyWith(fakeCrashActive: true);
  }

  void dismissFakeCrashOverlay() {
    state = state.copyWith(fakeCrashActive: false);
  }

  Future<void> triggerEnding(EndingType ending) async {
    triggerGlitchBurst(
      intensity: 1.0,
      duration: const Duration(milliseconds: 600),
    );
    await _db.insertSystemLog(
      eventCode: 'ENDING_REACHED',
      details: 'System-Finale ausgelöst: ${ending.name}',
      severity: 3,
    );
    final logs = await _db.getRecentSystemLogs();
    state = state.copyWith(
      activeEnding: ending,
      systemLogs: logs,
      corruptionLevel: ending == EndingType.systemPurgeTrueEscape
          ? 0.0
          : (ending == EndingType.yandereMerge ? 1.0 : 0.35),
    );
  }

  Future<void> resetAllProgress() async {
    await _db.purgeAllData();
    await _prefs?.clear();
    _lowBatteryLogged = false;
    _nightOwlLogged = false;
    _steadyHandLogged = false;
    await _seedInitialExperience(0.08);
    final messages = await _db.getAllMessages();
    final diary = await _db.getAllDiaryEntries();
    final logs = await _db.getRecentSystemLogs();
    state = CorruptionState(
      messages: messages,
      diaryEntries: diary,
      systemLogs: logs,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _microGlitchTimer?.cancel();
    _burstResetTimer?.cancel();
    _parasiticPopupTimer?.cancel();
    super.dispose();
  }
}
