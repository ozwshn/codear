/// lib/services/chord_generator.dart
import 'dart:math';
import '../models/chord.dart';

class ChordGenerator {
  static final _r = Random();

  /// 難易度ごとに出題プールを返す
  ///
  /// [diff] で基本プールを決定し、任意で [roots],[triads],[sevenths] を指定して上書きできます。  
  static List<ChordSpec> pool(
    Difficulty diff, {
    List<Root>? roots,
    List<Triad>? triads,
    List<Seventh>? sevenths,
  }) {
    // 使用するルート
    final useRoots = roots ?? Root.values;

    // デフォルトの triad / seventh / inversion を難易度ごとに設定
    List<Triad> useTriads;
    List<Seventh> useSevenths;
    int maxInv;

    switch (diff) {
      case Difficulty.level1:
        useTriads    = [Triad.maj];
        useSevenths  = [Seventh.none];
        maxInv       = 0;
        break;
      case Difficulty.level2:
        useTriads    = [Triad.maj];
        useSevenths  = [Seventh.none];
        maxInv       = 0;
        break;
      case Difficulty.level3:
        useTriads    = [Triad.maj];
        useSevenths  = [Seventh.none];
        maxInv       = 0;
        break;
      case Difficulty.level4:
        useTriads    = [Triad.maj, Triad.m];
        useSevenths  = [Seventh.none];
        maxInv       = 0;
        break;
      case Difficulty.level5:
        useTriads    = [Triad.maj, Triad.m, Triad.dim, Triad.aug];
        useSevenths  = [Seventh.none];
        maxInv       = 0;
        break;
      case Difficulty.level6:
        useTriads    = Triad.values;
        useSevenths  = [Seventh.none];
        maxInv       = 0;
        break;
      case Difficulty.level7:
        useTriads    = Triad.values;
        useSevenths  = [Seventh.none, Seventh.dom7];
        maxInv       = 0;
        break;
      case Difficulty.level8:
        useTriads    = Triad.values;
        useSevenths  = Seventh.values;
        maxInv       = 0;
        break;
      case Difficulty.level9:
        useTriads    = Triad.values;
        useSevenths  = Seventh.values;
        maxInv       = 1;
        break;
      case Difficulty.level10:
        useTriads    = Triad.values;
        useSevenths  = Seventh.values;
        maxInv       = 2;
        break;
    }

    // 引数で指定があれば上書き
    if (triads != null)    useTriads    = triads;
    if (sevenths != null)  useSevenths  = sevenths;

    // すべての組み合わせを生成
    return [
      for (final r in useRoots)
        for (final t in useTriads)
          for (final s in useSevenths)
            for (int inv = 0; inv <= maxInv; inv++)
              ChordSpec(root: r, triad: t, seventh: s, inversion: inv),
    ];
  }

  /// プールからランダムに１つ選ぶ
  static ChordSpec pick(List<ChordSpec> pool) =>
      pool[_r.nextInt(pool.length)];
}
