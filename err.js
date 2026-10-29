// err.js —— 真境探针的错误码单点定义 + 统一失败出口。
// 码义以仓库根目录 ERROR-CODES.md 全局表 v1.14.0 为准；本文件是本台
// 唯一定义处，业务代码只许引用 ERR.* 与 fail()，不许散写 'E####'。
// 唯一形态 = 裸码 E####（数字段全舰队唯一同义，不带任何前缀）。
// 总原则：错误处理不许制造新错误——fail() 全程不抛错，屏显/TTS/
// 写 lastError 各自失败各自静默吞掉。
import wx from 'wx';

export var SLUG = 'real-mud-probe';
export var VERSION = '1.0.0';

export var ERR = {
  CAM_OPEN: 'E1001',        // 相机打开失败
  CAM_DENIED: 'E1002',      // 相机权限未给
  CAPTURE_NA: 'E1003',      // 拍照器不可用
  CAM_MISSING: 'E1007',     // 相机设备不存在
  PHOTO: 'E1009',           // 拍照失败
  ENCODE_TEXT: 'E2013',     // 文本编码失败（arrayBuffer/分块 btoa 自身失败）
  SAVE: 'E5001',            // 记录保存失败
  LOAD: 'E5002',            // 记录读取失败
  LLM_NA: 'E6001',          // 大模型不可用
  LLM_REQ: 'E6002',         // 大模型请求失败
  LLM_TIMEOUT: 'E6003',     // 大模型超时
  IMG_INPUT: 'E6005',       // 图片输入失败
  RESP_PARSE: 'E6009',      // 响应解析失败（JSON 语法）
  LLM_OUTPUT: 'E6011',      // 大模型输出不可用（结构不符）
  SENSOR_NA: 'E7001',       // 朝向传感器不可用
  GEO_FAIL: 'E7002',        // 定位失败（error 2/3）
  GEO_DENIED: 'E7003',      // 定位权限未给（error 1）
  WORLD_AWARE: 'E7006',     // 手势通道异常（enableWorldAwareness 失败）
  SENSOR_NODATA: 'E7008',   // 传感器无数据（已启动超时无读数）
  NAV: 'E8001',             // 页面切换失败
  UNKNOWN: 'E9001'          // 未分类兜底
};

var MESSAGES = {
  E1001: '相机打开失败',
  E1002: '相机权限未给',
  E1003: '拍照器不可用',
  E1007: '相机设备不存在',
  E1009: '拍照失败',
  E2013: '编码转文本失败',
  E5001: '记录保存失败',
  E5002: '记录读取失败',
  E6001: '大模型不可用',
  E6002: '大模型请求失败',
  E6003: '大模型超时',
  E6005: '图片输入失败',
  E6009: '响应解析失败',
  E6011: '大模型输出不可用',
  E7001: '朝向传感器不可用',
  E7002: '定位失败',
  E7003: '定位权限未给',
  E7006: '手势通道异常',
  E7008: '传感器无数据',
  E8001: '页面切换失败',
  E9001: '未分类错误'
};

export function errLine(code) {
  return code + ' ' + (MESSAGES[code] || MESSAGES.E9001);
}

export function codedError(code, message) {
  var e = new Error(message || MESSAGES[code] || MESSAGES.E9001);
  e.code = code;
  return e;
}

// 页面把自己的屏显函数注册进来（大字码 + 一行说明）；err.js 不碰页面结构。
var _showOnScreen = null;
export function onShowError(fn) { _showOnScreen = fn; }

// 统一失败出口：写 lastError + 屏显（+可选 TTS 只读码），三处同一个码。
// raw 只进 lastError（截断 300 字），永不直接上屏。本函数永不抛错。
export function fail(code, raw, opts) {
  opts = opts || {};
  var entry = {
    code: code,
    slug: SLUG,
    version: VERSION,
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* 存储再失败也不许抛错 */ }
  try { if (_showOnScreen) _showOnScreen(code, MESSAGES[code] || MESSAGES.E9001); } catch (e) {}
  if (opts.speak) {
    try {
      if (typeof speechSynthesis !== 'undefined' && typeof SpeechSynthesisUtterance !== 'undefined') {
        speechSynthesis.speak(new SpeechSynthesisUtterance(code));
      }
    } catch (e) { /* 播报失败不再抛错 */ }
  }
  return entry;
}

// 裸码形状自检：ERR 里每个值必须恰好是 E + 4 位数字。
export function selfCheck() {
  for (var k in ERR) { if (!/^E\d{4}$/.test(ERR[k])) return false; }
  return true;
}
