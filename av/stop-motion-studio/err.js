// AV11 error-code system — the ONLY definition site in this project.
// Canonical table: ERROR-CODES.md at the repo root (fleet global
// table, registry: side chat 「Rokid开发环境」; local mirror at
// ~/workspace/rokid/ERROR-CODES.md). The project copy ERROR-CODES.md
// is an excerpt of the codes this agent uses; on any conflict the
// canonical table wins.
// Protocol (GO 2026-10-28, format finalised 23:22): the prefix is the
// SERIES code, concatenated with no separator — this agent shows
// "AVE#### + one line of explanation" in the big-text area; the user
// reports just the code. Codes never change meaning and are never
// reused. Raw error text is diagnostic garnish (truncated), never a
// substitute for a code. lastError stores the full series-prefixed code.
export var SERIES_PREFIX = 'AV';

export var ERR = {
  E1001: '相机打开失败',
  E1002: '相机权限未给',
  E1003: '拍照器不可用',
  E1004: '取景抓帧失败',
  E1005: '取景连续失败',
  E1006: '相机流中断',
  E2001: '拍帧抓帧失败',
  E2002: '画布创建失败',
  E2003: '编码失败（画布）',
  E2004: '编码失败（直编）',
  E2005: '编码转文本失败',
  E2006: '编码超时已切换',
  E2007: '无可用出帧路径',
  E2008: '内存帧读取失败',
  E2009: '单帧处理超时',
  E2010: '连续失败已停拍',
  E3001: '语音识别不可用',
  E3002: '语音识别没启动',
  E3003: '语音识别出错',
  E3004: '语音识别反复掉线',
  E3005: '播报失败',
  E4001: '没有可合成的帧',
  E4002: '帧解码失败',
  E4003: '播放绘制失败',
  E4004: '播放帧率过低',
  E4005: '帧数据丢失',
  E5001: '记录保存失败',
  E5002: '记录读取失败',
  E5003: '存储空间不足',
  E7006: '手势通道异常',
  E8001: '页面切换失败',
  E8002: '页面被系统回收',
  E9001: '未分类错误',
  E9002: '配置缺失'
};

export function errLabel(code) {
  return ERR[code] || ERR.E9001;
}

// Full series-prefixed code as stored in lastError and shown/spoken:
// "AVE2005" (= series AV + code E2005, concatenated, no separator)
export function fullCode(code) {
  return SERIES_PREFIX + code;
}

// Fixed on-screen format: "AVE2005 编码转文本失败"
export function errLine(code) {
  return SERIES_PREFIX + code + ' ' + errLabel(code);
}

// Build an Error that carries its (short) code through promise chains.
export function codedError(code, message) {
  var e = new Error(message || errLabel(code));
  e.code = code;
  return e;
}
