// trace-kana エラーコードの単一定義（描紅シェル v1）
// コードの意味は倉庫ルート ERROR-CODES.md の全艦隊表が正典。本ファイルが本台の唯一の定義場所で、
// 業務コードは ERR.* と fail() だけを参照し、'E####' を散書きしない。
import wx from 'wx';

export var ERR = {
  E1001: 'カメラを開けない',
  E1002: 'カメラの許可がない',
  E1003: '撮影機能が使えない',
  E1007: 'カメラが見つからない',
  E1009: '撮影に失敗',
  E2002: 'キャンバスを作れない',
  E2013: 'エンコードに失敗',
  E5001: '記録の保存に失敗',
  E5002: '記録の読み込みに失敗',
  E6001: '大規模モデルが使えない',
  E6002: '大規模モデルへの要求に失敗',
  E6011: '大規模モデルの出力が使えない',
  E8001: 'ページ切替に失敗',
  E9001: '未分類のエラー'
};

export function errLine(code) {
  return code + ' ' + (ERR[code] || ERR.E9001);
}

export function codedError(code, message) {
  var e = new Error(message || ERR[code] || ERR.E9001);
  e.code = code;
  return e;
}

// 統一の失敗出口：lastError（コード＋slug＋版＋原文の切り詰め）を書く。決して例外を投げない。
export function fail(code, raw, slug, version) {
  var entry = {
    code: code,
    slug: slug || 'trace-kana',
    version: version || '1.0.1',
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* 保存がまた失敗しても投げない */ }
  return entry;
}
