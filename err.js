// qr-capacity-probe error codes — the ONLY definition site in this
// project. Canonical table: ERROR-CODES.md at the repo root (fleet
// global table; new codes are assigned by the registry only). The bare
// code ("E####") is the only form used anywhere: on screen, in
// lastError, in reports. No prefix of any kind — the numeric segment
// is unique fleet-wide.

export var ERR = {
  E1001: '相机打开失败',
  E1002: '相机权限未给',
  E1003: '拍照器不可用',
  E1007: '相机设备不存在',
  E1008: '相机不可读',
  E1009: '拍照失败',
  E2002: '画布创建失败',
  E2003: '编码失败（画布）',
  E1010: '拍照模式不可用',
  E5001: '记录保存失败',
  E5002: '记录读取失败',
  E5003: '存储空间不足',
  E5005: '持久化不可用',
  E7004: '条码检测失败',
  E7005: '码制不支持',
  E7009: '条码检测器不可用',
  E9001: '未分类错误'
};

export function errLabel(code) {
  return ERR[code] || ERR.E9001;
}

// Fixed on-screen format: "E7004 条码检测失败" (bare code, no prefix).
export function errLine(code) {
  return code + ' ' + errLabel(code);
}

// Bare-code shape assertion (runtime self-check): every defined key
// must be exactly "E" + 4 digits — no prefix may ever creep back in.
export function selfCheck() {
  for (var k in ERR) {
    if (!/^E\d{4}$/.test(k)) return false;
  }
  return errLine('E7004') === 'E7004 条码检测失败';
}

try {
  if (!selfCheck() && typeof console !== 'undefined') console.warn('err.js self-check failed: non-bare code form');
} catch (e) { /* self-check must never break the agent */ }
