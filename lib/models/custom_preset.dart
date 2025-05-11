import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'chord.dart';  // Root, Triad, Seventh の定義があるファイル

/// カスタムプリセット: Triad / Seventh / Root のみを保存
@immutable
class CustomPreset {
  CustomPreset({
    String? id,
    required this.name,
    required List<Root> allowedRoots,
    required List<Triad> allowedTriads,
    required List<Seventh> allowedSevenths,
  })  : id = id ?? const Uuid().v4(),
        // 必ず growable なリストとして保持
        allowedRoots = List<Root>.from(allowedRoots, growable: true),
        allowedTriads = List<Triad>.from(allowedTriads, growable: true),
        allowedSevenths = List<Seventh>.from(allowedSevenths, growable: true);

  /// 一意識別子
  final String id;

  /// プリセット名
  final String name;

  /// 出題ルート一覧
  final List<Root> allowedRoots;

  /// 出題 Triad 一覧
  final List<Triad> allowedTriads;

  /// 出題 Seventh 一覧
  final List<Seventh> allowedSevenths;

  CustomPreset copyWith({
    String? id,
    String? name,
    List<Root>? allowedRoots,
    List<Triad>? allowedTriads,
    List<Seventh>? allowedSevenths,
  }) => CustomPreset(
    id:              id ?? this.id,
    name:            name ?? this.name,
    allowedRoots:    allowedRoots != null ? List.of(allowedRoots) : List.of(this.allowedRoots),
    allowedTriads:   allowedTriads != null ? List.of(allowedTriads) : List.of(this.allowedTriads),
    allowedSevenths: allowedSevenths != null ? List.of(allowedSevenths) : List.of(this.allowedSevenths),
  );

  /// JSON から復元
  factory CustomPreset.fromJson(Map<String, dynamic> j) {
    // id が無い／null なら新規生成
    final id = (j['id'] as String?) ?? const Uuid().v4();
    final name = j['name'] as String? ?? 'Unnamed';

    // JSON の List<dynamic> → Enum のリスト
    final rawRoots = (j['allowedRoots'] as List<dynamic>?) ?? [];
    final allowedRoots = rawRoots
        .map((e) => Root.values.byName(e as String))
        .toList(growable: true);

    final rawTriads = (j['allowedTriads'] as List<dynamic>?) ?? [];
    final allowedTriads = rawTriads
        .map((e) => Triad.values.byName(e as String))
        .toList(growable: true);

    final rawSevs = (j['allowedSevenths'] as List<dynamic>?) ?? [];
    final allowedSevenths = rawSevs
        .map((e) => Seventh.values.byName(e as String))
        .toList(growable: true);

    return CustomPreset(
      id: id,
      name: name,
      allowedRoots: allowedRoots.isNotEmpty
          ? allowedRoots
          : List<Root>.from(Root.values, growable: true),
      allowedTriads: allowedTriads.isNotEmpty
          ? allowedTriads
          : List<Triad>.from(Triad.values, growable: true),
      allowedSevenths: allowedSevenths.isNotEmpty
          ? allowedSevenths
          : List<Seventh>.from(Seventh.values, growable: true),
    );
  }

  /// JSON へ変換
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'allowedRoots': allowedRoots.map((r) => r.name).toList(),
        'allowedTriads': allowedTriads.map((t) => t.name).toList(),
        'allowedSevenths': allowedSevenths.map((s) => s.name).toList(),
      };

  @override
  String toString() =>
      'CustomPreset(id: $id, name: $name, roots: $allowedRoots, triads: $allowedTriads, sevenths: $allowedSevenths)';
}
