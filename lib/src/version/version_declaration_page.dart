import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VersionMetadata {
  const VersionMetadata({
    required this.packageName,
    required this.versionName,
    required this.buildNumber,
  });

  final String packageName;
  final String versionName;
  final String buildNumber;

  String get fullVersion =>
      buildNumber.isEmpty ? versionName : '$versionName+$buildNumber';

  factory VersionMetadata.fromPubspec(String pubspecContent) {
    final packageName = _matchField(pubspecContent, 'name') ?? 'unknown';
    final rawVersion = _matchField(pubspecContent, 'version') ?? 'unknown';
    final versionParts = rawVersion.split('+');

    return VersionMetadata(
      packageName: packageName,
      versionName: versionParts.first,
      buildNumber: versionParts.length > 1
          ? versionParts.sublist(1).join('+')
          : '',
    );
  }

  static Future<VersionMetadata> load() async {
    final pubspecContent = await rootBundle.loadString('pubspec.yaml');
    return VersionMetadata.fromPubspec(pubspecContent);
  }

  static String? _matchField(String content, String fieldName) {
    final match = RegExp(
      '^$fieldName:\\s*(.+)\$',
      multiLine: true,
    ).firstMatch(content);

    return match?.group(1)?.trim();
  }
}

class VersionDeclarationPage extends StatefulWidget {
  const VersionDeclarationPage({super.key});

  @override
  State<VersionDeclarationPage> createState() => _VersionDeclarationPageState();
}

class _VersionDeclarationPageState extends State<VersionDeclarationPage> {
  late final Future<VersionMetadata> _metadataFuture;

  @override
  void initState() {
    super.initState();
    _metadataFuture = VersionMetadata.load();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4DE), Color(0xFFE8F4F0), Color(0xFFFFFAF2)],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<VersionMetadata>(
          future: _metadataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
              );
            }

            final metadata =
                snapshot.data ??
                const VersionMetadata(
                  packageName: 'unknown',
                  versionName: 'unknown',
                  buildNumber: '',
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Text(
                  '版本宣告',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本版內容',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        const _BulletLine(text: '音名入門、白鍵練習、十二音挑戰與弱點複習四種練習路徑。'),
                        const _BulletLine(
                          text: '首頁集中顯示訓練概況、今日建議與最近練習紀錄。',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '音檔來源',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '本 app 使用的鋼琴 MP3 音檔來自 GitHub 上的 `fuhton/piano-mp3`。',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '授權：MIT License',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF617179),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          '來源：https://github.com/fuhton/piano-mp3',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF617179),
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        '版本資訊載入時發生問題，頁面目前顯示的是保底內容。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7A4A2D),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '完整宣告版本：${metadata.fullVersion}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF617179),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, this.isLast = false});

  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF0C7A6B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
