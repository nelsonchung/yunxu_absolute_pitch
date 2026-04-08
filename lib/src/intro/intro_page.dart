import 'package:flutter/material.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({
    super.key,
    required this.onFinished,
    this.dismissLabel = '略過',
  });

  final Future<void> Function() onFinished;
  final String dismissLabel;

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  static const _sections = [
    _IntroSectionData(
      tabLabel: '怎麼開始',
      badge: '先建立基準',
      title: '每天 3 到 5 分鐘，先把音名和聲音對起來',
      description: '先聽題目音，再選正確音名。每題都可以重播，讓耳朵先熟悉差異。',
      panelTitle: '一輪練習流程',
      panelItems: ['播放題目音', '點選你認為正確的音名', '立即看到答案與回饋'],
      accent: Color(0xFF0C7A6B),
      icon: Icons.play_circle_fill_rounded,
    ),
    _IntroSectionData(
      tabLabel: '練習模式',
      badge: '循序展開',
      title: '練習模式會跟著你的熟悉度逐步解鎖',
      description: '先從幾個錨點音開始，再擴展到白鍵、十二音，最後回頭補強弱點。',
      panelTitle: '目前內建的模式',
      panelItems: [
        '音名入門：先熟 C、F、G',
        '白鍵練習：建立七音輪廓',
        '十二音挑戰：擴展到全音域',
        '弱點複習：回頭加強容易錯的音',
      ],
      accent: Color(0xFFF4975C),
      icon: Icons.layers_rounded,
    ),
    _IntroSectionData(
      tabLabel: '小提醒',
      badge: '先求準，再求快',
      title: '不用搶快，先把每個音的差異聽清楚',
      description: '如果聽不出來就先重播。答對率穩定後，速度會跟著自然上來。',
      panelTitle: '練習時的小習慣',
      panelItems: ['短時間反覆練，比偶爾練很久更有效', '答錯的音會變成下一輪的重點', '看到回饋時，順便記住正確音名'],
      accent: Color(0xFF173A4B),
      icon: Icons.lightbulb_rounded,
    ),
  ];

  final PageController _pageController = PageController();
  var _currentIndex = 0;
  var _isCompleting = false;

  bool get _isLastPage => _currentIndex == _sections.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    await widget.onFinished();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCompleting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4DE), Color(0xFFE6F4EE), Color(0xFFFFFAF2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    TextButton(
                      key: const Key('intro-dismiss-button'),
                      onPressed: _isCompleting ? null : _finish,
                      child: Text(widget.dismissLabel),
                    ),
                    Expanded(
                      child: Text(
                        '使用介紹',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _sections.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _IntroSlide(section: _sections[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '說明分頁',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(_sections.length, (index) {
                        final section = _sections[index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == _sections.length - 1 ? 0 : 8,
                            ),
                            child: _SectionTab(
                              key: Key('intro-tab-$index'),
                              label: section.tabLabel,
                              isSelected: index == _currentIndex,
                              accent: section.accent,
                              onTap: () => _goToPage(index),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_sections.length, (index) {
                        final isSelected = index == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isSelected ? 24 : 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _sections[index].accent
                                : const Color(0xFFD2C8BA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('intro-previous-button'),
                            onPressed: _currentIndex == 0 || _isCompleting
                                ? null
                                : () => _goToPage(_currentIndex - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('上一頁'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            key: Key(
                              _isLastPage
                                  ? 'intro-finish-button'
                                  : 'intro-next-button',
                            ),
                            onPressed: _isCompleting
                                ? null
                                : _isLastPage
                                ? _finish
                                : () => _goToPage(_currentIndex + 1),
                            icon: Icon(
                              _isLastPage
                                  ? Icons.flag_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(
                              _isLastPage
                                  ? (_isCompleting ? '處理中...' : '開始練習')
                                  : '下一頁',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.section});

  final _IntroSectionData section;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: section.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            section.badge,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: section.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          section.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          section.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF56676D),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: section.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(section.icon, color: section.accent, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                section.panelTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              ...section.panelItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: section.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: section.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF314149),
                                height: 1.45,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accent : const Color(0xFFE2D8CB),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? accent : const Color(0xFF6B7A80),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IntroSectionData {
  const _IntroSectionData({
    required this.tabLabel,
    required this.badge,
    required this.title,
    required this.description,
    required this.panelTitle,
    required this.panelItems,
    required this.accent,
    required this.icon,
  });

  final String tabLabel;
  final String badge;
  final String title;
  final String description;
  final String panelTitle;
  final List<String> panelItems;
  final Color accent;
  final IconData icon;
}
