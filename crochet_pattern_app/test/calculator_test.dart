// Unit tests for the calculator (Section 4.4 testing strategy).
// Run with: flutter test test/calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_pattern_app/models/pattern_models.dart';
import 'package:crochet_pattern_app/calculator/calculator.dart';

const stSc = StitchType(
  id: 'sc', abbreviation: 'sc', name: 'Single Crochet',
  heightFactor: 1.0, yarnConsumptionFactor: 1.0,
);
const stInc = StitchType(
  id: 'inc', abbreviation: 'inc', name: 'Increase',
  heightFactor: 1.0, yarnConsumptionFactor: 1.9,
);
const stDec = StitchType(
  id: 'dec', abbreviation: 'dec', name: 'Decrease',
  heightFactor: 1.0, yarnConsumptionFactor: 1.6,
);

CrochetPattern _patternWithRounds(List<PatternRound> rounds) {
  return CrochetPattern(
    id: 'p1', name: 'Test Pattern',
    yarnWeightCategory: 'worsted', rounds: rounds,
  );
}

void main() {
  group('stitchCountsPerRound', () {
    test('empty pattern returns an empty list, no crash', () {
      final pattern = _patternWithRounds([]);
      expect(stitchCountsPerRound(pattern), isEmpty);
      expect(totalStitchCount(pattern), 0);
    });

    test('single round with 6 sc produces 6, consumes 0 (first round)', () {
      final pattern = _patternWithRounds([
        PatternRound(id: 'r1', roundNumber: 1, blocks: [
          StitchBlock(id: 'b1', stitchType: stSc, repeatCount: 6, sequenceOrder: 0),
        ]),
      ]);
      final counts = stitchCountsPerRound(pattern);
      expect(counts.length, 1);
      expect(counts.first.produced, 6);
      expect(counts.first.consumedFromPrevious, 6);
    });

    test('increase round correctly doubles stitch count', () {
      final pattern = _patternWithRounds([
        PatternRound(id: 'r1', roundNumber: 1, blocks: [
          StitchBlock(id: 'b1', stitchType: stSc, repeatCount: 6, sequenceOrder: 0),
        ]),
        PatternRound(id: 'r2', roundNumber: 2, blocks: [
          StitchBlock(id: 'b2', stitchType: stInc, repeatCount: 6, sequenceOrder: 0),
        ]),
      ]);
      final counts = stitchCountsPerRound(pattern);
      expect(counts[1].consumedFromPrevious, 6);  // 6 inc consumes 6 from prior round
      expect(counts[1].produced, 12);              // 6 inc produces 12
    });

    test('a decrease that over-consumes the previous round throws', () {
      final pattern = _patternWithRounds([
        PatternRound(id: 'r1', roundNumber: 1, blocks: [
          StitchBlock(id: 'b1', stitchType: stSc, repeatCount: 6, sequenceOrder: 0),
        ]),
        PatternRound(id: 'r2', roundNumber: 2, blocks: [
          // 6 decreases would consume 12 stitches, but round 1 only produced 6.
          StitchBlock(id: 'b2', stitchType: stDec, repeatCount: 6, sequenceOrder: 0),
        ]),
      ]);
      expect(() => stitchCountsPerRound(pattern), throwsA(isA<InvalidPatternException>()));
    });

    test('large synthetic pattern (100+ rounds) does not throw or hang', () {
      final rounds = List.generate(120, (i) => PatternRound(
        id: 'r$i', roundNumber: i + 1, blocks: [
          StitchBlock(id: 'b$i', stitchType: stSc, repeatCount: 12, sequenceOrder: 0),
        ],
      ));
      final pattern = _patternWithRounds(rounds);
      final counts = stitchCountsPerRound(pattern);
      expect(counts.length, 120);
      expect(totalStitchCount(pattern), 120 * 12);
    });
  });

  group('estimateYardage', () {
    test('empty pattern yields zero yardage', () {
      final pattern = _patternWithRounds([]);
      final yardage = estimateYardage(pattern);
      expect(yardage.estimatedYards, 0.0);
    });

    test('worsted-weight sc-only pattern matches hand-calculated yardage', () {
      final pattern = _patternWithRounds([
        PatternRound(id: 'r1', roundNumber: 1, blocks: [
          StitchBlock(id: 'b1', stitchType: stSc, repeatCount: 10, sequenceOrder: 0),
        ]),
      ]);
      // 10 stitches * 0.03 baseline * 1.0 factor * 1.0 (worsted) = 0.3 yards
      final yardage = estimateYardage(pattern);
      expect(yardage.estimatedYards, closeTo(0.3, 0.01));
    });
  });

  group('estimateDimensions', () {
    test('no gauge provided returns nulls with an explanatory note', () {
      final pattern = _patternWithRounds([
        PatternRound(id: 'r1', roundNumber: 1, blocks: [
          StitchBlock(id: 'b1', stitchType: stSc, repeatCount: 6, sequenceOrder: 0),
        ]),
      ]);
      final dims = estimateDimensions(pattern);
      expect(dims.widthCm, isNull);
      expect(dims.heightCm, isNull);
      expect(dims.note, isNotNull);
    });

    test('with gauge provided, returns a computed width and height', () {
      final pattern = _patternWithRounds([
        PatternRound(id: 'r1', roundNumber: 1, blocks: [
          StitchBlock(id: 'b1', stitchType: stSc, repeatCount: 20, sequenceOrder: 0),
        ]),
      ]);
      final dims = estimateDimensions(
        pattern, gaugeStitchesPer10cm: 20, gaugeRowsPer10cm: 20,
      );
      expect(dims.widthCm, closeTo(10.0, 0.01));
      expect(dims.heightCm, closeTo(0.5, 0.01));
    });
  });
}