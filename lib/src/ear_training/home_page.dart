import 'package:flutter/material.dart';

import '../intro/intro_page.dart';
import 'controller.dart';
import 'note_library.dart';
import 'practice_page.dart';

class EarTrainingHomePage extends StatelessWidget {
  const EarTrainingHomePage({super.key, required this.controller});

  final EarTrainingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final progress = controller.progress;
        final beginnerNotes = progress.beginnerFocusNotes();
        final weakNotes = progress.weakestNotes();
        final recommendedMode = _recommendedMode(
          progress,
          controller.canStartWeakSpotReview,
        );

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF4DE),
                  Color(0xFFE8F4F0),
                  Color(0xFFFDF7ED),
                ],
              ),
            ),
            child: Stack(
              children: [
                const _BackdropOrbs(),
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      _Header(onOpenIntro: () => _openIntro(context)),
                      const SizedBox(height: 20),
                      _OverviewCard(progress: progress),
                      const SizedBox(height: 20),
                      _FocusCard(
                        title: progress.needsNoteBasics
                            ? '今天先熟這幾個音'
                            : weakNotes.isEmpty
                            ? '今日建議'
                            : '近期弱點',
                        body: progress.needsNoteBasics
                            ? '先把 ${beginnerNotes.map((note) => note.label).join('、')} 聽熟、看熟，再進白鍵入門會輕鬆很多。'
                            : weakNotes.isEmpty
                            ? '白鍵七音已經開始建立輪廓，可以繼續拉高穩定度。'
                            : '先複習 ${weakNotes.map((note) => note.label).join('、')}，再進入十二音模式。',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '開始練習',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...PracticeMode.values.map(
                        (mode) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ModeCard(
                            mode: mode,
                            enabled:
                                mode != PracticeMode.weakSpots ||
                                controller.canStartWeakSpotReview,
                            isRecommended: mode == recommendedMode,
                            onPressed: () => _openPractice(context, mode),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '最近練習',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (progress.recentSessions.isEmpty)
                        const _EmptyHistoryCard()
                      else
                        ...progress.recentSessions.map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecentSessionCard(session: session),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPractice(BuildContext context, PracticeMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePage(controller: controller, mode: mode),
      ),
    );
  }

  Future<void> _openIntro(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (pageContext) => IntroPage(
          dismissLabel: '關閉',
          onFinished: () async {
            Navigator.of(pageContext).pop();
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenIntro});

  final VoidCallback onOpenIntro;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yunxu Ear Lab',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '把耳訓拆成每天都做得完的短練習，先建立準確，再追求速度。',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF4D626A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: '查看介紹',
          onPressed: onOpenIntro,
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.progress});

  final ProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '訓練概況',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: '總練習次數',
                    value: '${progress.totalSessions}',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: '整體正確率',
                    value: '${(progress.accuracy * 100).round()}%',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: '平均反應',
                    value: _formatMs(progress.averageResponseMs),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  '七音熟悉度',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress.familiarWhiteKeyCount}/7',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF617179),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: NotePitch.whiteKeys.map((note) {
                return _NoteProgressChip(
                  note: note,
                  stage: progress.learningStageFor(note),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64757A)),
        ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF173A4B),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.enabled,
    required this.isRecommended,
    required this.onPressed,
  });

  final PracticeMode mode;
  final bool enabled;
  final bool isRecommended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFE0F1EC)
                      : const Color(0xFFEAE3D8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  switch (mode) {
                    PracticeMode.noteBasics => Icons.music_note_rounded,
                    PracticeMode.whiteKeys => Icons.piano,
                    PracticeMode.chromatic => Icons.graphic_eq,
                    PracticeMode.weakSpots => Icons.track_changes,
                  },
                  color: enabled
                      ? const Color(0xFF0C7A6B)
                      : const Color(0xFF8B8073),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isRecommended && enabled) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F1EC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '推薦從這裡開始',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: const Color(0xFF0C7A6B),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      enabled ? mode.subtitle : '完成幾輪練習後，這裡會自動解鎖。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF617179),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF9B9388),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          '先從七音認識開始，這裡就會慢慢記錄你的正確率和反應速度。',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF617179)),
        ),
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.mode.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(session.accuracy * 100).round()}% 正確率 · ${_formatMs(session.averageResponseMs)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF617179),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatSessionTime(session.completedAt),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7D8D92)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteProgressChip extends StatelessWidget {
  const _NoteProgressChip({required this.note, required this.stage});

  final NotePitch note;
  final NoteLearningStage stage;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, marker) = switch (stage) {
      NoteLearningStage.unseen => (
        const Color(0xFFF4E7D7),
        const Color(0xFF7A6551),
        '未碰過',
      ),
      NoteLearningStage.practicing => (
        const Color(0xFFFFE7BF),
        const Color(0xFF8A5A12),
        '練習中',
      ),
      NoteLearningStage.familiar => (
        const Color(0xFFDDF3E8),
        const Color(0xFF1C6B4A),
        '已建立',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            marker,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrbs extends StatelessWidget {
  const _BackdropOrbs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -20,
            child: _Orb(size: 180, color: const Color(0x33F4975C)),
          ),
          Positioned(
            top: 280,
            left: -30,
            child: _Orb(size: 160, color: const Color(0x331D8F7A)),
          ),
          Positioned(
            bottom: 40,
            right: -50,
            child: _Orb(size: 220, color: const Color(0x22B3D7CC)),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _formatMs(int milliseconds) {
  if (milliseconds <= 0) {
    return '--';
  }
  return '${(milliseconds / 1000).toStringAsFixed(1)}s';
}

String _formatSessionTime(DateTime completedAt) {
  final hour = completedAt.hour.toString().padLeft(2, '0');
  final minute = completedAt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

PracticeMode _recommendedMode(
  ProgressSnapshot progress,
  bool canStartWeakSpotReview,
) {
  if (progress.needsNoteBasics) {
    return PracticeMode.noteBasics;
  }
  if (progress.familiarWhiteKeyCount < NotePitch.whiteKeys.length) {
    return PracticeMode.whiteKeys;
  }
  if (canStartWeakSpotReview && progress.weakestNotes().isNotEmpty) {
    return PracticeMode.weakSpots;
  }
  return PracticeMode.chromatic;
}
