import 'package:flutter_test/flutter_test.dart';
import 'package:yunxu_absolute_pitch/src/ear_training/note_library.dart';

void main() {
  test('note basics starts from three anchor white keys', () {
    const progress = ProgressSnapshot.empty();

    final session = PracticeSessionBlueprint.generate(
      mode: PracticeMode.noteBasics,
      progress: progress,
    );

    expect(session.answerOptions.map((note) => note.id).toList(), [
      'c4',
      'f4',
      'g4',
    ]);
    expect(session.targets, isNotEmpty);
    expect(session.targets.every((note) => note.isWhiteKey), isTrue);
  });

  test('white key session only includes white-key targets', () {
    const progress = ProgressSnapshot.empty();

    final session = PracticeSessionBlueprint.generate(
      mode: PracticeMode.whiteKeys,
      progress: progress,
    );

    expect(session.targets, isNotEmpty);
    expect(session.targets.every((note) => note.isWhiteKey), isTrue);
    expect(session.answerOptions.length, 7);
  });

  test('progress merge accumulates totals and note stats', () {
    final result = PracticeSessionResult(
      mode: PracticeMode.chromatic,
      completedAt: DateTime(2026, 3, 24, 22, 0),
      attempts: const [
        SessionAttempt(
          targetNoteId: 'c4',
          selectedNoteId: 'c4',
          responseMs: 800,
        ),
        SessionAttempt(
          targetNoteId: 'd4',
          selectedNoteId: 'e4',
          responseMs: 1500,
        ),
      ],
    );

    final merged = const ProgressSnapshot.empty().merge(result);

    expect(merged.totalSessions, 1);
    expect(merged.totalAttempts, 2);
    expect(merged.correctAttempts, 1);
    expect(merged.noteStats['c4']?.correct, 1);
    expect(merged.noteStats['d4']?.attempts, 1);
  });

  test('beginner focus notes prioritize unseen white keys', () {
    const snapshot = ProgressSnapshot(
      totalSessions: 2,
      totalAttempts: 8,
      correctAttempts: 6,
      totalResponseMs: 6400,
      noteStats: {
        'c4': NotePerformance(attempts: 3, correct: 3, totalResponseMs: 1800),
        'f4': NotePerformance(attempts: 3, correct: 3, totalResponseMs: 1800),
        'g4': NotePerformance(attempts: 1, correct: 0, totalResponseMs: 1200),
      },
      recentSessions: [],
    );

    expect(snapshot.beginnerFocusNotes().map((note) => note.id).toList(), [
      'd4',
      'e4',
      'a4',
    ]);
    expect(snapshot.needsNoteBasics, isTrue);
  });
}
