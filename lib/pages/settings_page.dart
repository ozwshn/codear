// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../app_state.dart';                // AppStateScope.of(context) 用
import '../data/gm_instruments.dart';     // GM 番号 → 楽器名マップ
import '../services/audio_service.dart';  // プレビュー専用に生成
import '../models/chord.dart';

/// グローバル設定画面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─────────────────────────────────
          // ■ サウンド設定
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('サウンド設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // 音色
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('音色 (GM Program)'),
              subtitle: Text(
                '${app.instrument.toString().padLeft(3)}  '
                '${gmInstruments[app.instrument]}',
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _openInstrumentPicker(context, app),
            ),
          ),

          // 再生長さ
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('再生秒数'),
              subtitle: Slider(
                value: app.duration,
                min: 0.2,
                max: 4.0,
                divisions: 19,
                label: app.duration.toStringAsFixed(1) + ' 秒',
                onChanged: (v) => app.setDuration(v),
              ),
            ),
          ),

          // ─────────────────────────────────
          // ■ クイズ設定
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('クイズ設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // 問題数
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text('問題数'),
              // subtitle: DropdownButton<int>(
              //   value: app.questionCount,
              //   items: [5, 10, 20]
              //       .map((n) => DropdownMenuItem(
              //             value: n,
              //             child: Text('$n 問'),
              //           ))
              //       .toList(),
              //   onChanged: (v) => app.setQuestionCount(v!),
              // ),
              subtitle: Text('${app.questionCount} 問'),
              onTap: () => _showQuestionCountPicker(context, app),
            ),
          ),

          // プリセット選択
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('プリセット選択'),
              subtitle: Text(app.activePreset.name),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => Navigator.pushNamed(context, '/presets'),
            ),
          ),

          // 出題するルート音
          ListTile(
            title: const Text('出題するルート音'),
            subtitle: Text(
              app.allowedRoots
                  .map((r) => app.useFlats ? r.nameFlat() : r.nameSharp())
                  .join('  '),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => SettingsPage.openRootPicker(
              context,
              app,
              selected: app.allowedRoots,
              onChanged: (list) => app.setAllowedRoots(list),
            ),
          ),

          // ─────────────────────────────────
          // ■ 表示設定
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('表示設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // シャープ/フラット切替
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: SwitchListTile(
              secondary: const Icon(Icons.music_note),
              title: const Text('ルート音の表示'),
              subtitle: const Text('シャープ ♯ / フラット ♭ を切り替え'),
              value: app.useFlats,
              onChanged: (v) => app.setUseFlats(v),
            ),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('テーマカラー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('テーマカラーを選択'),
              subtitle: DropdownButton<String>(
                value: app.themeKey,
                items: themeColors.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (k) {
                  if (k != null) app.setThemeKey(k);
                },
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('テーマモード',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('システム設定に合わせる'),
            value: AppThemeMode.system,
            groupValue: app.themeMode,
            onChanged: (v) => app.setThemeMode(v!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('ライトモード'),
            value: AppThemeMode.light,
            groupValue: app.themeMode,
            onChanged: (v) => app.setThemeMode(v!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('ダークモード'),
            value: AppThemeMode.dark,
            groupValue: app.themeMode,
            onChanged: (v) => app.setThemeMode(v!),
          ),
        ],
      ),
    );
  }

  /* ───────── 音色ピッカー (BottomSheet) ───────── */
  void _openInstrumentPicker(BuildContext ctx, AppState app) {
    final int original = app.instrument;      // もとの音色
    int tmp = original;                       // 操作中の音色
    final preview = AudioService();           // プレビュー再生専用

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,   // 画面高 × 指定比率を使う
      enableDrag: false,          // 下ドラッグで閉じない
      isDismissible: false,       // 背景タップで閉じない
      builder: (_) => StatefulBuilder(
        builder: (c, setState) => SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(ctx).canvasColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: gmInstruments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final id   = gmInstruments.keys.elementAt(idx);
                      final name = gmInstruments[id]!;
                      final sel  = id == app.instrument;
                      final chosen = id == tmp;
                      return ListTile(
                        selected: sel,
                        selectedColor: Colors.blue,
                        selectedTileColor:
                            Colors.blue.withOpacity(0.1),
                        title: Text(
                          '${id.toString().padLeft(3)}  $name',
                          style: TextStyle(
                            color: chosen
                                ? Theme.of(ctx).colorScheme.primary
                                : null,
                            fontWeight: chosen
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () async {
                          setState(() => tmp = id);
                          await preview.init(
                              program: id, ms: 800);
                          preview.playChord(
                              [60, 64, 67]);
                        },
                      );
                    },
                  ),
                ),

                /* ── 決定 / キャンセル ── */
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: const Text('キャンセル'),
                        onPressed: () async {
                          if (tmp != original) {
                            await app.setInstrument(original);
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        child: const Text('決定'),
                        onPressed: () async {
                          await app.setInstrument(tmp);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => preview.dispose());
  }

  // ───────── 問題数ホイールピッカー ─────────
  void _showQuestionCountPicker(BuildContext ctx, AppState app) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        height: 216,
        color: Theme.of(ctx).canvasColor,
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
            initialItem: app.questionCount - 1,
          ),
          itemExtent: 32,
          onSelectedItemChanged: (i) => app.setQuestionCount(i + 1),
          children: List<Widget>.generate(
            50,
            (i) => Center(child: Text('${i + 1} 問')),
          ),
        ),
      ),
    );
  }

  /// ルート音選択 BottomSheet
  static void openRootPicker(
    BuildContext ctx,
    AppState app, {
    required List<Root> selected,
    required ValueChanged<List<Root>> onChanged,
  }) {
    final tmp = List.of(selected);
    final useFlats = app.useFlats;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag:    false,  // 下スワイプで閉じない
      isDismissible: false,  // 背景タップでも閉じない
      builder: (_) {
        // シートの高さを画面の 60% に固定
        final height = MediaQuery.of(ctx).size.height * 0.6;
        return SafeArea(
          top: false,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(ctx).canvasColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: StatefulBuilder(
              builder: (sheetCtx, setSheetState) {
                final canSave = tmp.isNotEmpty;
                return Column(
                  children: [
                    // 全選択／全解除
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          TextButton(
                            child: const Text('全選択'),
                            onPressed: () => setSheetState(() {
                              tmp
                                ..clear()
                                ..addAll(Root.values);
                            }),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            child: const Text('全解除'),
                            onPressed: () => setSheetState(tmp.clear),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // ここから中身だけスクロール可能
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: Root.values.map((r) {
                          final label = useFlats ? r.nameFlat() : r.nameSharp();
                          return CheckboxListTile(
                            title: Text(label),
                            value: tmp.contains(r),
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == true) tmp.add(r);
                                else          tmp.remove(r);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1),
                    // 決定／キャンセル
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            child: const Text('キャンセル'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            child: const Text('保存'),
                            onPressed: canSave
                              ? () {
                                  onChanged(tmp);
                                  Navigator.pop(ctx);
                                }
                              : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
