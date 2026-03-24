import 'dart:async';

import 'package:flutter/foundation.dart';

import 'note_library.dart';
import 'note_player.dart';
import 'progress_repository.dart';

class EarTrainingController extends ChangeNotifier {
  EarTrainingController({
    required ProgressRepository repository,
    required NotePlayer player,
  }) : _repository = repository,
       _player = player;

  final ProgressRepository _repository;
  final NotePlayer _player;

  ProgressSnapshot _progress = const ProgressSnapshot.empty();
  bool _isLoaded = false;
  bool _isPlaying = false;

  ProgressSnapshot get progress => _progress;
  bool get isLoaded => _isLoaded;
  bool get isPlaying => _isPlaying;

  bool get canStartWeakSpotReview =>
      _progress.noteStats.values.where((stat) => stat.attempts > 0).length >= 4;

  Future<void> load() async {
    _progress = await _repository.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> play(NotePitch note) async {
    _isPlaying = true;
    notifyListeners();

    try {
      await _player.play(note);
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> recordSession(PracticeSessionResult result) async {
    _progress = _progress.merge(result);
    notifyListeners();
    await _repository.save(_progress);
  }

  Future<void> close() async {
    unawaited(_player.dispose());
    super.dispose();
  }
}
