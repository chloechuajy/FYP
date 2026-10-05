// Week 9: displays buildReport() output for the current pattern.
// Gauge fields are plain text inputs for now (not persisted -- see the note
// in calculator.dart about gauge not yet being in the schema).

import 'package:flutter/material.dart';
import '../models/pattern_models.dart';
import '../calculator/calculator.dart';

class ResultsScreen extends StatefulWidget {
  final CrochetPattern pattern;
  const ResultsScreen({super.key, required this.pattern});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _gaugeStitchesController = TextEditingController();
  final _gaugeRowsController = TextEditingController();

  PatternReport? _report;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    setState(() {
      _errorMessage = null;
      _report = null;
    });
    try {
      final report = buildReport(
        widget.pattern,
        gaugeStitchesPer10cm: double.tryParse(_gaugeStitchesController.text),
        gaugeRowsPer10cm: double.tryParse(_gaugeRowsController.text),
      );
      setState(() => _report = report);
    } on InvalidPatternException catch (e) {
      // Surfaced clearly instead of crashing -- this is exactly the R2/4.4
      // "don't silently compute a bad decrease" requirement in action.
      setState(() => _errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pattern Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gaugeStitchesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Gauge: sts / 10cm'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _gaugeRowsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Gauge: rows / 10cm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _recalculate, child: const Text('Recalculate')),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Pattern error: $_errorMessage',
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            if (_report != null) ..._buildReportWidgets(_report!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReportWidgets(PatternReport report) {
    return [
      Text('Total stitches: ${report.totalStitches}',
          style: Theme.of(context).textTheme.titleMedium),
      const Divider(),
      ...report.perRound.map((r) => Text(
          'Round ${r.roundNumber}: ${r.produced} sts (consumed ${r.consumedFromPrevious} from previous)')),
      const SizedBox(height: 16),
      Text('Yardage estimate', style: Theme.of(context).textTheme.titleMedium),
      Text('${report.yardage.estimatedYards} yards '
          '(${report.yardage.estimatedMeters} m, '
          '~${report.yardage.estimatedSkeins} skeins)'),
      const Text('Note: this is an estimate based on average consumption factors, '
          'not a precise measurement.', style: TextStyle(fontStyle: FontStyle.italic)),
      const SizedBox(height: 16),
      Text('Dimension estimate', style: Theme.of(context).textTheme.titleMedium),
      if (report.dimensions.note != null)
        Text(report.dimensions.note!, style: const TextStyle(fontStyle: FontStyle.italic))
      else
        Text('${report.dimensions.widthCm} cm wide x ${report.dimensions.heightCm} cm tall'),
    ];
  }
}