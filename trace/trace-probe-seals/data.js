// data.js —— 九字印（臨・兵・闘・者・皆・陳・烈・在・前）認識プローブのデータ。
// 唯一の参照は GO 定版の九欄図譜（kuji-reference-chart.jpg）だけ。
// 要点（tip）は各欄下の縦排説明（崩し字）からの転写／要約か、読解が
// 及ばない印は保守的な一般説明。区別は tipSrc に持ち、根拠の断片と
// 判定は README の出典一覧に逐印で書く：
//   'chart-distill' = 図譜の断片が読め、文意を一文に要約できた
//   'general'       = 文としては読解できず、印名と図の形からの一般説明
// 印刷ページ写真は参照から外れたため、文案にも使っていない。
//
// 見本（art）データの形式：図譜を参照に再描画した自有線稿を高さ 92px に
// ラスタライズし、行ごとに [y, x0, len0, x1, len1, ...] の行程符号（runs）で持つ。
// { w, h, rows } 形式。ページは Canvas に 1px 線（#7dff9e）で描く。
// 2026-10-29 時点：再描画の見本（前四印）が GO 確認待ちのため art は
// 全印 null。定版後に生成スクリプトで本ファイルへ流し込む。null の印は
// 輪測ページで「見本準備中」と正直に表示される（代用図は置かない）。
export var SEALS = [
  { id: 'rin', name: '臨', reading: 'りん', sub: '独古印', subReading: 'とっこのいん', tipSrc: 'chart-distill', tip: '両手の指を組み合わせ、指先を揃えて合わせる。', diff: '兵（大金剛輪印）と似る。臨は指先を揃えて合わせる形。', art: null },
  { id: 'hyo', name: '兵', reading: 'ひょう', sub: '大金剛輪印', subReading: 'だいこんごうりんのいん', tipSrc: 'general', tip: '両手の指をからめ合わせ、中央で輪を作るように結ぶ。', diff: '臨と似る。兵は中央で輪を作る形になる。', art: null },
  { id: 'to', name: '闘', reading: 'とう', sub: '外獅子印', subReading: 'げししのいん', tipSrc: 'chart-distill', tip: '人差し指と中指を立て、薬指と小指を組み合わせる。', diff: '者（内獅子印）と似る。闘は人差し指と中指を立てる。', art: null },
  { id: 'sha', name: '者', reading: 'しゃ', sub: '内獅子印', subReading: 'ないししのいん', tipSrc: 'general', tip: '両手の指を内側で組み合わせ、指先を合わせるように結ぶ。', diff: '闘と似る。者は指を内側で組み、指先を合わせる。', art: null },
  { id: 'kai', name: '皆', reading: 'かい', sub: '外縛印', subReading: 'げばくのいん', tipSrc: 'general', tip: '両手の指を外側に出して組み合わせる。', diff: '陳（内縛印）とは内外が逆。指を外側へ出して組む。', art: null },
  { id: 'chin', name: '陳', reading: 'ちん', sub: '内縛印', subReading: 'ないばくのいん', tipSrc: 'general', tip: '両手の指を内側に入れて組み合わせる。', diff: '皆（外縛印）と対。指を内側へ入れて組む。', art: null },
  { id: 'retsu', name: '烈', reading: 'れつ', sub: '智拳印', subReading: 'ちけんのいん', tipSrc: 'chart-distill', tip: '左手の人差し指を立て、右手の指を添えて包むように結ぶ。', diff: '左手の人差し指を立てる形。他の印と組み方が大きく違う。', art: null },
  { id: 'zai', name: '在', reading: 'ざい', sub: '日輪印', subReading: 'にちりんのいん', tipSrc: 'chart-distill', tip: '両手の親指と人差し指の先をつけて輪を作り、他の指は開く。', diff: '指先で輪を作る形。臨の組み方とは違う。', art: null },
  { id: 'zen', name: '前', reading: 'ぜん', sub: '隠形印', subReading: 'おんぎょうのいん', tipSrc: 'chart-distill', tip: '片方の手をもう一方の手に重ね、指を隠すように組み合わせる。', diff: '手を重ねて指を隠す形。在の輪とは違う。', art: null }
];

export var SEAL_NAMES = SEALS.map(function (s) { return s.name + '（' + s.sub + '）'; }).join('、');
