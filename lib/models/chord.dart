import 'package:flutter/foundation.dart';
import '../app_state.dart';

/* ---- 基本構成 ---- */
enum Root { C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B }
extension RootDisplay on Root {
  /// Unicode の ♯（シャープ）／♭（フラット）付きで表示
  String nameSharp() {
    switch (this) {
      case Root.C:  return 'C';
      case Root.Cs: return 'C♯';
      case Root.D:  return 'D';
      case Root.Ds: return 'D♯';
      case Root.E:  return 'E';
      case Root.F:  return 'F';
      case Root.Fs: return 'F♯';
      case Root.G:  return 'G';
      case Root.Gs: return 'G♯';
      case Root.A:  return 'A';
      case Root.As: return 'A♯';
      case Root.B:  return 'B';
    }
  }

  String nameFlat() {
    switch (this) {
      case Root.C:  return 'C';
      case Root.Cs: return 'D♭';
      case Root.D:  return 'D';
      case Root.Ds: return 'E♭';
      case Root.E:  return 'E';
      case Root.F:  return 'F';
      case Root.Fs: return 'G♭';
      case Root.G:  return 'G';
      case Root.Gs: return 'A♭';
      case Root.A:  return 'A';
      case Root.As: return 'B♭';
      case Root.B:  return 'B';
    }
  }
}

enum Triad { maj, m, dim, aug, sus2, sus4 }

enum Seventh { none, dom7, maj7, m7, dim7, m7b5 }

/// lib/models/chord.dart

/// 10 段階の難易度レベル
enum Difficulty {
  level1,  // 最も簡単：C のメジャーだけ
  level2,  // C / A / G / F のメジャーだけ
  level3,  // 全ルートのメジャーだけ
  level4,  // 全ルートのメジャー＋マイナー（no 7th）
  level5,  // 全ルートのメジャー＋マイナー＋dim/aug
  level6,  // 全ルートの triads + sus2/sus4
  level7,  // 〈レベル６〉＋dom7 の追加
  level8,  // 〈レベル７〉＋maj7/m7/m7b5 の追加
  level9,  // 〈レベル８〉＋第１転回形を解禁
  level10, // 全部入り：四和音＋第２転回形まで
}

/* ---- コード仕様 ---- */
@immutable
class ChordSpec {
  const ChordSpec({
    required this.root,
    required this.triad,
    this.seventh = Seventh.none,
    this.inversion = 0,
  });

  final Root root;
  final Triad triad;
  final Seventh seventh;
  final int inversion;          // 0=rootPos, 1=1st, 2=2nd

  /* -------- 表示ラベル -------- */
  String get label {
    // AppState から現在値を読む
    final useFlats = AppState.instance.useFlats;
    final rootText = useFlats ? root.nameFlat() : root.nameSharp();

    // triad/seventh/inversion のサフィックスはそのまま
    final triTxt = switch (triad) {
        Triad.maj   => '',
        Triad.m     => 'm',
        Triad.dim   => 'dim',
        Triad.aug   => 'aug',
        Triad.sus2  => 'sus2',
        Triad.sus4  => 'sus4',
    };
    final sevTxt = switch (seventh) {
      Seventh.none  => '',
      Seventh.dom7  => '7',
      Seventh.maj7  => 'maj7',
      Seventh.m7    => 'm7',
      Seventh.dim7  => 'dim7',
      Seventh.m7b5  => 'm7♭5',
    };

    // 転回形のルート（enum）を計算
    final invRoot = Root.values[(root.index + inversion) % 12];

    // 表示用文字列をシャープ or フラットで切り替え
    final invRootText = useFlats
        ? invRoot.nameFlat()
        : invRoot.nameSharp();

    // 最終的な invTxt は…
    final invTxt = inversion == 0 ? '' : '/$invRootText';
      
    return '$rootText$triTxt$sevTxt$invTxt';
  }

  /* -------- MIDI ノート -------- */
  List<int> get notes {
    const tri = {
      Triad.maj : [0,4,7],
      Triad.m   : [0,3,7],
      Triad.dim : [0,3,6],
      Triad.aug : [0,4,8],
      Triad.sus2: [0,2,7],
      Triad.sus4: [0,5,7],
    };
    const sev = {
      Seventh.none : [],
      Seventh.dom7 : [10],
      Seventh.maj7 : [11],
      Seventh.m7   : [10],
      Seventh.dim7 : [9],
      Seventh.m7b5 : [10], // triad.dim + ♭7
    };

    var iv = [...tri[triad]!, ...sev[seventh]!];

    // 転回
    for (int i = 0; i < inversion; i++) {
      iv = [...iv.skip(1), iv.first + 12];
    }
    final base = 60 + root.index;           // C4 = 60
      return iv.map((i) => (base + i) as int).toList();
  }

  /* -------- 等価判定（構成音が同じなら true） -------- */
  bool equals(ChordSpec other) {
    return root    == other.root
        && triad   == other.triad
        && seventh == other.seventh;
    // inversion を厳密に見るなら  && inversion == other.inversion
  }
  
  factory ChordSpec.fromJson(Map<String, dynamic> j) {
    return ChordSpec(
      root      : Root.values.byName(j['root']     as String),
      triad     : Triad.values.byName(j['triad']   as String),
      seventh   : Seventh.values.byName(j['seventh'] ?? 'none'),
      inversion : (j['inversion'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'root'     : root.name,
    'triad'    : triad.name,
    'seventh'  : seventh.name,
    'inversion': inversion,
  };
}
