import 'dart:math';

enum PracticeMode { whiteKeys, chromatic, weakSpots }

extension PracticeModePresentation on PracticeMode {
  String get title => switch (this) {
    PracticeMode.whiteKeys => '白鍵入門',
    PracticeMode.chromatic => '十二音挑戰',
    PracticeMode.weakSpots => '弱點加強',
  };

  String get subtitle => switch (this) {
    PracticeMode.whiteKeys => '從 C 大調七個音開始，建立基本聽感標籤。',
    PracticeMode.chromatic => '擴展到 12 個半音，開始練真實辨識速度。',
    PracticeMode.weakSpots => '把最近最容易錯的音拉出來密集複習。',
  };

  int get questionCount => switch (this) {
    PracticeMode.whiteKeys => 10,
    PracticeMode.chromatic => 12,
    PracticeMode.weakSpots => 12,
  };

  List<NotePitch> answerOptions(ProgressSnapshot progress) => switch (this) {
    PracticeMode.whiteKeys => NotePitch.whiteKeys,
    PracticeMode.chromatic => NotePitch.chromatic,
    PracticeMode.weakSpots => NotePitch.chromatic,
  };

  List<NotePitch> questionPool(ProgressSnapshot progress) {
    switch (this) {
      case PracticeMode.whiteKeys:
        return NotePitch.whiteKeys;
      case PracticeMode.chromatic:
        return NotePitch.chromatic;
      case PracticeMode.weakSpots:
        final weakCandidates = progress.weakestNotes(limit: 5);
        if (weakCandidates.length >= 4) {
          return weakCandidates;
        }
        return NotePitch.chromatic;
    }
  }
}

class NotePitch {
  const NotePitch({
    required this.id,
    required this.label,
    required this.frequency,
    required this.assetName,
    required this.isWhiteKey,
  });

  final String id;
  final String label;
  final double frequency;
  final String assetName;
  final bool isWhiteKey;

  static const chromatic = <NotePitch>[
    NotePitch(
      id: 'c4',
      label: 'C',
      frequency: 261.63,
      assetName: 'audio/notes/c4.wav',
      isWhiteKey: true,
    ),
    NotePitch(
      id: 'cs4',
      label: 'C#',
      frequency: 277.18,
      assetName: 'audio/notes/cs4.wav',
      isWhiteKey: false,
    ),
    NotePitch(
      id: 'd4',
      label: 'D',
      frequency: 293.66,
      assetName: 'audio/notes/d4.wav',
      isWhiteKey: true,
    ),
    NotePitch(
      id: 'ds4',
      label: 'D#',
      frequency: 311.13,
      assetName: 'audio/notes/ds4.wav',
      isWhiteKey: false,
    ),
    NotePitch(
      id: 'e4',
      label: 'E',
      frequency: 329.63,
      assetName: 'audio/notes/e4.wav',
      isWhiteKey: true,
    ),
    NotePitch(
      id: 'f4',
      label: 'F',
      frequency: 349.23,
      assetName: 'audio/notes/f4.wav',
      isWhiteKey: true,
    ),
    NotePitch(
      id: 'fs4',
      label: 'F#',
      frequency: 369.99,
      assetName: 'audio/notes/fs4.wav',
      isWhiteKey: false,
    ),
    NotePitch(
      id: 'g4',
      label: 'G',
      frequency: 392.00,
      assetName: 'audio/notes/g4.wav',
      isWhiteKey: true,
    ),
    NotePitch(
      id: 'gs4',
      label: 'G#',
      frequency: 415.30,
      assetName: 'audio/notes/gs4.wav',
      isWhiteKey: false,
    ),
    NotePitch(
      id: 'a4',
      label: 'A',
      frequency: 440.00,
      assetName: 'audio/notes/a4.wav',
      isWhiteKey: true,
    ),
    NotePitch(
      id: 'as4',
      label: 'A#',
      frequency: 466.16,
      assetName: 'audio/notes/as4.wav',
      isWhiteKey: false,
    ),
    NotePitch(
      id: 'b4',
      label: 'B',
      frequency: 493.88,
      assetName: 'audio/notes/b4.wav',
      isWhiteKey: true,
    ),
  ];

  static final whiteKeys = chromatic.where((note) => note.isWhiteKey).toList();
  static final byId = {for (final note in chromatic) note.id: note};
}

class PracticeSessionBlueprint {
  PracticeSessionBlueprint({
    required this.mode,
    required this.answerOptions,
    required this.targets,
  });

  final PracticeMode mode;
  final List<NotePitch> answerOptions;
  final List<NotePitch> targets;

  static PracticeSessionBlueprint generate({
    required PracticeMode mode,
    required ProgressSnapshot progress,
    Random? random,
  }) {
    final rng = random ?? Random();
    final pool = mode.questionPool(progress);
    final answerOptions = mode.answerOptions(progress);
    final targets = <NotePitch>[];

    for (var index = 0; index < mode.questionCount; index++) {
      targets.add(
        _pickWeighted(
          pool: pool,
          progress: progress,
          previous: targets.isEmpty ? null : targets.last,
          random: rng,
        ),
      );
    }

    return PracticeSessionBlueprint(
      mode: mode,
      answerOptions: answerOptions,
      targets: targets,
    );
  }

  static NotePitch _pickWeighted({
    required List<NotePitch> pool,
    required ProgressSnapshot progress,
    required Random random,
    NotePitch? previous,
  }) {
    final weighted = <({NotePitch note, double weight})>[];
    var totalWeight = 0.0;

    for (final note in pool) {
      final stat = progress.noteStats[note.id];
      final attempts = stat?.attempts ?? 0;
      final accuracy = stat?.accuracy ?? 0;
      var weight = attempts == 0 ? 1.7 : 1.0 + ((1 - accuracy) * 2.6);

      if (previous != null && previous.id == note.id && pool.length > 1) {
        weight *= 0.32;
      }

      totalWeight += weight;
      weighted.add((note: note, weight: weight));
    }

    var cursor = random.nextDouble() * totalWeight;

    for (final entry in weighted) {
      cursor -= entry.weight;
      if (cursor <= 0) {
        return entry.note;
      }
    }

    return weighted.last.note;
  }
}

class SessionAttempt {
  const SessionAttempt({
    required this.targetNoteId,
    required this.selectedNoteId,
    required this.responseMs,
  });

  final String targetNoteId;
  final String selectedNoteId;
  final int responseMs;

  bool get isCorrect => targetNoteId == selectedNoteId;

  NotePitch get targetNote => NotePitch.byId[targetNoteId]!;
  NotePitch get selectedNote => NotePitch.byId[selectedNoteId]!;
}

class PracticeSessionResult {
  const PracticeSessionResult({
    required this.mode,
    required this.attempts,
    required this.completedAt,
  });

  final PracticeMode mode;
  final List<SessionAttempt> attempts;
  final DateTime completedAt;

  int get totalQuestions => attempts.length;
  int get correctAnswers =>
      attempts.where((attempt) => attempt.isCorrect).length;

  double get accuracy =>
      attempts.isEmpty ? 0 : correctAnswers / attempts.length;

  int get averageResponseMs => attempts.isEmpty
      ? 0
      : attempts
                .map((attempt) => attempt.responseMs)
                .reduce((left, right) => left + right) ~/
            attempts.length;

  List<NotePitch> weakestTargets({int limit = 3}) {
    final grouped = <String, ({int attempts, int correct})>{};
    for (final attempt in attempts) {
      final current =
          grouped[attempt.targetNoteId] ?? (attempts: 0, correct: 0);
      grouped[attempt.targetNoteId] = (
        attempts: current.attempts + 1,
        correct: current.correct + (attempt.isCorrect ? 1 : 0),
      );
    }

    final ranked = grouped.entries.toList()
      ..sort((left, right) {
        final leftAccuracy = left.value.correct / left.value.attempts;
        final rightAccuracy = right.value.correct / right.value.attempts;
        final byAccuracy = leftAccuracy.compareTo(rightAccuracy);
        if (byAccuracy != 0) {
          return byAccuracy;
        }
        return right.value.attempts.compareTo(left.value.attempts);
      });

    return ranked
        .take(limit)
        .map((entry) => NotePitch.byId[entry.key]!)
        .toList();
  }
}

class NotePerformance {
  const NotePerformance({
    required this.attempts,
    required this.correct,
    required this.totalResponseMs,
  });

  const NotePerformance.empty()
    : attempts = 0,
      correct = 0,
      totalResponseMs = 0;

  final int attempts;
  final int correct;
  final int totalResponseMs;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  int get averageResponseMs => attempts == 0 ? 0 : totalResponseMs ~/ attempts;

  NotePerformance register(SessionAttempt attempt) {
    return NotePerformance(
      attempts: attempts + 1,
      correct: correct + (attempt.isCorrect ? 1 : 0),
      totalResponseMs: totalResponseMs + attempt.responseMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attempts': attempts,
      'correct': correct,
      'totalResponseMs': totalResponseMs,
    };
  }

  factory NotePerformance.fromJson(Map<String, dynamic> json) {
    return NotePerformance(
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      totalResponseMs: (json['totalResponseMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionSummary {
  const SessionSummary({
    required this.mode,
    required this.accuracy,
    required this.averageResponseMs,
    required this.completedAt,
  });

  final PracticeMode mode;
  final double accuracy;
  final int averageResponseMs;
  final DateTime completedAt;

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'accuracy': accuracy,
      'averageResponseMs': averageResponseMs,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      mode: PracticeMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => PracticeMode.whiteKeys,
      ),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      averageResponseMs: (json['averageResponseMs'] as num?)?.toInt() ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.totalSessions,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.totalResponseMs,
    required this.noteStats,
    required this.recentSessions,
  });

  const ProgressSnapshot.empty()
    : totalSessions = 0,
      totalAttempts = 0,
      correctAttempts = 0,
      totalResponseMs = 0,
      noteStats = const {},
      recentSessions = const [];

  final int totalSessions;
  final int totalAttempts;
  final int correctAttempts;
  final int totalResponseMs;
  final Map<String, NotePerformance> noteStats;
  final List<SessionSummary> recentSessions;

  double get accuracy =>
      totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;

  int get averageResponseMs =>
      totalAttempts == 0 ? 0 : totalResponseMs ~/ totalAttempts;

  List<NotePitch> weakestNotes({int limit = 3}) {
    final ranked =
        noteStats.entries.where((entry) => entry.value.attempts > 0).toList()
          ..sort((left, right) {
            final leftWeakness =
                (1 - left.value.accuracy) * left.value.attempts;
            final rightWeakness =
                (1 - right.value.accuracy) * right.value.attempts;
            final byWeakness = rightWeakness.compareTo(leftWeakness);
            if (byWeakness != 0) {
              return byWeakness;
            }
            return left.value.accuracy.compareTo(right.value.accuracy);
          });

    return ranked
        .take(limit)
        .map((entry) => NotePitch.byId[entry.key]!)
        .toList();
  }

  ProgressSnapshot merge(PracticeSessionResult result) {
    final updatedStats = Map<String, NotePerformance>.from(noteStats);

    for (final attempt in result.attempts) {
      final current =
          updatedStats[attempt.targetNoteId] ?? const NotePerformance.empty();
      updatedStats[attempt.targetNoteId] = current.register(attempt);
    }

    final summaries = [
      SessionSummary(
        mode: result.mode,
        accuracy: result.accuracy,
        averageResponseMs: result.averageResponseMs,
        completedAt: result.completedAt,
      ),
      ...recentSessions,
    ].take(6).toList();

    return ProgressSnapshot(
      totalSessions: totalSessions + 1,
      totalAttempts: totalAttempts + result.totalQuestions,
      correctAttempts: correctAttempts + result.correctAnswers,
      totalResponseMs:
          totalResponseMs +
          result.attempts.fold<int>(
            0,
            (sum, attempt) => sum + attempt.responseMs,
          ),
      noteStats: updatedStats,
      recentSessions: summaries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'totalResponseMs': totalResponseMs,
      'noteStats': {
        for (final entry in noteStats.entries) entry.key: entry.value.toJson(),
      },
      'recentSessions': recentSessions
          .map((summary) => summary.toJson())
          .toList(),
    };
  }

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) {
    final noteStatsJson =
        json['noteStats'] as Map<String, dynamic>? ?? const {};
    final sessionsJson = json['recentSessions'] as List<dynamic>? ?? const [];

    return ProgressSnapshot(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      correctAttempts: (json['correctAttempts'] as num?)?.toInt() ?? 0,
      totalResponseMs: (json['totalResponseMs'] as num?)?.toInt() ?? 0,
      noteStats: {
        for (final entry in noteStatsJson.entries)
          entry.key: NotePerformance.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
      recentSessions: sessionsJson
          .map(
            (summary) => SessionSummary.fromJson(
              Map<String, dynamic>.from(summary as Map),
            ),
          )
          .toList(),
    );
  }
}
