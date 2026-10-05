import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/step_builder_screen.dart';

// TODO: move these to a config file (e.g. loaded via --dart-define or an
// untracked secrets.dart) before pushing this to a public GitHub repo.
const supabaseUrl = 'https://hxaeqptzryujfgbxbksf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4YWVxcHR6cnl1amZnYnhia3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzMzgxMjUsImV4cCI6MjEwMzkxNDEyNX0.u8xgGw90Gg56RZq7PAU3mChAS1rwuBDviz_v9RcqSiA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  final client = Supabase.instance.client;
  if (client.auth.currentSession == null) {
    await client.auth.signInAnonymously();
  }

  runApp(const StitchLogicApp());
}

class StitchLogicApp extends StatelessWidget {
  const StitchLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StitchLogic',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const StepBuilderScreen(),
    );
  }
}