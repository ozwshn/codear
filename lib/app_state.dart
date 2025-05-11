import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'services/audio_service.dart';
import 'models/chord.dart';
import 'models/custom_preset.dart';

/// テーマモード
enum AppThemeMode { system, light, dark }

/// 利用可能なテーマカラー
const Map<String, MaterialColor> themeColors = {
  'Blue':    Colors.blue,
  'Red':     Colors.red,
  'Green':   Colors.green,
  'Orange':  Colors.orange,
  'Purple':  Colors.purple,
};

class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();
  final AudioService audio = AudioService();
  final _uuid = Uuid();

  // --- UI 設定 -------------------------------------
  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeMode get themeMode => _themeMode;
  String _themeKey = 'Blue';
  String get themeKey => _themeKey;
  bool _useFlats = false;
  bool get useFlats => _useFlats;

  // --- サウンド設定 --------------------------------
  int _instrument = 0;
  double _duration = 2.0;
  int get instrument => _instrument;
  double get duration => _duration;

  // --- クイズ設定 ----------------------------------
  int _questionCount = 10;
  int get questionCount => _questionCount;

  Difficulty _difficulty = Difficulty.level1;
  Difficulty get difficulty => _difficulty;

  List<Root>    _allowedRoots    = List.of(Root.values);
  List<Triad>   _allowedTriads   = List.of(Triad.values);
  List<Seventh> _allowedSevenths = List.of(Seventh.values);

  List<Root>    get allowedRoots    => List.unmodifiable(_allowedRoots);
  List<Triad>   get allowedTriads   => List.unmodifiable(_allowedTriads);
  List<Seventh> get allowedSevenths => List.unmodifiable(_allowedSevenths);

  // --- プリセット管理 ------------------------------
  static final List<CustomPreset> defaultPresets = List.generate(10, (i) {
    final level = i + 1;
    const triadsByLevel = [
      [Triad.maj],
      [Triad.maj, Triad.m],
      [Triad.maj, Triad.m, Triad.sus2, Triad.sus4],
      [Triad.maj, Triad.m, Triad.sus2, Triad.sus4, Triad.dim, Triad.aug],
      [Triad.maj, Triad.m, Triad.sus2, Triad.sus4, Triad.dim, Triad.aug],
      [Triad.maj, Triad.m],
      [Triad.maj, Triad.m, Triad.dim, Triad.aug],
      Triad.values,
      Triad.values,
      Triad.values,
    ];
    const seventhsByLevel = [
      [Seventh.none],
      [Seventh.none],
      [Seventh.none],
      [Seventh.none],
      [Seventh.none, Seventh.dom7],
      [Seventh.none, Seventh.dom7, Seventh.maj7],
      [Seventh.none, Seventh.dom7, Seventh.maj7, Seventh.m7],
      [Seventh.none, Seventh.dom7, Seventh.maj7, Seventh.m7],
      [Seventh.none, Seventh.dom7, Seventh.maj7, Seventh.m7, Seventh.dim7],
      Seventh.values,
    ];
    return CustomPreset(
      id: 'level$level',
      name: 'Level $level',
      allowedRoots:    List.of(Root.values),
      allowedTriads:   List.of(triadsByLevel[i]),
      allowedSevenths: List.of(seventhsByLevel[i]),
    );
  });

  List<CustomPreset> _customPresets = [];
  /// Combined list of read-only defaults + user customs
  List<CustomPreset> get presets => [
    ...defaultPresets,
    ..._customPresets,
  ];
  List<CustomPreset> get customPresets => List.unmodifiable(_customPresets);

  String _currentPresetId = defaultPresets.first.id;
  CustomPreset get activePreset {
    if (!presets.any((p) => p.id == _currentPresetId)) {
      _currentPresetId = presets.first.id;
    }
    return presets.firstWhere((p) => p.id == _currentPresetId);
  }

  /// アプリ起動時の初期化
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // カスタムプリセット読み込み
    // カスタムプリセット読み込み（always into a growable List<CustomPreset>）
    final rawPresets = prefs.getString('custom_presets');
    if (rawPresets != null) {
      final decoded = jsonDecode(rawPresets) as List<dynamic>;
      _customPresets = decoded
          .map((e) => CustomPreset.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    }
    // 選択中プリセット
    _currentPresetId = prefs.getString('current_preset_id') ?? _currentPresetId;

    // その他設定読み込み
    _instrument    = prefs.getInt('instrument')    ?? _instrument;
    _duration      = prefs.getDouble('duration')   ?? _duration;
    _useFlats      = prefs.getBool('useFlats')     ?? _useFlats;
    _themeKey      = prefs.getString('themeKey')   ?? _themeKey;
    _themeMode     = AppThemeMode.values.byName(
      prefs.getString('themeMode') ?? _themeMode.name
    );
    _questionCount = prefs.getInt('questionCount') ?? _questionCount;
    _difficulty    = Difficulty.values.byName(
      prefs.getString('difficulty') ?? _difficulty.name
    );
    final savedRoots = prefs.getStringList('allowed_roots');
    if (savedRoots != null) {
      _allowedRoots = savedRoots.map((n) => Root.values.byName(n)).toList(growable: true);
    }

    // プリセット適用
    await applyPreset(activePreset, persist: false);
    // オーディオ初期化
    await audio.init(program: _instrument, ms: (_duration * 1000).round());
    notifyListeners();
  }

  /// プリセット適用
  Future<void> applyPreset(CustomPreset p, {bool persist = true}) async {
    _allowedTriads   = List.of(p.allowedTriads);
    _allowedSevenths = List.of(p.allowedSevenths);
    _allowedRoots    = List.of(p.allowedRoots);
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_preset_id', p.id);
      _currentPresetId = p.id;
      // ルートも永続化
      await prefs.setStringList('allowed_roots', _allowedRoots.map((r) => r.name).toList());
    }
    notifyListeners();
  }

  /// プリセット追加
  Future<void> addPreset(CustomPreset p) async {
    final newPreset = p.copyWith(id: _uuid.v4());
    _customPresets.add(newPreset);
    await _saveCustomPresets();
    notifyListeners();
  }

  /// プリセット読み込み
  Future<void> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('custom_presets');
    if (raw != null) {
      _customPresets = (jsonDecode(raw) as List)
        .map((e) => CustomPreset.fromJson(e as Map<String, dynamic>))
        .toList(growable: true);
    } else {
      _customPresets = [];
    }
    notifyListeners();
  }

  /// プリセット更新
  Future<void> updatePreset(CustomPreset p) async {
    final idx = _customPresets.indexWhere((e) => e.id == p.id);
    if (idx >= 0) {
      _customPresets[idx] = p;
      await _saveCustomPresets();
      notifyListeners();
    }
  }

  /// プリセット削除
  Future<void> removePreset(CustomPreset p) async {
    _customPresets.removeWhere((e) => e.id == p.id);
    await _saveCustomPresets();
    if (_currentPresetId == p.id) {
      _currentPresetId = presets.first.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_preset_id', _currentPresetId);
    }
    notifyListeners();
  }

  /// 並び替え
  Future<void> reorderCustomPresets(int oldIndex, int newIndex) async {
    // operate on the full `presets` list, then extract back just the customs
    final full = List.of(presets);
    final item = full.removeAt(oldIndex);
    full.insert(newIndex, item);
    // keep only those not in defaults, in their new order:
    _customPresets = full
        .where((p) => defaultPresets.indexWhere((d) => d.id == p.id) < 0)
        .toList(growable: true);
    await _saveCustomPresets();
    notifyListeners();
  }

  Future<void> _saveCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_customPresets.map((e) => e.toJson()).toList());
    await prefs.setString('custom_presets', raw);
  }

  // --- その他設定セッター -----------------------------
  Future<void> setInstrument(int prog) async {
    _instrument = prog;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('instrument', prog);
    await audio.init(program: prog, ms: (_duration * 1000).round());
    notifyListeners();
  }
  Future<void> setUseFlats(bool v) async {
    _useFlats = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useFlats', v);
    notifyListeners();
  }
  Future<void> setDuration(double sec) async {
    _duration = sec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('duration', sec);
    await audio.init(program: _instrument, ms: (sec * 1000).round());
    notifyListeners();
  }
  Future<void> setQuestionCount(int count) async {
    _questionCount = count.clamp(1, 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('questionCount', _questionCount);
    notifyListeners();
  }
  Future<void> setDifficulty(Difficulty diff) async {
    _difficulty = diff;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('difficulty', diff.name);
    notifyListeners();
  }
  Future<void> setAllowedRoots(List<Root> roots) async {
    _allowedRoots = List.of(roots);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('allowed_roots', _allowedRoots.map((r) => r.name).toList());
    notifyListeners();
  }
  Future<void> setThemeKey(String key) async {
    _themeKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeKey', key);
    notifyListeners();
  }
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  AppStateScope({super.key, required super.child}) : super(notifier: AppState.instance);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}
