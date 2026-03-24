import 'package:flutter/material.dart';

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
        final weakNotes = progress.weakestNotes();

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
                      const _Header(),
                      const SizedBox(height: 20),
                      _OverviewCard(progress: progress),
                      const SizedBox(height: 20),
                      _FocusCard(
                        title: weakNotes.isEmpty ? '今日建議' : '近期弱點',
                        body: weakNotes.isEmpty
                            ? '先從白鍵入門開始，熟悉 C 大調七個音的聲音標籤。'
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
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
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
    required this.onPressed,
  });

  final PracticeMode mode;
  final bool enabled;
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
          '先完成一輪練習，這裡就會開始記錄正確率和反應速度。',
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
