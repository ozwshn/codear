import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class AudioService {
  /* ---------- 共有（static）領域 ---------- */
  static final MidiPro _midi = MidiPro();  // 全画面で 1 インスタンス
  static int? _sharedSfId;                 // 1 度ロードしたら再利用

  /* ---------- インスタンスごと ---------- */
  int _program = 0;      // 現在の音色
  int _defaultMs = 2000; // デフォルト再生長

  /* ------- 初期化／音色変更 ------- */
  Future<void> init({int? program, int? ms}) async {
    if (program != null) _program = program;
    if (ms != null) _defaultMs = ms;

    // ① まだロードしていなければロード
    if (_sharedSfId == null) {
      try {
        _sharedSfId = await _midi.loadSoundfont(
          path: 'assets/soundfonts/FluidR3_GM.sf2',  // ← アセットパス直渡し
          bank: 0,
          program: _program,
        );
      } catch (e) {
        debugPrint('loadSoundfont error: $e');
        return;
      }
    } else {
      // ② 既にロード済みなら program だけ切り替え
      _midi.selectInstrument(
        channel: 0,
        bank: 0,
        program: _program,
        sfId: _sharedSfId!,
      );
    }
  }

  /* ------- 和音を鳴らす ------- */
  void playChord(List<int> notes, {int? ms}) {
    if (_sharedSfId == null) return;              // まだロード前
    final dur = ms ?? _defaultMs;
    final sf  = _sharedSfId!;                     // キャプチャしておく

    for (final n in notes) {
      _midi.playNote(channel: 0, key: n, velocity: 100, sfId: sf);
      Future.delayed(
        Duration(milliseconds: dur),
        () => _midi.stopNote(channel: 0, key: n, sfId: sf),
      );
    }
  }

  /* ------- 後片付け ------- */
  void dispose() {
    // 共有インスタンスは解放しない（アプリ全体で 1 つ）
  }
}
