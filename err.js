// storage-probe error codes — the ONLY definition site in this project.
// Canonical table: ERROR-CODES.md at the repo root (fleet global table;
// new codes are assigned by the registry only). The bare code ("E####")
// is the only form used anywhere: on screen, in lastError, in reports.
// No prefix of any kind — the numeric segment is unique fleet-wide.

export var ERR = {
  E5001: '记录保存失败',
  E5002: '记录读取失败',
  E5003: '存储空间不足',
  E5005: '持久化不可用',
  E9001: '未分类错误'
};

export function errLabel(code) {
  return ERR[code] || ERR.E9001;
}

// Fixed on-screen format: "E5003 存储空间不足" (bare code, no prefix).
export function errLine(code) {
  return code + ' ' + errLabel(code);
}

// Bare-code shape assertion (runtime self-check): every defined key
// must be exactly "E" + 4 digits — no prefix may ever creep back in.
export function selfCheck() {
  for (var k in ERR) {
    if (!/^E\d{4}$/.test(k)) return false;
  }
  return errLine('E5003') === 'E5003 存储空间不足';
}

try {
  if (!selfCheck() && typeof console !== 'undefined') console.warn('err.js self-check failed: non-bare code form');
} catch (e) { /* self-check must never break the agent */ }
