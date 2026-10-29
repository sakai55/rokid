// trace-probe-seals エラーコード単一定義（描紅シェル v1）
// コードの意味はリポジトリ直下 ERROR-CODES.md の全体表が正。本ファイルが
// 本機の唯一の定義場所で、業務コードは ERR.* と fail() だけを参照し、
// 'E####' の文字列を散らして書いてはならない。
import wx from 'wx';

export var ERR = {
  E1001: 'カメラを開けなかった',
  E1002: 'カメラの許可がない',
  E1003: '撮影機能が使えない',
  E1007: 'カメラが見つからない',
  E1009: '撮影に失敗',
  E2002: 'キャンバスの作成に失敗',
  E2013: 'テキスト変換に失敗',
  E5001: '記録の保存に失敗',
  E5002: '記録の読み込みに失敗',
  E6001: 'LLMが使えない',
  E6002: 'LLMへのリクエストに失敗',
  E6011: 'LLMの出力が使えない',
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

// 統一の失敗出口：lastError（コード + slug + 版 + 原文の切り詰め）を書き、決して投げない。
export function fail(code, raw, slug, version) {
  var entry = {
    code: code,
    slug: slug || 'trace-probe-seals',
    version: version || '2.0.0',
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* 保存に再失敗しても投げない */ }
  return entry;
}
