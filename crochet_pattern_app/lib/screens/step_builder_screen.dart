import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pattern_models.dart';
import '../data/dummy_data.dart';
import '../data/pattern_repository.dart';
import 'results_screen.dart';

class StepBuilderScreen extends StatefulWidget {
  const StepBuilderScreen({super.key});

  @override
  State<StepBuilderScreen> createState() => _StepBuilderScreenState();
}

class _StepBuilderScreenState extends State<StepBuilderScreen> {
  late CrochetPattern pattern;
  final _repository = PatternRepository();

  List<StitchType> availableStitchTypes = dummyStitchTypes;
  bool _saving = false;
  bool _loadingPattern = false;

  @override
  void initState() {
    super.initState();
    pattern = buildDummyPattern();
    _loadStitchTypesFromSupabase();
  }

  Future<void> _loadStitchTypesFromSupabase() async {
    try {
      final rows = await Supabase.instance.client.from('stitch_types').select();
      final fetched = (rows as List)
          .map((row) => StitchType.fromMap(row as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      if (fetched.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected, but stitch_types table is empty — did the seed run?')),
        );
      } else {
        setState(() => availableStitchTypes = fetched);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${fetched.length} stitch types from Supabase ✅')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supabase fetch failed, using dummy data instead: $e')),
      );
    }
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      final id = await _repository.savePattern(pattern);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ✅ (pattern id: ${id.substring(0, 8)}...)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleLoad() async {
    setState(() => _loadingPattern = true);
    try {
      final loaded = await _repository.loadMostRecentPattern(availableStitchTypes);
      if (!mounted) return;
      if (loaded == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved pattern found yet — try Save first.')),
        );
      } else {
        setState(() => pattern = loaded);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loaded most recent saved pattern ✅')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _loadingPattern = false);
    }
  }

  void _openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsScreen(pattern: pattern)),
    );
  }

  void _reorderRounds(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final round = pattern.rounds.removeAt(oldIndex);
      pattern.rounds.insert(newIndex, round);
      for (var i = 0; i < pattern.rounds.length; i++) {
        pattern.rounds[i].roundNumber = i + 1;
      }
    });
  }

  void _reorderBlocksInRound(PatternRound round, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final block = round.blocks.removeAt(oldIndex);
      round.blocks.insert(newIndex, block);
      for (var i = 0; i < round.blocks.length; i++) {
        round.blocks[i].sequenceOrder = i;
      }
    });
  }

  Future<void> _addBlockToRound(PatternRound round) async {
    final chosen = await showDialog<StitchType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a stitch'),
        children: availableStitchTypes.map((st) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, st),
            child: Text('${st.abbreviation} — ${st.name}'),
          );
        }).toList(),
      ),
    );

    if (chosen == null) return;

    setState(() {
      round.blocks.add(StitchBlock(
        id: 'new-${DateTime.now().microsecondsSinceEpoch}',
        stitchType: chosen,
        repeatCount: 1,
        sequenceOrder: round.blocks.length,
      ));
    });
  }

  void _removeBlock(PatternRound round, StitchBlock block) {
    setState(() => round.blocks.remove(block));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pattern.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'View pattern report',
            onPressed: _openResults,
          ),
          IconButton(
            icon: _loadingPattern
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.folder_open),
            tooltip: 'Load most recent saved pattern',
            onPressed: _loadingPattern ? null : _handleLoad,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            tooltip: 'Save pattern',
            onPressed: _saving ? null : _handleSave,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pattern.rounds.length,
        onReorder: _reorderRounds,
        itemBuilder: (context, index) {
          final round = pattern.rounds[index];
          return Card(
            key: ValueKey(round.id),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Round ${round.roundNumber}',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('${round.stitchCount} sts',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const Divider(),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: round.blocks.length,
                    onReorder: (oldIndex, newIndex) =>
                        _reorderBlocksInRound(round, oldIndex, newIndex),
                    itemBuilder: (context, i) {
                      final block = round.blocks[i];
                      return ListTile(
                        key: ValueKey(block.id),
                        dense: true,
                        leading: const Icon(Icons.drag_handle),
                        title: Text(block.label),
                        subtitle: Text(block.stitchType.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeBlock(round, block),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _addBlockToRound(round),
                      icon: const Icon(Icons.add),
                      label: const Text('Add stitch'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}