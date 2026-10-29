// trace-probe-seals 错误码单点定义（描红系列壳 v1）
// 码义以仓库根 ERROR-CODES.md 全局表为准；本文件是本台唯一定义处，
// 业务代码只许引用 ERR.* 与 fail()，不许散写 'E####' 字符串。
import wx from 'wx';

export var ERR = {
  E1001: '相机打开失败',
  E1002: '相机权限未给',
  E1003: '拍照器不可用',
  E1007: '相机设备不存在',
  E1009: '拍照失败',
  E2002: '画布创建失败',
  E2013: '文本编码失败',
  E5001: '记录保存失败',
  E5002: '记录读取失败',
  E6001: '大模型不可用',
  E6002: '大模型请求失败',
  E6011: '大模型输出不可用',
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
    slug: slug || 'trace-probe-seals',
    version: version || '1.0.0',
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* 存储再失败也不许抛错 */ }
  return entry;
}
