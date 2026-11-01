// overlay.js —— 现实合影的叠加画法（取景页与纯净页共用同一份画法，
// 保证取景时看到的样子就是截图里合成的样子）。
// 画布坐标系 480 宽；高度由页面传入（取景页 296、纯净页 352）。
// 颜色只用绿色阶；气泡填充半透明，让现实透出来、字又读得清。
var BRIGHT = '#7dff9e';
var MID = '#40ff5e';
var DIM = 'rgba(64,255,94,0.55)';
var FILL = 'rgba(4,20,10,0.55)';
var SCALES = [0.85, 1, 1.18];

function rrect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.arc(x + w - r, y + r, r, -Math.PI / 2, 0);
  ctx.lineTo(x + w, y + h - r);
  ctx.arc(x + w - r, y + h - r, r, 0, Math.PI / 2);
  ctx.lineTo(x + r, y + h);
  ctx.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI);
  ctx.lineTo(x, y + r);
  ctx.arc(x + r, y + r, r, Math.PI, Math.PI * 1.5);
  ctx.closePath();
}

function wrap(text, perLine, maxLines) {
  var t = String(text || '');
  var out = [];
  for (var i = 0; i < t.length && out.length < maxLines; i += perLine) out.push(t.slice(i, i + perLine));
  if (t.length > perLine * maxLines && out.length) out[out.length - 1] = out[out.length - 1].slice(0, perLine - 1) + '…';
  if (!out.length) out.push('');
  return out;
}

function drawLines(ctx, lines, cx, topY, font) {
  ctx.font = font + 'px sans-serif';
  ctx.fillStyle = BRIGHT;
  for (var i = 0; i < lines.length; i++) {
    var w = lines[i].length * font;
    ctx.fillText(lines[i], cx - w / 2, topY + font * (i * 1.4 + 1.02));
  }
}

function bubbleBox(ctx, bx, by, bw, text, font, dashed) {
  var perLine = Math.max(2, Math.floor((bw - 30) / font));
  var lines = wrap(text, perLine, 3);
  var bh = lines.length * font * 1.4 + 20;
  if (dashed && typeof ctx.setLineDash === 'function') { try { ctx.setLineDash([7, 5]); } catch (e) {} }
  rrect(ctx, bx, by, bw, bh, 14);
  ctx.fillStyle = FILL; ctx.fill();
  ctx.strokeStyle = BRIGHT; ctx.lineWidth = 2; ctx.stroke();
  if (dashed && typeof ctx.setLineDash === 'function') { try { ctx.setLineDash([]); } catch (e) {} }
  drawLines(ctx, lines, bx + bw / 2, by + (bh - lines.length * font * 1.4) / 2 - font * 0.02, font);
  return bh;
}

function tail(ctx, x1, x2, yTop, tipX, tipY) {
  ctx.beginPath();
  ctx.moveTo(x1, yTop); ctx.lineTo(x2, yTop); ctx.lineTo(tipX, tipY); ctx.closePath();
  ctx.fillStyle = FILL; ctx.fill();
  ctx.strokeStyle = BRIGHT; ctx.lineWidth = 2; ctx.stroke();
}

function aimDot(ctx, x, y) {
  ctx.beginPath(); ctx.arc(x, y, 4, 0, Math.PI * 2);
  ctx.strokeStyle = MID; ctx.lineWidth = 1.6; ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(x - 10, y); ctx.lineTo(x - 6, y); ctx.moveTo(x + 6, y); ctx.lineTo(x + 10, y);
  ctx.moveTo(x, y - 10); ctx.lineTo(x, y - 6); ctx.moveTo(x, y + 6); ctx.lineTo(x, y + 10);
  ctx.stroke();
}

// opts: { guides: bool, count: 0|3|2|1, dateStr: '' }
export function drawOverlay(ctx, W, H, scene, sess, opts) {
  opts = opts || {};
  var s = SCALES[sess.size] || 1;
  var kind = scene.kind;
  ctx.fillStyle = '#000000';
  ctx.fillRect(0, 0, W, H);

  if (kind === 'bubble') {
    var font = Math.round(20 * s);
    var bw = Math.min(320 * s, W - 40);
    var bx = (W - bw) / 2, by = 22;
    var bh = bubbleBox(ctx, bx, by, bw, sess.textA, font, false);
    tail(ctx, W / 2 - 11, W / 2 + 11, by + bh - 2, W / 2, by + bh + 28);
    if (opts.guides) aimDot(ctx, W / 2, by + bh + 44);
  } else if (kind === 'duo') {
    var f2 = Math.round(17 * s);
    var w2 = 198 * s;
    var hA = bubbleBox(ctx, 14, 22, w2, sess.textA, f2, false);
    tail(ctx, 14 + w2 * 0.55, 14 + w2 * 0.8, 22 + hA - 2, 14 + w2 * 0.72, 22 + hA + 24);
    var hB = bubbleBox(ctx, W - 14 - w2, 22, w2, sess.textB, f2, false);
    tail(ctx, W - 14 - w2 * 0.8, W - 14 - w2 * 0.55, 22 + hB - 2, W - 14 - w2 * 0.72, 22 + hB + 24);
    if (opts.guides) { aimDot(ctx, 14 + w2 * 0.72, 22 + hA + 40); aimDot(ctx, W - 14 - w2 * 0.72, 22 + hB + 40); }
  } else if (kind === 'thought') {
    var f3 = Math.round(19 * s);
    var w3 = Math.min(320 * s, W - 40);
    var x3 = (W - w3) / 2, y3 = 22;
    var h3 = bubbleBox(ctx, x3, y3, w3, sess.textA, f3, true);
    ctx.beginPath(); ctx.arc(W / 2 - 26, y3 + h3 + 12, 5, 0, Math.PI * 2);
    ctx.strokeStyle = BRIGHT; ctx.lineWidth = 1.8; ctx.stroke();
    ctx.beginPath(); ctx.arc(W / 2 - 40, y3 + h3 + 25, 3, 0, Math.PI * 2); ctx.stroke();
    if (opts.guides) aimDot(ctx, W / 2 - 48, y3 + h3 + 38);
  } else if (kind === 'plate') {
    var w4 = 250 * s, h4 = 48 * s, x4 = (W - w4) / 2, y4 = 40;
    rrect(ctx, x4, y4, w4, h4, 10);
    ctx.fillStyle = FILL; ctx.fill();
    ctx.strokeStyle = BRIGHT; ctx.lineWidth = 2.2; ctx.stroke();
    drawLines(ctx, [String(sess.textA || '')], W / 2, y4 + (h4 - Math.round(21 * s) * 1.4) / 2, Math.round(21 * s));
    tail(ctx, W / 2 - 10, W / 2 + 10, y4 + h4 - 2, W / 2, y4 + h4 + 16);
    if (opts.guides) aimDot(ctx, W / 2, y4 + h4 + 30);
  } else if (kind === 'banner') {
    var h5 = 56 * s, y5 = 12;
    rrect(ctx, 10, y5, W - 20, h5, 12);
    ctx.fillStyle = FILL; ctx.fill();
    ctx.strokeStyle = BRIGHT; ctx.lineWidth = 2.2; ctx.stroke();
    ctx.font = Math.round(20 * s) + 'px sans-serif';
    ctx.fillStyle = MID;
    ctx.fillText('★', 24, y5 + h5 / 2 + 7 * s);
    ctx.fillText('★', W - 48, y5 + h5 / 2 + 7 * s);
    drawLines(ctx, [String(sess.textA || '')], W / 2, y5 + (h5 - Math.round(25 * s) * 1.4) / 2, Math.round(25 * s));
  } else if (kind === 'frame') {
    ctx.strokeStyle = BRIGHT; ctx.lineWidth = 3;
    ctx.strokeRect(8, 8, W - 16, H - 16);
    ctx.strokeStyle = DIM; ctx.lineWidth = 1;
    ctx.strokeRect(15, 15, W - 30, H - 30);
    var barY = H - 48;
    ctx.fillStyle = FILL; ctx.fillRect(8, barY, W - 16, 40);
    ctx.strokeStyle = BRIGHT; ctx.lineWidth = 1.4; ctx.strokeRect(8, barY, W - 16, 40);
    ctx.font = '16px sans-serif'; ctx.fillStyle = BRIGHT;
    ctx.fillText(String(sess.textA || ''), 22, barY + 26);
    var d = String(opts.dateStr || '');
    ctx.fillStyle = MID;
    ctx.fillText(d, W - 22 - d.length * 8.6, barY + 26);
  }

  if (opts.guides) {
    ctx.strokeStyle = DIM; ctx.lineWidth = 1.6;
    var m = 6, a = 18;
    ctx.beginPath();
    ctx.moveTo(m, m + a); ctx.lineTo(m, m); ctx.lineTo(m + a, m);
    ctx.moveTo(W - m - a, m); ctx.lineTo(W - m, m); ctx.lineTo(W - m, m + a);
    ctx.moveTo(m, H - m - a); ctx.lineTo(m, H - m); ctx.lineTo(m + a, H - m);
    ctx.moveTo(W - m - a, H - m); ctx.lineTo(W - m, H - m); ctx.lineTo(W - m, H - m - a);
    ctx.stroke();
    ctx.font = '11px sans-serif'; ctx.fillStyle = DIM;
    var hint = '对准后进纯净页截图 · 画面里只剩叠加';
    var hintY = (kind === 'frame') ? H - 58 : H - 8;
    ctx.fillText(hint, (W - hint.length * 11) / 2, hintY);
  }

  if (opts.count && opts.count > 0) {
    ctx.font = '64px sans-serif'; ctx.fillStyle = BRIGHT;
    ctx.fillText(String(opts.count), W / 2 - 18, H / 2 - 30);
    ctx.font = '15px sans-serif'; ctx.fillStyle = MID;
    var t = '保持不动';
    ctx.fillText(t, (W - t.length * 15) / 2, H / 2 + 8);
  }

  try { ctx.flush(); } catch (e) { /* 预览运行时无 flush 时忽略 */ }
}
