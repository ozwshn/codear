import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/chord.dart';
import '../services/chord_generator.dart';
import 'settings_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // 問題数は設定画面で変更される
  late int _maxQuestion;
  static const _defaultMax = 10;

  // 出題プールと選択肢
  late List<ChordSpec> _pool;
  late List<ChordSpec> _choices;
  late ChordSpec _answer;

  int  _qNo     = 0;   // 何問目（1〜）
  int  _score   = 0;   // 正解数
  bool _ready   = false; // ボタン活性
  bool _loading = true;  // 初回読み込み中
  bool _locked  = false; // 多重タップ防止

  bool _initedDeps = false;

  @override
  void initState() {
    super.initState();
    _maxQuestion = _defaultMax;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initedDeps) {
      final app = AppStateScope.of(context);
      _pool = ChordGenerator.pool(
        app.difficulty,
        roots: app.allowedRoots,
        triads: app.allowedTriads,
        sevenths: app.allowedSevenths,
      );
      _maxQuestion = app.questionCount;
      _nextQuestion();
      _initedDeps = true;
      setState(() => _loading = false);
    }
  }

  void _nextQuestion() {
    if (_qNo == _maxQuestion) {
      _showResultDialog();
      return;
    }

    _answer  = ChordGenerator.pick(_pool);
    _choices = {_answer, ..._pool..shuffle()}
      .take(4).toList(growable: false)..shuffle();

    // 音を再生
    AppState.instance.audio.playChord(_answer.notes, ms: 1500);

    setState(() {
      _qNo  += 1;
      _ready  = true;
      _locked = false;
    });
  }

  void _pick(ChordSpec picked) {
    if (_locked || !_ready) return;
    _locked = true;
    final correct = picked.equals(_answer);
    if (correct) _score += 1;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? '正解！ 🎉' : '残念…正解は ${_answer.label}'),
        duration: const Duration(milliseconds: 800),
      ),
    );

    Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // final app = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('$_score / $_qNo  （全 $_maxQuestion 問）',
            style: const TextStyle(fontSize: 18)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('再生されたコードは？',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ..._choices.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: _ready ? () => _pick(c) : null,
                  child: Text(c.label, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () =>
                  AppState.instance.audio.playChord(_answer.notes),
              child: const Text('もう一度聴く'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResultDialog() async {
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('結果'),
        content: Text(
          '$_maxQuestion 問中 $_score 問正解！\n'
          '正答率 ${(100 * _score / _maxQuestion).toStringAsFixed(1)} %',
        ),
        actions: [
          TextButton(
            child: const Text('やめる'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('もう一度'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (again == true) {
      setState(() {
        _score = 0;
        _qNo   = 0;
      });
      _nextQuestion();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }
}
