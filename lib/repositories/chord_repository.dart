// lib/repositories/chord_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chord.dart';

class ChordRepository {
  ChordRepository._();
  static final instance = ChordRepository._();

  List<ChordSpec>? _cache;

  Future<List<ChordSpec>> load() async {
    if (_cache != null) return _cache!;        // 既に読み込んでいれば再利用

    // ★ ここが読み込みファイル名だけ変更
    final jsonStr = await rootBundle.loadString('assets/chords.json');
    final List data = json.decode(jsonStr);

    // Chord.fromJson() は quality を含む新フォーマット対応版
    _cache = data.map((e) => ChordSpec.fromJson(e)).toList(growable: false);
    return _cache!;
  }
}
