import 'package:flutter/material.dart';
import 'app_state.dart';
import 'pages/quiz_page.dart';
import 'pages/demo_page.dart';
import 'pages/settings_page.dart';
import 'pages/preset_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.init();        // 先に音源ロード
  runApp(const CodearApp());
}



class CodearApp extends StatelessWidget {
  const CodearApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      child: Builder(builder: (ctx) {
        final app = AppStateScope.of(ctx);

        // ① 共通の「シードカラー」から Light/Dark のカラースキームを作る
        final seed = themeColors[app.themeKey]!;
        final light  = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
          useMaterial3: true,
        );
        final dark   = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
          useMaterial3: true,
        );

        return MaterialApp(
          title: 'Codear',
          theme: light,
          darkTheme: dark,
          themeMode: switch (app.themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light  => ThemeMode.light,
            AppThemeMode.dark   => ThemeMode.dark,
          },
          routes: {
            '/':        (_) => const HomePage(),
            '/demo':    (_) => const MidiDemoPage(),
            '/quiz':    (_) => const QuizPage(),
            '/settings':(_) => const SettingsPage(),
            '/presets': (_) => const PresetListPage(),
          },
        );
      }),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 各セクションの定義
    final sections = <SectionItem>[
      SectionItem(
        title: 'Demo',
        icon: Icons.play_circle_outline,
        children: [
          FeatureItem(
            icon: Icons.music_note,
            title: 'コード再生デモ',
            subtitle: 'MIDI でコードを再生してみる',
            onTap: () => Navigator.pushNamed(context, '/demo'),
          ),
        ],
      ),
      SectionItem(
        title: 'Quiz',
        icon: Icons.quiz_outlined,
        children: [
          FeatureItem(
            icon: Icons.question_mark,
            title: 'コード当てクイズ',
            subtitle: '流れたコードを当てる練習',
            onTap: () => Navigator.pushNamed(context, '/quiz'),
          ),
          // 例：将来的にここに別の Quiz モードを追加できます
          // FeatureItem(
          //   icon: Icons.multiline_chart,
          //   title: 'コード進行クイズ',
          //   subtitle: '進行を当てる新モード',
          //   onTap: () => Navigator.pushNamed(context, '/quiz/progression'),
          // ),
        ],
      ),
      SectionItem(
        title: 'Preset',
        icon: Icons.tune,
        children: [
          FeatureItem(
            icon: Icons.list_alt,
            title: 'プリセット管理',
            subtitle: 'カスタム・デフォルトを整理する',
            onTap: () => Navigator.pushNamed(context, '/presets'),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Codear ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, i) {
          final sec = sections[i];
          return ExpansionTile(
            leading: Icon(sec.icon),
            title: Text(
              sec.title,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
              ),
            ),
            children: sec.children.map((f) {
              return ListTile(
                leading: Icon(f.icon),
                title: Text(f.title),
                subtitle: Text(f.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: f.onTap,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// セクション（Demo / Quiz / Preset）モデル
class SectionItem {
  final String title;
  final IconData icon;
  final List<FeatureItem> children;
  SectionItem({
    required this.title,
    required this.icon,
    required this.children,
  });
}

/// 各機能項目モデル
class FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}