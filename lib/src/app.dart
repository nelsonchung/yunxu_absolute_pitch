import 'dart:async';

import 'package:flutter/material.dart';

import 'ear_training/controller.dart';
import 'ear_training/home_page.dart';
import 'ear_training/note_player.dart';
import 'ear_training/progress_repository.dart';

class EarTrainingApp extends StatefulWidget {
  const EarTrainingApp({super.key});

  @override
  State<EarTrainingApp> createState() => _EarTrainingAppState();
}

class _EarTrainingAppState extends State<EarTrainingApp> {
  late final EarTrainingController _controller;
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _controller = EarTrainingController(
      repository: ProgressRepository(),
      player: NotePlayer(),
    );
    _bootstrap = _controller.load();
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yunxu Ear Lab',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: FutureBuilder<void>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _BootScreen();
          }

          return EarTrainingHomePage(controller: _controller);
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF0C7A6B);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        primary: const Color(0xFF0C7A6B),
        secondary: const Color(0xFFF4975C),
        surface: const Color(0xFFFFFAF2),
        surfaceContainer: const Color(0xFFF6EFE4),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFAF2),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF20313A),
        displayColor: const Color(0xFF20313A),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.82),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4DE), Color(0xFFE2F2EE)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 5),
              ),
              SizedBox(height: 24),
              Text(
                '準備耳訓練習中',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
