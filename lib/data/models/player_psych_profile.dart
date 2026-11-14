import 'package:flutter/foundation.dart';

import 'emotional_vector.dart';

/// Immutable behavioural telemetry snapshot of the player.
///
/// Mimi does not only react to discrete choices: every keystroke, deletion,
/// hesitation, tap velocity and ignored countdown is folded into this profile.
@immutable
class PlayerPsychProfile {
  /// Time between Mimi's last message and the player's first keystroke of the
  /// current reply (or the send action, if nothing was typed).
  final int typingHesitationMs;

  /// Exponential moving average of [typingHesitationMs] across all replies.
  final double avgHesitationMs;

  /// Backspaces pressed in the current (unsent) draft.
  final int backspaceCount;

  /// Backspaces pressed across the whole save game.
  final int totalBackspaces;

  /// Number of characters the player deleted before sending the last message.
  final int deletedCharsLastMessage;

  /// Most recent touch velocity on the avatar in logical pixels per second.
  final double touchVelocity;

  /// Rolling taps per second over the last ~2 seconds.
  final double panicTapRate;

  /// Count of slow, gentle strokes (headpats) recognised by velocity analysis.
  final int gentleStrokeCount;

  /// Count of panic bursts (fast, repeated taps).
  final int panicBurstCount;

  /// Number of timed choices the player let expire (silence as an answer).
  final int silenceCount;

  /// Number of messages the player has actively sent.
  final int messagesSent;

  /// Mimi's emotional reading of the relationship.
  final EmotionalVector emotion;

  const PlayerPsychProfile({
    this.typingHesitationMs = 0,
    this.avgHesitationMs = 0,
    this.backspaceCount = 0,
    this.totalBackspaces = 0,
    this.deletedCharsLastMessage = 0,
    this.touchVelocity = 0,
    this.panicTapRate = 0,
    this.gentleStrokeCount = 0,
    this.panicBurstCount = 0,
    this.silenceCount = 0,
    this.messagesSent = 0,
    this.emotion = EmotionalVector.initial,
  });

  static const PlayerPsychProfile initial = PlayerPsychProfile();

  /// A coarse "is the player nervous?" score in `0.0 - 1.0`.
  double get nervousness {
    final hesitation = (avgHesitationMs / 12000.0).clamp(0.0, 1.0);
    final deletions = (totalBackspaces / 120.0).clamp(0.0, 1.0);
    final panic = (panicTapRate / 8.0).clamp(0.0, 1.0);
    final silence = (silenceCount / 6.0).clamp(0.0, 1.0);
    return (hesitation * 0.30 + deletions * 0.25 + panic * 0.25 + silence * 0.20)
        .clamp(0.0, 1.0);
  }

  PlayerPsychProfile copyWith({
    int? typingHesitationMs,
    double? avgHesitationMs,
    int? backspaceCount,
    int? totalBackspaces,
    int? deletedCharsLastMessage,
    double? touchVelocity,
    double? panicTapRate,
    int? gentleStrokeCount,
    int? panicBurstCount,
    int? silenceCount,
    int? messagesSent,
    EmotionalVector? emotion,
  }) {
    return PlayerPsychProfile(
      typingHesitationMs: typingHesitationMs ?? this.typingHesitationMs,
      avgHesitationMs: avgHesitationMs ?? this.avgHesitationMs,
      backspaceCount: backspaceCount ?? this.backspaceCount,
      totalBackspaces: totalBackspaces ?? this.totalBackspaces,
      deletedCharsLastMessage:
          deletedCharsLastMessage ?? this.deletedCharsLastMessage,
      touchVelocity: touchVelocity ?? this.touchVelocity,
      panicTapRate: panicTapRate ?? this.panicTapRate,
      gentleStrokeCount: gentleStrokeCount ?? this.gentleStrokeCount,
      panicBurstCount: panicBurstCount ?? this.panicBurstCount,
      silenceCount: silenceCount ?? this.silenceCount,
      messagesSent: messagesSent ?? this.messagesSent,
      emotion: emotion ?? this.emotion,
    );
  }

  Map<String, dynamic> toJson() => {
        'typingHesitationMs': typingHesitationMs,
        'avgHesitationMs': avgHesitationMs,
        'backspaceCount': backspaceCount,
        'totalBackspaces': totalBackspaces,
        'deletedCharsLastMessage': deletedCharsLastMessage,
        'touchVelocity': touchVelocity,
        'panicTapRate': panicTapRate,
        'gentleStrokeCount': gentleStrokeCount,
        'panicBurstCount': panicBurstCount,
        'silenceCount': silenceCount,
        'messagesSent': messagesSent,
        'emotion': emotion.toJson(),
      };

  factory PlayerPsychProfile.fromJson(Map<String, dynamic> json) {
    int i(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;
    double d(String k) => (json[k] is num) ? (json[k] as num).toDouble() : 0.0;
    final emotionJson = json['emotion'];
    return PlayerPsychProfile(
      typingHesitationMs: i('typingHesitationMs'),
      avgHesitationMs: d('avgHesitationMs'),
      backspaceCount: i('backspaceCount'),
      totalBackspaces: i('totalBackspaces'),
      deletedCharsLastMessage: i('deletedCharsLastMessage'),
      touchVelocity: d('touchVelocity'),
      panicTapRate: d('panicTapRate'),
      gentleStrokeCount: i('gentleStrokeCount'),
      panicBurstCount: i('panicBurstCount'),
      silenceCount: i('silenceCount'),
      messagesSent: i('messagesSent'),
      emotion: emotionJson is Map<String, dynamic>
          ? EmotionalVector.fromJson(emotionJson)
          : EmotionalVector.initial,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerPsychProfile &&
      other.typingHesitationMs == typingHesitationMs &&
      other.avgHesitationMs == avgHesitationMs &&
      other.backspaceCount == backspaceCount &&
      other.totalBackspaces == totalBackspaces &&
      other.deletedCharsLastMessage == deletedCharsLastMessage &&
      other.touchVelocity == touchVelocity &&
      other.panicTapRate == panicTapRate &&
      other.gentleStrokeCount == gentleStrokeCount &&
      other.panicBurstCount == panicBurstCount &&
      other.silenceCount == silenceCount &&
      other.messagesSent == messagesSent &&
      other.emotion == emotion;

  @override
  int get hashCode => Object.hash(
        typingHesitationMs,
        avgHesitationMs,
        backspaceCount,
        totalBackspaces,
        deletedCharsLastMessage,
        touchVelocity,
        panicTapRate,
        gentleStrokeCount,
        panicBurstCount,
        silenceCount,
        messagesSent,
        emotion,
      );
}
