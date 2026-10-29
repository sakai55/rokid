// data.js —— JSL（日本手話）指文字＋数字 首輪プローブ 22 項目。
// 範本は装着者視点の線画模式図（Canvas 自描）。指の形は各項目の
// tip（要点テキスト）が正であり、模式図は形の目安にすぎない。
// fingers = [親指, 人差し指, 中指, 薬指, 小指]、0=折る 1=伸ばす 2=半ば曲げる。
// palm: 'mae' 手のひら側が見える / 'ura' 手の甲側が見える。
// dir: 'up' 上 / 'down' 下 / 'side' 横（体側へ）/ 'fwd' 相手方向（短く見える）。
// 動きで区別する濁音・半濁音・促音・拗音・長音は静止写真で判定できないため収録しない。
export var SIGNS = [
  { id: 'a', name: 'あ', kind: '指文字', tip: '親指だけを斜め上に立て、他の指は握り込む。手のひらは相手側。', fingers: [1, 0, 0, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'side' },
  { id: 'i', name: 'い', kind: '指文字', tip: '小指だけを上に伸ばし、他の指は握り込む。', fingers: [0, 0, 0, 0, 1], palm: 'mae', dir: 'up', thumbPos: 'in' },
  { id: 'u', name: 'う', kind: '指文字', tip: '人差し指と中指をそろえて上に伸ばし、他の指は握る。', fingers: [0, 1, 1, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'in' },
  { id: 'e', name: 'え', kind: '指文字', tip: '五指を軽く曲げて爪を相手に見せ、親指を手のひらの前に置く。', fingers: [2, 2, 2, 2, 2], palm: 'mae', dir: 'up', thumbPos: 'front' },
  { id: 'o', name: 'お', kind: '指文字', tip: '五指の先を丸く合わせ、輪（円）を作る。', fingers: [2, 2, 2, 2, 2], palm: 'mae', dir: 'up', thumbPos: 'front', ring: true },
  { id: 'ka', name: 'か', kind: '指文字', tip: '人差し指と中指を上に伸ばし、親指を中指の付け根に触れさせる。', fingers: [1, 1, 1, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'touch' },
  { id: 'sa', name: 'さ', kind: '指文字', tip: '握りこぶしの前に親指を横に渡す（親指は立てない）。', fingers: [1, 0, 0, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'front' },
  { id: 'ta', name: 'た', kind: '指文字', tip: '人差し指を上に、親指を横に出し、角を作る。他の指は握る。', fingers: [1, 1, 0, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'side' },
  { id: 'na', name: 'な', kind: '指文字', tip: '人差し指と中指をそろえて下に向ける。手の甲が相手側。', fingers: [0, 1, 1, 0, 0], palm: 'ura', dir: 'down', thumbPos: 'in' },
  { id: 'ha', name: 'は', kind: '指文字', tip: '人差し指と中指をそろえて相手の方向へ向ける（指は短く見える）。', fingers: [0, 2, 2, 0, 0], palm: 'ura', dir: 'fwd', thumbPos: 'in' },
  { id: 'ma', name: 'ま', kind: '指文字', tip: '親指の上に人差し指・中指・薬指をかぶせるように折る。', fingers: [1, 2, 2, 2, 0], palm: 'mae', dir: 'up', thumbPos: 'under' },
  { id: 'ya', name: 'や', kind: '指文字', tip: '親指と小指だけを左右に開き、間の三指は握る。', fingers: [1, 0, 0, 0, 1], palm: 'mae', dir: 'up', thumbPos: 'side' },
  { id: 'ra', name: 'ら', kind: '指文字', tip: '人差し指と中指を交差させて上に伸ばす。', fingers: [0, 1, 1, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'in', cross: true },
  { id: 'wa', name: 'わ', kind: '指文字', tip: '人差し指・中指・薬指の三指を開いて上に伸ばす。', fingers: [0, 1, 1, 1, 0], palm: 'mae', dir: 'up', thumbPos: 'in' },
  { id: 'ni', name: 'に', kind: '指文字', tip: '人差し指と中指をそろえて横（体の内側）へ向ける。な・は と同じ手形で向きだけが違う。', fingers: [0, 1, 1, 0, 0], palm: 'mae', dir: 'side', thumbPos: 'in' },
  { id: 'te', name: 'て', kind: '指文字', tip: '五指を開いて伸ばし、手のひらを相手に見せる。', fingers: [1, 1, 1, 1, 1], palm: 'mae', dir: 'up', thumbPos: 'side' },
  { id: 'ho', name: 'ほ', kind: '指文字', tip: '五指を開いて伸ばし、手の甲を相手に見せる（手のひらは自分側）。て と手形は同じで向きが反対。', fingers: [1, 1, 1, 1, 1], palm: 'ura', dir: 'up', thumbPos: 'side' },
  { id: 'n1', name: '1', kind: '数字', tip: '数字の1：親指だけをまっすぐ上に立てる。', fingers: [1, 0, 0, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'up' },
  { id: 'n2', name: '2', kind: '数字', tip: '数字の2：親指と人差し指の二本を立てる。', fingers: [1, 1, 0, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'up' },
  { id: 'n3', name: '3', kind: '数字', tip: '数字の3：親指・人差し指・中指の三本を立てる。', fingers: [1, 1, 1, 0, 0], palm: 'mae', dir: 'up', thumbPos: 'up' },
  { id: 'n4', name: '4', kind: '数字', tip: '数字の4：小指以外の四本を立てる。', fingers: [1, 1, 1, 1, 0], palm: 'mae', dir: 'up', thumbPos: 'up' },
  { id: 'n5', name: '5', kind: '数字', tip: '数字の5：五指を全部開いて立てる。', fingers: [1, 1, 1, 1, 1], palm: 'mae', dir: 'up', thumbPos: 'up' }
];

export var SIGN_NAMES = SIGNS.map(function (s) { return s.name; }).join('、');
