// Hardcoded dummy data, used as a fallback until the real Supabase fetch
// succeeds (and for the very first app launch before any pattern is saved).

import '../models/pattern_models.dart';

const stSingle = StitchType(
  id: 'dummy-sc',
  abbreviation: 'sc',
  name: 'Single Crochet',
  heightFactor: 1.0,
  yarnConsumptionFactor: 1.0,
);

const stIncrease = StitchType(
  id: 'dummy-inc',
  abbreviation: 'inc',
  name: 'Increase (2 sc in same st)',
  heightFactor: 1.0,
  yarnConsumptionFactor: 1.9,
);

const stDecrease = StitchType(
  id: 'dummy-dec',
  abbreviation: 'dec',
  name: 'Decrease (sc2tog)',
  heightFactor: 1.0,
  yarnConsumptionFactor: 1.6,
);

const List<StitchType> dummyStitchTypes = [stSingle, stIncrease, stDecrease];

/// A classic amigurumi sphere opening sequence: 6, 12, 18 stitches.
CrochetPattern buildDummyPattern() {
  return CrochetPattern(
    id: 'dummy-pattern-1',
    name: 'Amigurumi Sphere (sample)',
    hookSizeMm: 3.5,
    yarnWeightCategory: 'worsted',
    rounds: [
      PatternRound(
        id: 'r1',
        roundNumber: 1,
        joinType: 'spiral',
        blocks: [
          StitchBlock(id: 'b1', stitchType: stSingle, repeatCount: 6, sequenceOrder: 0),
        ],
      ),
      PatternRound(
        id: 'r2',
        roundNumber: 2,
        joinType: 'spiral',
        blocks: [
          StitchBlock(id: 'b2', stitchType: stIncrease, repeatCount: 6, sequenceOrder: 0),
        ],
      ),
      PatternRound(
        id: 'r3',
        roundNumber: 3,
        joinType: 'spiral',
        blocks: [
          StitchBlock(id: 'b3', stitchType: stSingle, repeatCount: 1, sequenceOrder: 0),
          StitchBlock(id: 'b4', stitchType: stIncrease, repeatCount: 1, sequenceOrder: 1),
        ],
      ),
    ],
  );
}