import 'package:flutter_test/flutter_test.dart';
import 'package:yunxu_absolute_pitch/src/ear_training/note_library.dart';

void main() {
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
}
