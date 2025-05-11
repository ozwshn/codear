import 'package:flutter/material.dart';
import '../models/custom_preset.dart';
import '../models/chord.dart';
import '../app_state.dart';
import 'settings_page.dart';

class PresetEditorPage extends StatefulWidget {
  final CustomPreset preset;
  final bool isNew;
  const PresetEditorPage({
    Key? key,
    required this.preset,
    this.isNew = false,
  }) : super(key: key);

  @override
  State<PresetEditorPage> createState() => _PresetEditorPageState();
}

class _PresetEditorPageState extends State<PresetEditorPage> {
  late final TextEditingController _nameCtl;
  late List<Root> _allowedRoots;
  late List<Triad> _allowedTriads;
  late List<Seventh> _allowedSevenths;

  @override
  void initState() {
    super.initState();
    _nameCtl       = TextEditingController(text: widget.preset.name);
    _allowedRoots  = List.of(widget.preset.allowedRoots);
    _allowedTriads = List.of(widget.preset.allowedTriads);
    _allowedSevenths = List.of(widget.preset.allowedSevenths);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.preset.copyWith(
      name:            _nameCtl.text,
      allowedRoots:    _allowedRoots,
      allowedTriads:   _allowedTriads,
      allowedSevenths: _allowedSevenths,
    );
    final app = AppState.instance;
    if (widget.isNew) {
      await app.addPreset(updated);
    } else {
      await app.updatePreset(updated);
    }
    // 編集後は一覧側で再読み込みするので、ここでは Navigator.pop のみ
    Navigator.pop(context);
  }

  void _pickRoots() {
    SettingsPage.openRootPicker(
      context,
      AppState.instance,
      selected: _allowedRoots,
      onChanged: (list) => setState(() => _allowedRoots = list),
    );
  }

  /// Triad の選択シート
  void _pickTriads() {
    final tmp = List<Triad>.from(_allowedTriads, growable: true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
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
                          onPressed: () =>
                              setModalState(() => tmp
                                ..clear()
                                ..addAll(Triad.values)),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          child: const Text('全解除'),
                          onPressed: () => setModalState(tmp.clear),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: Triad.values.map((t) {
                        return CheckboxListTile(
                          title: Text(t.name),
                          value: tmp.contains(t),
                          onChanged: (v) => setModalState(() {
                            if (v == true)
                              tmp.add(t);
                            else
                              tmp.remove(t);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          child: const Text('キャンセル'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          child: const Text('保存'),
                          onPressed: canSave
                              ? () {
                                  setState(() => _allowedTriads = List.of(tmp));
                                  Navigator.pop(context);
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
      ),
    );
  }

  /// Seventh の選択シート
  void _pickSevenths() {
    final tmp = List<Seventh>.from(_allowedSevenths, growable: true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
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
                          onPressed: () =>
                              setModalState(() => tmp
                                ..clear()
                                ..addAll(Seventh.values)),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          child: const Text('全解除'),
                          onPressed: () => setModalState(tmp.clear),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: Seventh.values.map((s) {
                        return CheckboxListTile(
                          title: Text(s.name),
                          value: tmp.contains(s),
                          onChanged: (v) => setModalState(() {
                            if (v == true)
                              tmp.add(s);
                            else
                              tmp.remove(s);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          child: const Text('キャンセル'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          child: const Text('保存'),
                          onPressed: canSave
                              ? () {
                                  setState(() => _allowedSevenths = List.of(tmp));
                                  Navigator.pop(context);
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
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(widget.isNew ? '新規プリセット作成' : 'プリセット編集'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(labelText: 'プリセット名'),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('出題するルート'),
            subtitle: Text(_allowedRoots
                .map((r) => AppState.instance.useFlats ? r.nameFlat() : r.nameSharp())
                .join(', ')),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _pickRoots,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('許可する Triad'),
            subtitle: Text(_allowedTriads.map((t) => t.name).join(', ')),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _pickTriads,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('許可する Seventh'),
            subtitle: Text(_allowedSevenths.map((s) => s.name).join(', ')),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _pickSevenths,
          ),
        ],
      ),
    );
  }
}
