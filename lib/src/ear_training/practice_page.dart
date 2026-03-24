import 'package:flutter/material.dart';

import 'controller.dart';
import 'note_library.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key, required this.controller, required this.mode});

  final EarTrainingController controller;
  final PracticeMode mode;

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late PracticeSessionBlueprint _session;
  final Stopwatch _stopwatch = Stopwatch();
  final List<SessionAttempt> _attempts = [];

  var _currentIndex = 0;
  var _isAnswerLocked = false;
  var _isSaving = false;
  String? _selectedNoteId;
  String? _feedback;
  bool? _lastAnswerCorrect;
  PracticeSessionResult? _result;

  NotePitch get _currentTarget => _session.targets[_currentIndex];

  @override
  void initState() {
    super.initState();
    _startSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _replayCurrentNote();
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _startSession() {
    _session = PracticeSessionBlueprint.generate(
      mode: widget.mode,
      progress: widget.controller.progress,
    );
    _attempts.clear();
    _currentIndex = 0;
    _selectedNoteId = null;
    _feedback = null;
    _lastAnswerCorrect = null;
    _result = null;
    _isAnswerLocked = false;
    _isSaving = false;
    _stopwatch
      ..reset()
      ..start();
  }

  Future<void> _replayCurrentNote() async {
    if (_result != null) {
      return;
    }
    await widget.controller.play(_currentTarget);
  }

  Future<void> _submitAnswer(NotePitch selected) async {
    if (_isAnswerLocked || _result != null) {
      return;
    }

    final attempt = SessionAttempt(
      targetNoteId: _currentTarget.id,
      selectedNoteId: selected.id,
      responseMs: _stopwatch.elapsedMilliseconds.clamp(1, 99999),
    );

    _stopwatch.stop();

    setState(() {
      _isAnswerLocked = true;
      _selectedNoteId = selected.id;
      _lastAnswerCorrect = attempt.isCorrect;
      _feedback = attempt.isCorrect
          ? '答對了，這題是 ${_currentTarget.label}'
          : '這題是 ${_currentTarget.label}，你選了 ${selected.label}';
      _attempts.add(attempt);
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) {
      return;
    }

    if (_attempts.length == _session.targets.length) {
      await _finishSession();
      return;
    }

    setState(() {
      _currentIndex += 1;
      _isAnswerLocked = false;
      _selectedNoteId = null;
      _feedback = null;
      _lastAnswerCorrect = null;
      _stopwatch
        ..reset()
        ..start();
    });

    await _replayCurrentNote();
  }

  Future<void> _finishSession() async {
    final result = PracticeSessionResult(
      mode: widget.mode,
      attempts: List.unmodifiable(_attempts),
      completedAt: DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    await widget.controller.recordSession(result);

    if (!mounted) {
      return;
    }

    setState(() {
      _result = result;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF173A4B), Color(0xFF0F6B66), Color(0xFFF8F1E5)],
            stops: [0.0, 0.34, 0.34],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _result == null
                ? _PracticeView(
                    key: const ValueKey('practice'),
                    session: _session,
                    currentIndex: _currentIndex,
                    currentTarget: _currentTarget,
                    selectedNoteId: _selectedNoteId,
                    feedback: _feedback,
                    lastAnswerCorrect: _lastAnswerCorrect,
                    controller: widget.controller,
                    onReplay: _replayCurrentNote,
                    onChoose: _submitAnswer,
                    isAnswerLocked: _isAnswerLocked,
                  )
                : _ResultView(
                    key: const ValueKey('result'),
                    result: _result!,
                    isSaving: _isSaving,
                    onRetry: () {
                      setState(() {
                        _startSession();
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _replayCurrentNote();
                      });
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _PracticeView extends StatelessWidget {
  const _PracticeView({
    super.key,
    required this.session,
    required this.currentIndex,
    required this.currentTarget,
    required this.selectedNoteId,
    required this.feedback,
    required this.lastAnswerCorrect,
    required this.controller,
    required this.onReplay,
    required this.onChoose,
    required this.isAnswerLocked,
  });

  final PracticeSessionBlueprint session;
  final int currentIndex;
  final NotePitch currentTarget;
  final String? selectedNoteId;
  final String? feedback;
  final bool? lastAnswerCorrect;
  final EarTrainingController controller;
  final Future<void> Function() onReplay;
  final Future<void> Function(NotePitch selected) onChoose;
  final bool isAnswerLocked;

  @override
  Widget build(BuildContext context) {
    final progressValue = (currentIndex + 1) / session.targets.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
            const Spacer(),
            Text(
              session.mode.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          '第 ${currentIndex + 1} / ${session.targets.length} 題',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '先聽音，再選出正確音名。這輪會優先抽出你比較不穩的音。',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: progressValue,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF9BF73)),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '播放題目音',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  '可重播，不限次數。目標是越聽越快、越判越準。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF607179),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: FilledButton(
                    onPressed: onReplay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF173A4B),
                      shape: const CircleBorder(),
                    ),
                    child: controller.isPlaying
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.volume_up_rounded, size: 54),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: feedback == null
              ? const SizedBox(height: 58)
              : Container(
                  key: ValueKey(feedback),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: (lastAnswerCorrect ?? false)
                        ? const Color(0xFFDDF3E8)
                        : const Color(0xFFFCE3D6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (lastAnswerCorrect ?? false)
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: (lastAnswerCorrect ?? false)
                            ? const Color(0xFF167E55)
                            : const Color(0xFFB2512F),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feedback!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF29404A),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: session.answerOptions.map((note) {
            final isSelected = selectedNoteId == note.id;
            final isCorrectReveal =
                isAnswerLocked && currentTarget.id == note.id && !isSelected;
            final background = note.isWhiteKey
                ? const Color(0xFFFFFBF4)
                : const Color(0xFF243A45);
            final foreground = note.isWhiteKey
                ? const Color(0xFF23353D)
                : Colors.white;

            return SizedBox(
              width: _buttonWidthFor(context),
              child: FilledButton(
                onPressed: isAnswerLocked ? null : () => onChoose(note),
                style: FilledButton.styleFrom(
                  backgroundColor: isSelected
                      ? (note.isWhiteKey
                            ? const Color(0xFFF7C37B)
                            : const Color(0xFF40697A))
                      : background,
                  foregroundColor: foreground,
                  disabledBackgroundColor: isCorrectReveal
                      ? const Color(0xFFBEE8D6)
                      : background.withValues(alpha: 0.96),
                  disabledForegroundColor: isCorrectReveal
                      ? const Color(0xFF114A39)
                      : foreground.withValues(alpha: 0.92),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  note.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.result,
    required this.isSaving,
    required this.onRetry,
  });

  final PracticeSessionResult result;
  final bool isSaving;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final weakNotes = result.weakestTargets();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Spacer(),
            Text(
              '本輪結果',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${(result.accuracy * 100).round()}%',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF173A4B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '整體正確率',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF617179),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _ResultStat(
                        label: '答對題數',
                        value:
                            '${result.correctAnswers}/${result.totalQuestions}',
                      ),
                    ),
                    Expanded(
                      child: _ResultStat(
                        label: '平均反應',
                        value: _formatMs(result.averageResponseMs),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '這輪最值得複習',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (weakNotes.isEmpty)
                  Text(
                    '這輪每個音都答得不錯，接著可以直接再跑一輪。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF617179),
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: weakNotes.map((note) {
                      return Chip(
                        label: Text(note.label),
                        backgroundColor: const Color(0xFFF4E4D2),
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5E4333),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : onRetry,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: const Color(0xFF173A4B),
          ),
          child: Text(
            isSaving ? '儲存中...' : '再練一次',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            side: const BorderSide(color: Colors.white70),
            foregroundColor: Colors.white,
          ),
          child: Text(
            '回首頁',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF617179)),
        ),
      ],
    );
  }
}

double _buttonWidthFor(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width - 52;
  const columns = 4;
  return (width - ((columns - 1) * 12)) / columns;
}

String _formatMs(int milliseconds) {
  return '${(milliseconds / 1000).toStringAsFixed(1)}s';
}
