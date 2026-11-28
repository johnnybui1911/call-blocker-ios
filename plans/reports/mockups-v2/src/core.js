// Shared prototype logic. Sample data only: nothing here talks to iOS.
const Q = new URLSearchParams(location.search);
const SAMPLE = [
  { d: '0283999', note: 'Tổng đài quảng cáo', on: true },
  { d: '0901234567', note: 'Môi giới bất động sản', on: true },
  { d: '0247300', note: '', on: false },
];
const LIMIT = 2000000;
const S = { prot: 'on', items: [], fresh: -1, name: 'home' };
window.S = S;
const $ = (s) => document.querySelector(s);
const $$ = (s) => document.querySelectorAll(s);
const nf = (n) => n.toLocaleString('vi-VN');

function norm(raw) {
  let d = String(raw).replace(/\D/g, '');
  if (d.startsWith('0084')) d = '0' + d.slice(4);
  else if (d.startsWith('84')) d = '0' + d.slice(2);
  return d;
}
const fullLen = (d) => (d.startsWith('02') ? 11 : 10);
function fmt(d) {
  const c = d.startsWith('02') ? [3, 7] : [3, 6];
  return [d.slice(0, c[0]), d.slice(c[0], c[1]), d.slice(c[1])].filter(Boolean).join(' ');
}
const countOf = (d) => Math.pow(10, fullLen(d) - d.length);
const isOne = (d) => d.length === fullLen(d);
const total = () => S.items.filter((i) => i.on).reduce((a, i) => a + countOf(i.d), 0);

// Decide what a typed value means. Copy comes from the wording table.
function analyze(raw) {
  const d = norm(raw);
  if (!d) return { kind: 'empty', title: 'Nhập số bạn muốn chặn.', msg: 'Một số đầy đủ, hoặc ít nhất 6 số đầu để chặn cả dải số.' };
  if (d[0] !== '0') return { kind: 'error', msg: 'Hiện chỉ chặn được số Việt Nam (bắt đầu bằng 0 hoặc +84).' };
  const full = fullLen(d);
  if (d.length > full) return { kind: 'error', msg: 'Số này dài quá. Kiểm tra lại giúp nhé.' };
  if (d.length < 6) return { kind: 'error', msg: 'Nhập ít nhất 6 số đầu, ví dụ 028 888. iPhone không cho chặn dải số rộng hơn.' };
  if (d.length === full) return { kind: 'one', d, title: 'Sẽ chặn 1 số: ' + fmt(d), msg: 'Chỉ chặn đúng số này.' };
  const pad = full - d.length;
  return { kind: 'prefix', d, title: 'Sẽ chặn ' + nf(countOf(d)) + ' số',
    msg: 'Mọi số bắt đầu bằng ' + fmt(d) + ', từ ' + fmt(d + '0'.repeat(pad)) + ' đến ' + fmt(d + '9'.repeat(pad)) + '.' };
}

function statusText() {
  if (S.prot === 'off') return { title: 'Chưa bật chặn', sub: 'Còn một bước trong Cài đặt để bắt đầu chặn.', cta: 'Bật ngay' };
  if (!S.items.length) return { title: 'Đã bật', sub: 'Thêm số đầu tiên để bắt đầu chặn.' };
  return { title: 'Đang bảo vệ', sub: 'Đang chặn ' + nf(total()) + ' số.' };
}

function listHTML() {
  if (!S.items.length) return '<div class="empty"><b>Chưa chặn số nào</b><span>Nhập một số, hoặc vài số đầu để chặn cả dải số.</span></div>';
  return '<div class="list">' + S.items.map((it, i) => {
    const one = isOne(it.d);
    return '<div class="row' + (it.on ? '' : ' paused') + (i === S.fresh ? ' new' : '') + '">' +
      '<button class="del" data-act="remove:' + i + '">Bỏ chặn</button><div class="row-in"><div class="main">' +
      '<span class="tag">' + (one ? 'Một số' : 'Đầu số') + '</span>' +
      '<div class="n num">' + fmt(it.d) + (one ? '' : '…') + '</div>' +
      (one ? '' : '<div class="d num">' + nf(countOf(it.d)) + ' số bắt đầu bằng ' + fmt(it.d) + '</div>') +
      (it.note ? '<div class="note">' + it.note.replace(/</g, '&lt;') + '</div>' : '') +
      '</div><button class="switch" role="switch" aria-checked="' + it.on + '" data-act="toggle:' + i +
      '" aria-label="' + (it.on ? 'Tạm ngưng chặn ' : 'Chặn lại ') + fmt(it.d) + '"></button></div></div>';
  }).join('') + '</div>';
}

const SHIELD = '<svg viewBox="0 0 132 148" aria-hidden="true"><path class="body" d="M66 4 120 24v46c0 36-23 60-54 74C35 130 12 106 12 70V24Z"/>' +
  '<path class="shine" d="M66 4 12 24v46c0 20 7 36 19 49C28 96 30 54 66 4Z"/><circle class="core" cx="66" cy="72" r="30"/>' +
  '<path class="mark v" d="m52 73 10 10 19-21"/><path class="mark x" d="M66 54v22M66 88v2"/></svg>';

const setAll = (sel, text) => $$(sel).forEach((e) => (e.textContent = text));
function render() {
  $('.screen').dataset.prot = S.prot;
  const st = statusText(), n = S.items.length, t = total();
  setAll('[data-st-title]', st.title);
  setAll('[data-st-sub]', st.sub);
  $$('[data-st-cta]').forEach((e) => { e.hidden = !st.cta; e.textContent = st.cta || ''; });
  setAll('[data-count]', 'Số đang chặn (' + n + ')');
  setAll('[data-n]', n);
  setAll('[data-total]', nf(t));
  setAll('[data-cap]', nf(Math.round((t / LIMIT) * 1000) / 10) + '%');
  $$('[data-list]').forEach((e) => (e.innerHTML = listHTML()));
  $$('.shield:empty').forEach((e) => (e.innerHTML = SHIELD));
  $$('[data-act^="state:"]').forEach((b) => b.setAttribute('aria-pressed', b.dataset.act === 'state:' + S.name));
  if (window.onRender) window.onRender(S);
  S.fresh = -1;
}
function setState(name) {
  S.name = name;
  S.prot = name === 'off' ? 'off' : 'on';
  S.items = name === 'empty' ? [] : SAMPLE.map((x) => ({ ...x }));
  closeAll();
  render();
}
function closeAll() { delete $('.screen').dataset.sheet; }
function openSheet(name) {
  $('.screen').dataset.sheet = name;
  if (name === 'setup') delete $('#setupSheet').dataset.done;
}
function toast(msg) {
  const t = $('.toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(toast.t);
  toast.t = setTimeout(() => t.classList.remove('show'), 2200);
}
function block(d, note) {
  S.items.unshift({ d, note: note || '', on: true });
  S.fresh = 0;
  closeAll();
  render();
  toast('Đã chặn ' + fmt(d) + '.');
  if (window.onBlocked) window.onBlocked(d);
}
function updateLive() {
  const a = analyze($('#num').value), live = $('#live');
  live.dataset.kind = a.kind;
  live.innerHTML = (a.title ? '<b class="num">' + a.title + '</b>' : '') + a.msg;
  $('#saveBtn').disabled = !a.d;
}
function openAdd(prefill, heard) {
  $('#num').value = prefill ? fmt(norm(prefill)) : '';
  $('#note').value = '';
  $('#heard').hidden = !heard;
  $('#heard').textContent = heard ? 'Đã nghe: “' + heard + '”' : '';
  updateLive();
  openSheet('add');
}

document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-act]');
  if (!el) return;
  const [act, arg] = el.dataset.act.split(':');
  if (act === 'state') setState(arg);
  else if (act === 'add') openAdd(arg);
  else if (act === 'fill') { $('#num').value = fmt(arg); updateLive(); }
  else if (act === 'save') { const a = analyze($('#num').value); if (a.d) block(a.d, $('#note').value); }
  else if (act === 'block') block(arg, el.dataset.note);
  else if (act === 'toggle') {
    const it = S.items[+arg];
    it.on = !it.on;
    render();
    toast((it.on ? 'Đang chặn ' : 'Đã tạm ngưng chặn ') + fmt(it.d) + '.');
  }
  else if (act === 'remove') { const it = S.items.splice(+arg, 1)[0]; render(); toast('Đã bỏ chặn ' + fmt(it.d) + '.'); }
  else if (act === 'setup') openSheet('setup');
  else if (act === 'list') openSheet('list');
  else if (act === 'setupgo') { S.prot = 'on'; S.name = ''; $('#setupSheet').dataset.done = '1'; render(); }
  else if (act === 'close') closeAll();
});

document.addEventListener('DOMContentLoaded', () => {
  if (Q.has('embed') || Q.has('shot')) document.body.classList.add('bare');
  if (Q.has('shot')) document.body.classList.add('still');
  $('#num').addEventListener('input', updateLive);
  setState(Q.get('state') || 'home');
  const sheet = Q.get('sheet');
  if (sheet) openAdd(sheet === 'prefix' ? '028888' : '02838234567', window.HEARD && window.HEARD[sheet]);
});
