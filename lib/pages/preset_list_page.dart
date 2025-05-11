import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/custom_preset.dart';
import 'preset_editor_page.dart';
import '../models/chord.dart';

/// プリセット一覧・管理ページ
class PresetListPage extends StatefulWidget {
  const PresetListPage({Key? key}) : super(key: key);

  @override
  State<PresetListPage> createState() => _PresetListPageState();
}

class _PresetListPageState extends State<PresetListPage> {
  final app = AppState.instance;
  List<CustomPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    // 初期ロード
    _presets = app.presets;
  }

  Future<void> _refreshPresets() async {
    await app.loadPresets();
    setState(() => _presets = app.presets);
  }

  void _addPreset() async {
    final newPreset = CustomPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '新規プリセット',
      allowedRoots: app.allowedRoots,
      allowedTriads: app.allowedTriads,
      allowedSevenths: app.allowedSevenths,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorPage(preset: newPreset, isNew: true),
      ),
    );
    await _refreshPresets();
  }

  void _editPreset(CustomPreset p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorPage(preset: p, isNew: false),
      ),
    );
    await _refreshPresets();
  }

  void _deletePreset(CustomPreset p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('プリセットを削除'),
        content: Text('「${p.name}」を削除してもよろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok == true) {
      await app.removePreset(p);
      setState(() => _presets = app.presets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = app.customPresets.length < 10;
    return Scaffold(
      appBar: AppBar(
        title: const Text('プリセット一覧'),
        actions: [
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '新規プリセット作成',
              onPressed: _addPreset,
            ),
        ],
      ),
      // body: ReorderableListView.builder(
        // UI 上のすべてのプリセットを移動できる
        // itemCount: _presets.length,
        // onReorder: (oldIndex, newIndex) async {
        //   if (newIndex > oldIndex) newIndex -= 1;
        //   // AppState側の reorderCustomPresets を呼び出せば
        //   // デフォルト/カスタム混在でも内部でカスタムだけpersistされます
        //   await app.reorderCustomPresets(oldIndex, newIndex);
        //   // ローカルリストもAppStateから再取得して更新
        //   setState(() => _presets = app.presets);
        // },
        // itemBuilder: (context, index) {
        //   final p = _presets[index];
        // 並び替え機能を外して通常のリスト表示に
      body: ListView.separated(
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = _presets[index];
          final isDefault = AppState.defaultPresets.any((d) => d.id == p.id);
          final subtitle = p.allowedRoots
              .map((r) => app.useFlats ? r.nameFlat() : r.nameSharp())
              .join('  ');
          return ListTile(
            key: ValueKey(p.id),
            title: Text(p.name),
            subtitle: Text(subtitle),
            // leading: const Icon(Icons.drag_handle),
            trailing: isDefault
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: '編集',
                        onPressed: () => _editPreset(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: '削除',
                        onPressed: () => _deletePreset(p),
                      ),
                    ],
                  ),
            onTap: () async {
              await app.applyPreset(p);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
