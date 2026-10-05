// Dart-side mirror of the Supabase schema (Section 4.1).

class StitchType {
  final String id;
  final String abbreviation;
  final String name;
  final double heightFactor;
  final double yarnConsumptionFactor;

  const StitchType({
    required this.id,
    required this.abbreviation,
    required this.name,
    required this.heightFactor,
    required this.yarnConsumptionFactor,
  });

  /// Builds a StitchType from a Supabase row (a Map<String, dynamic>).
  /// Column names match supabase/migrations/0001_init.sql exactly.
  factory StitchType.fromMap(Map<String, dynamic> map) {
    return StitchType(
      id: map['id'] as String,
      abbreviation: map['abbreviation'] as String,
      name: map['name'] as String,
      heightFactor: (map['height_factor'] as num).toDouble(),
      yarnConsumptionFactor: (map['yarn_consumption_factor'] as num).toDouble(),
    );
  }
}

class StitchBlock {
  String id;
  StitchType stitchType;
  int repeatCount;
  int sequenceOrder;

  StitchBlock({
    required this.id,
    required this.stitchType,
    required this.repeatCount,
    required this.sequenceOrder,
  });

  String get label => '${stitchType.abbreviation} x$repeatCount';
}

class PatternRound {
  String id;
  int roundNumber;
  String? joinType;
  List<StitchBlock> blocks;

  PatternRound({
    required this.id,
    required this.roundNumber,
    this.joinType,
    required this.blocks,
  });

  int get stitchCount => blocks.fold(0, (sum, b) => sum + b.repeatCount);
}

class CrochetPattern {
  String id;
  String name;
  double? hookSizeMm;
  String? yarnWeightCategory;
  List<PatternRound> rounds;

  CrochetPattern({
    required this.id,
    required this.name,
    this.hookSizeMm,
    this.yarnWeightCategory,
    required this.rounds,
  });
}