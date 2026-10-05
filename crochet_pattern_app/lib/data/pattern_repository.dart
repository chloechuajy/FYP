// Save/load for the patterns -> rounds -> stitch_blocks hierarchy (Objective 4).
// Simplification: savePattern() always INSERTs a new pattern row rather than
// updating in place. Good enough for now -- upsert-by-id can come later.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pattern_models.dart';

class PatternRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> savePattern(CrochetPattern pattern) async {
    final userId = _client.auth.currentUser!.id;

    final patternRow = await _client
        .from('patterns')
        .insert({
          'user_id': userId,
          'name': pattern.name,
          'hook_size_mm': pattern.hookSizeMm,
          'yarn_weight_category': pattern.yarnWeightCategory,
        })
        .select()
        .single();
    final patternId = patternRow['id'] as String;

    for (final round in pattern.rounds) {
      final roundRow = await _client
          .from('rounds')
          .insert({
            'pattern_id': patternId,
            'round_number': round.roundNumber,
            'join_type': round.joinType,
          })
          .select()
          .single();
      final roundId = roundRow['id'] as String;

      if (round.blocks.isNotEmpty) {
        await _client.from('stitch_blocks').insert(
              round.blocks
                  .map((b) => {
                        'round_id': roundId,
                        'stitch_type_id': b.stitchType.id,
                        'repeat_count': b.repeatCount,
                        'sequence_order': b.sequenceOrder,
                      })
                  .toList(),
            );
      }
    }

    return patternId;
  }

  Future<CrochetPattern?> loadMostRecentPattern(
    List<StitchType> stitchTypeLookup,
  ) async {
    final userId = _client.auth.currentUser!.id;

    final patternRows = await _client
        .from('patterns')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if ((patternRows as List).isEmpty) return null;
    final patternRow = patternRows.first as Map<String, dynamic>;
    final patternId = patternRow['id'] as String;

    final roundRows = await _client
        .from('rounds')
        .select()
        .eq('pattern_id', patternId)
        .order('round_number');

    final stitchTypeById = {for (final st in stitchTypeLookup) st.id: st};

    final rounds = <PatternRound>[];
    for (final r in (roundRows as List)) {
      final roundMap = r as Map<String, dynamic>;
      final roundId = roundMap['id'] as String;

      final blockRows = await _client
          .from('stitch_blocks')
          .select()
          .eq('round_id', roundId)
          .order('sequence_order');

      final blocks = (blockRows as List).map((b) {
        final blockMap = b as Map<String, dynamic>;
        final stitchType = stitchTypeById[blockMap['stitch_type_id']];
        if (stitchType == null) {
          throw StateError(
            'Unknown stitch_type_id ${blockMap['stitch_type_id']} -- '
            'was stitchTypeLookup fetched before calling loadMostRecentPattern?',
          );
        }
        return StitchBlock(
          id: blockMap['id'] as String,
          stitchType: stitchType,
          repeatCount: blockMap['repeat_count'] as int,
          sequenceOrder: blockMap['sequence_order'] as int,
        );
      }).toList();

      rounds.add(PatternRound(
        id: roundId,
        roundNumber: roundMap['round_number'] as int,
        joinType: roundMap['join_type'] as String?,
        blocks: blocks,
      ));
    }

    return CrochetPattern(
      id: patternId,
      name: patternRow['name'] as String,
      hookSizeMm: (patternRow['hook_size_mm'] as num?)?.toDouble(),
      yarnWeightCategory: patternRow['yarn_weight_category'] as String?,
      rounds: rounds,
    );
  }
}