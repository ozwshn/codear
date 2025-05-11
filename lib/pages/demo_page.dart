import 'package:flutter/material.dart';
import '../models/chord.dart';
import '../repositories/chord_repository.dart';
import '../app_state.dart';
import 'settings_page.dart';

class MidiDemoPage extends StatefulWidget {
  const MidiDemoPage({super.key});
  @override
  State<MidiDemoPage> createState() => _MidiDemoPageState();
}

class _MidiDemoPageState extends State<MidiDemoPage> {
  List<ChordSpec> _chords = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ChordRepository.instance;   // ★シングルトン
    _chords = await repo.load();
    setState(() {});                           // UI 更新
  }

  @override
  Widget build(BuildContext context) {
    final ready = _chords.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('MIDI コードプレーヤー'),
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
      body: Center(
        child: ready
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: _chords.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      final app = AppStateScope.of(context);
                      app.audio.playChord(c.notes);
                    },
                    child: Text('${c.label} コードを鳴らす'),   // ← これを追加
                  ),
                ),).toList(),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}