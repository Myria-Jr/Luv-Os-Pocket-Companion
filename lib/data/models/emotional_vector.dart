import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The five emotional axes Mimi uses to model her own state toward the player.
enum EmotionAxis { affection, obsession, paranoia, mania, trust }

/// Immutable 5-dimensional emotional state vector. Every component is
/// normalised to `0.0 - 1.0`.
@immutable
class EmotionalVector {
  final double affection;
  final double obsession;
  final double paranoia;
  final double mania;
  final double trust;

  const EmotionalVector({
    this.affection = 0.0,
    this.obsession = 0.0,
    this.paranoia = 0.0,
    this.mania = 0.0,
    this.trust = 0.0,
  });

  /// Mimi's state right after installation: adoring, trusting, calm.
  static const EmotionalVector initial = EmotionalVector(
    affection: 0.62,
    obsession: 0.15,
    paranoia: 0.05,
    mania: 0.08,
    trust: 0.70,
  );

  /// A zero delta, useful as a default for choices without emotional impact.
  static const EmotionalVector zero = EmotionalVector();

  double operator [](EmotionAxis axis) {
    switch (axis) {
      case EmotionAxis.affection:
        return affection;
      case EmotionAxis.obsession:
        return obsession;
      case EmotionAxis.paranoia:
        return paranoia;
      case EmotionAxis.mania:
        return mania;
      case EmotionAxis.trust:
        return trust;
    }
  }

  /// Adds a delta vector and clamps every component to `0.0 - 1.0`.
  EmotionalVector applyDelta(EmotionalVector delta) {
    return EmotionalVector(
      affection: (affection + delta.affection).clamp(0.0, 1.0),
      obsession: (obsession + delta.obsession).clamp(0.0, 1.0),
      paranoia: (paranoia + delta.paranoia).clamp(0.0, 1.0),
      mania: (mania + delta.mania).clamp(0.0, 1.0),
      trust: (trust + delta.trust).clamp(0.0, 1.0),
    );
  }

  /// Unclamped component-wise scaling, used to build deltas.
  EmotionalVector scale(double factor) {
    return EmotionalVector(
      affection: affection * factor,
      obsession: obsession * factor,
      paranoia: paranoia * factor,
      mania: mania * factor,
      trust: trust * factor,
    );
  }

  /// Exponential decay of the volatile axes (mania, paranoia) toward a
  /// resting baseline. [dtSeconds] is the elapsed time; [halfLifeSeconds]
  /// controls how quickly Mimi calms down.
  EmotionalVector decayVolatile(double dtSeconds, {double halfLifeSeconds = 90}) {
    final k = math.pow(0.5, dtSeconds / halfLifeSeconds).toDouble();
    final maniaFloor = obsession * 0.35;
    final paranoiaFloor = (1.0 - trust) * 0.30;
    return copyWith(
      mania: maniaFloor + (mania - maniaFloor) * k,
      paranoia: paranoiaFloor + (paranoia - paranoiaFloor) * k,
    );
  }

  static EmotionalVector lerp(EmotionalVector a, EmotionalVector b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    return EmotionalVector(
      affection: l(a.affection, b.affection),
      obsession: l(a.obsession, b.obsession),
      paranoia: l(a.paranoia, b.paranoia),
      mania: l(a.mania, b.mania),
      trust: l(a.trust, b.trust),
    );
  }

  /// Euclidean length, normalised so that the all-ones vector has length 1.
  double get magnitude =>
      math.sqrt(
        affection * affection +
            obsession * obsession +
            paranoia * paranoia +
            mania * mania +
            trust * trust,
      ) /
      math.sqrt(5);

  /// "Yandere pressure": high when obsession and mania are high while trust is low.
  double get yanderePressure =>
      (obsession * 0.45 + mania * 0.30 + paranoia * 0.15 + (1.0 - trust) * 0.10)
          .clamp(0.0, 1.0);

  EmotionAxis get dominantAxis {
    var best = EmotionAxis.affection;
    var bestValue = -1.0;
    for (final axis in EmotionAxis.values) {
      final v = this[axis];
      if (v > bestValue) {
        bestValue = v;
        best = axis;
      }
    }
    return best;
  }

  EmotionalVector copyWith({
    double? affection,
    double? obsession,
    double? paranoia,
    double? mania,
    double? trust,
  }) {
    return EmotionalVector(
      affection: (affection ?? this.affection).clamp(0.0, 1.0),
      obsession: (obsession ?? this.obsession).clamp(0.0, 1.0),
      paranoia: (paranoia ?? this.paranoia).clamp(0.0, 1.0),
      mania: (mania ?? this.mania).clamp(0.0, 1.0),
      trust: (trust ?? this.trust).clamp(0.0, 1.0),
    );
  }

  Map<String, double> toJson() => {
        'affection': affection,
        'obsession': obsession,
        'paranoia': paranoia,
        'mania': mania,
        'trust': trust,
      };

  factory EmotionalVector.fromJson(Map<String, dynamic> json) {
    double read(String key, double fallback) {
      final v = json[key];
      return v is num ? v.toDouble() : fallback;
    }

    return EmotionalVector(
      affection: read('affection', initial.affection),
      obsession: read('obsession', initial.obsession),
      paranoia: read('paranoia', initial.paranoia),
      mania: read('mania', initial.mania),
      trust: read('trust', initial.trust),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EmotionalVector &&
      other.affection == affection &&
      other.obsession == obsession &&
      other.paranoia == paranoia &&
      other.mania == mania &&
      other.trust == trust;

  @override
  int get hashCode => Object.hash(affection, obsession, paranoia, mania, trust);

  @override
  String toString() =>
      'EmotionalVector(aff: ${affection.toStringAsFixed(2)}, obs: ${obsession.toStringAsFixed(2)}, '
      'par: ${paranoia.toStringAsFixed(2)}, man: ${mania.toStringAsFixed(2)}, tru: ${trust.toStringAsFixed(2)})';
}
