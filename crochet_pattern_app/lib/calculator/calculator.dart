// The materials calculator (Objective 3).

import '../models/pattern_models.dart';

class InvalidPatternException implements Exception {
  final String message;
  InvalidPatternException(this.message);
  @override
  String toString() => 'InvalidPatternException: $message';
}

const Map<String, ({int consumes, int produces})> _stitchArity = {
  'ch': (consumes: 0, produces: 1),
  'sl st': (consumes: 1, produces: 0),
  'inc': (consumes: 1, produces: 2),
  'dec': (consumes: 2, produces: 1),
};

({int consumes, int produces}) _arityFor(StitchType st) {
  return _stitchArity[st.abbreviation] ?? (consumes: 1, produces: 1);
}

const double _baselineYardsPerStitch = 0.03;

const Map<String, double> _yarnWeightMultiplier = {
  'lace': 0.35,
  'fingering': 0.5,
  'sport': 0.7,
  'dk': 0.85,
  'worsted': 1.0,
  'bulky': 1.4,
  'super_bulky': 1.9,
};

class RoundStitchCount {
  final int roundNumber;
  final int consumedFromPrevious;
  final int produced;
  RoundStitchCount(this.roundNumber, this.consumedFromPrevious, this.produced);
}

List<RoundStitchCount> stitchCountsPerRound(CrochetPattern pattern) {
  final results = <RoundStitchCount>[];
  int? previousProduced;

  for (final round in pattern.rounds) {
    int consumed = 0;
    int produced = 0;
    for (final block in round.blocks) {
      final arity = _arityFor(block.stitchType);
      consumed += arity.consumes * block.repeatCount;
      produced += arity.produces * block.repeatCount;
    }

    if (previousProduced != null && consumed > previousProduced) {
      throw InvalidPatternException(
        'Round ${round.roundNumber} consumes $consumed stitches but the '
        'previous round only produced $previousProduced. Check for an '
        'over-aggressive decrease.',
      );
    }

    results.add(RoundStitchCount(round.roundNumber, consumed, produced));
    previousProduced = produced;
  }

  return results;
}

int totalStitchCount(CrochetPattern pattern) {
  return stitchCountsPerRound(pattern).fold(0, (sum, r) => sum + r.produced);
}

class YardageEstimate {
  final double estimatedYards;
  final double estimatedMeters;
  final double estimatedSkeins;
  YardageEstimate(this.estimatedYards, this.estimatedMeters, this.estimatedSkeins);
}

YardageEstimate estimateYardage(CrochetPattern pattern, {double skeinYards = 200}) {
  final multiplier = _yarnWeightMultiplier[pattern.yarnWeightCategory] ?? 1.0;
  double totalYards = 0;

  for (final round in pattern.rounds) {
    for (final block in round.blocks) {
      totalYards += block.repeatCount *
          _baselineYardsPerStitch *
          block.stitchType.yarnConsumptionFactor *
          multiplier;
    }
  }

  return YardageEstimate(
    double.parse(totalYards.toStringAsFixed(1)),
    double.parse((totalYards * 0.9144).toStringAsFixed(1)),
    double.parse((totalYards / skeinYards).toStringAsFixed(2)),
  );
}

class DimensionEstimate {
  final double? widthCm;
  final double? heightCm;
  final String? note;
  DimensionEstimate({this.widthCm, this.heightCm, this.note});
}

DimensionEstimate estimateDimensions(
  CrochetPattern pattern, {
  double? gaugeStitchesPer10cm,
  double? gaugeRowsPer10cm,
}) {
  if (gaugeStitchesPer10cm == null || gaugeRowsPer10cm == null) {
    return DimensionEstimate(
      note: 'Provide gauge (stitches/rows per 10cm) for a dimension estimate.',
    );
  }

  final counts = stitchCountsPerRound(pattern);
  if (counts.isEmpty) {
    return DimensionEstimate(note: 'Pattern has no rounds yet.');
  }

  final maxProduced = counts.map((c) => c.produced).reduce((a, b) => a > b ? a : b);
  final widthCm = (maxProduced / gaugeStitchesPer10cm) * 10;
  final heightCm = (pattern.rounds.length / gaugeRowsPer10cm) * 10;

  return DimensionEstimate(
    widthCm: double.parse(widthCm.toStringAsFixed(1)),
    heightCm: double.parse(heightCm.toStringAsFixed(1)),
  );
}

class PatternReport {
  final int totalStitches;
  final List<RoundStitchCount> perRound;
  final YardageEstimate yardage;
  final DimensionEstimate dimensions;
  PatternReport(this.totalStitches, this.perRound, this.yardage, this.dimensions);
}

PatternReport buildReport(
  CrochetPattern pattern, {
  double? gaugeStitchesPer10cm,
  double? gaugeRowsPer10cm,
}) {
  final perRound = stitchCountsPerRound(pattern);
  final total = perRound.fold(0, (sum, r) => sum + r.produced);
  final yardage = estimateYardage(pattern);
  final dimensions = estimateDimensions(
    pattern,
    gaugeStitchesPer10cm: gaugeStitchesPer10cm,
    gaugeRowsPer10cm: gaugeRowsPer10cm,
  );
  return PatternReport(total, perRound, yardage, dimensions);
}