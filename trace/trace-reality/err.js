// trace-reality 错误码单点定义（描红系列壳）
// 码义以仓库根 ERROR-CODES.md 全局表为准；本文件是本台唯一定义处，
// 业务代码只许引用 ERR.* 与 fail()，不许散写 'E####' 字符串。
import wx from 'wx';

export var ERR = {
  E3001: '语音识别不可用',
  E3002: '语音识别没启动',
  E3003: '语音识别出错',
  E5001: '记录保存失败',
  E5002: '记录读取失败',
  E8001: '页面切换失败',
  E9001: '未分类错误'
};

export function errLine(code) {
  return code + ' ' + (ERR[code] || ERR.E9001);
}

export function codedError(code, message) {
  var e = new Error(message || ERR[code] || ERR.E9001);
  e.code = code;
  return e;
}

// 统一失败出口：写 lastError（码 + slug + 版本 + 原文截断），永不抛错。
export function fail(code, raw, slug, version) {
  var entry = {
    code: code,
    slug: slug || 'trace-reality',
    version: version || '1.0.0',
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* 静默 */ }
}
