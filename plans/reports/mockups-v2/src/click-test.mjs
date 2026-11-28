#!/usr/bin/env node
// Drives each prototype in headless Chrome with real mouse and keyboard events (Chrome DevTools Protocol),
// asserts the resulting state, and saves PNG screenshots. Needs Node 22+ and Google Chrome.
// Usage: node click-test.mjs
import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SHOTS = join(ROOT, 'screenshots');
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9377;
const STYLES = [['1', '1-toi-gian.html'], ['2', '2-tuong-phan-cao.html'], ['3', '3-vi-tuong-tac.html']];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
mkdirSync(SHOTS, { recursive: true });

const profile = mkdtempSync(join(tmpdir(), 'cb-click-'));
const chrome = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--hide-scrollbars', 'about:blank'], { stdio: 'ignore' });
let results = [], failed = 0;

async function connect() {
  for (let i = 0; i < 50; i++) {
    try {
      const t = await (await fetch(`http://127.0.0.1:${PORT}/json/new?about:blank`, { method: 'PUT' })).json();
      return t.webSocketDebuggerUrl;
    } catch { await sleep(200); }
  }
  throw new Error('Chrome did not start');
}

async function main() {
  const ws = new WebSocket(await connect());
  await new Promise((r) => (ws.onopen = r));
  let id = 0;
  const pending = new Map(), loads = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id); }
    if (d.method === 'Page.loadEventFired') loads.splice(0).forEach((f) => f());
  };
  const send = (method, params = {}) => new Promise((res) => { pending.set(++id, res); ws.send(JSON.stringify({ id, method, params })); });
  const ev = async (expr) => (await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true })).result?.result?.value;
  const size = (w, h) => send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 2, mobile: false });
  const nav = async (url) => { const p = new Promise((r) => loads.push(r)); await send('Page.navigate', { url }); await p; await sleep(350); };
  const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(SHOTS, name + '.png'), Buffer.from(r.result.data, 'base64')); };
  const mouse = (type, x, y, extra = {}) => send('Input.dispatchMouseEvent', { type, x, y, button: 'left', buttons: type === 'mouseReleased' ? 0 : 1, clickCount: 1, ...extra });
  // Find the first visible match, scroll it into view, and confirm it is the element actually under the pointer.
  const locate = (sel) => ev(`(() => { const el = [...document.querySelectorAll(${JSON.stringify(sel)})].find(e => e.offsetParent !== null && getComputedStyle(e).visibility !== 'hidden');
    if (!el) return null; el.scrollIntoView({ block: 'center' }); const r = el.getBoundingClientRect(); const x = r.left + r.width / 2, y = r.top + r.height / 2;
    const hit = document.elementFromPoint(x, y); return { x, y, hit: !!hit && (hit === el || el.contains(hit)) }; })()`);
  const click = async (sel) => {
    const p = await locate(sel);
    if (!p) throw new Error('not found or not visible: ' + sel);
    if (!p.hit) throw new Error('covered by another element: ' + sel);
    await mouse('mouseMoved', p.x, p.y, { buttons: 0 }); await mouse('mousePressed', p.x, p.y); await mouse('mouseReleased', p.x, p.y);
    await sleep(650);
  };
  const type = async (text) => { await send('Input.insertText', { text }); await sleep(150); };
  await send('Page.enable');
  await size(390, 844);

  for (const [n, file] of STYLES) {
    const url = (q) => pathToFileURL(join(ROOT, file)).href + '?embed=1&' + q;
    const check = async (name, fn) => {
      try { const ok = await fn(); if (ok !== true) throw new Error('got ' + JSON.stringify(ok)); results.push(`PASS  ${file}  ${name}`); }
      catch (e) { failed++; results.push(`FAIL  ${file}  ${name}  -> ${e.message}`); }
    };
    const sheet = () => ev(`document.querySelector('.screen').dataset.sheet || ''`);
    const title = () => ev(`document.querySelector('[data-st-title]').textContent`);
    const live = () => ev(`document.querySelector('#live').textContent`);

    await nav(url('state=home'));
    await check('home shows protection on with 3 sample numbers', async () => (await title()) === 'Đang bảo vệ' && (await ev('S.items.length')) === 3);
    await check('tap "Chặn số" opens the add sheet', async () => { await click('[data-act="add"]'); return (await sheet()) === 'add'; });
    await check('typing 028888 previews 100.000 numbers', async () => { await click('#num'); await type('028888'); return (await live()).includes('Sẽ chặn 100.000 số') && (await ev(`document.querySelector('#saveBtn').disabled`)) === false; });
    await check('tap "Chặn" saves the prefix, closes the sheet, shows a toast', async () => { await click('#saveBtn'); return (await sheet()) === '' && (await ev('S.items.length')) === 4 && (await ev('S.items[0].d')) === '028888' && (await ev(`document.querySelector('.toast').textContent`)).includes('Đã chặn 028 888'); });
    if (n === '3') await check('block feedback plays (confetti and shield stamp)', async () => { await click('[data-act="add"]'); await click('[data-act="fill:0907654321"], [data-act="fill:02838234567"]'); await click('#saveBtn'); const c = await ev(`document.querySelectorAll('.confetti').length`); await sleep(900); return c > 0 && (await ev('S.items.length')) === 5; });
    await check('full number previews "1 số" and saves', async () => { const before = await ev('S.items.length'); await click('[data-act="add"]'); await click('#num'); await type(n === '3' ? '0912345678' : '02838234567'); const l = await live(); await click('#saveBtn'); return l.includes('Sẽ chặn 1 số') && (await ev('S.items.length')) === before + 1; });
    await check('too-short prefix is refused and "Hủy" closes the sheet', async () => { await click('[data-act="add"]'); await click('[data-act="fill:0288"]'); const kind = await ev(`document.querySelector('#live').dataset.kind`); const dis = await ev(`document.querySelector('#saveBtn').disabled`); await click('#addSheet [data-act="close"]'); return kind === 'error' && dis === true && (await sheet()) === ''; });
    await check('tapping outside the sheet closes it', async () => { await click('[data-act="add"]'); const hit = await ev(`(() => { const e = document.elementFromPoint(195, 30); return e ? e.className : 'none'; })()`); if (hit !== 'scrim') throw new Error('element at tap point is ' + hit); await mouse('mouseMoved', 195, 30, { buttons: 0 }); await mouse('mousePressed', 195, 30); await mouse('mouseReleased', 195, 30); await sleep(600); return (await sheet()) === ''; });
    await check('row switch pauses and resumes a number', async () => { await click('.a-list .switch'); const off = await ev('S.items[0].on'); await click('.a-list .switch'); return off === false && (await ev('S.items[0].on')) === true; });
    if (n === '3') await check('swipe a row left, then "Bỏ chặn" removes it', async () => {
      const before = await ev('S.items.length'); const p = await locate('.a-list .row .main');
      await mouse('mouseMoved', p.x, p.y, { buttons: 0 }); await mouse('mousePressed', p.x, p.y);
      for (const dx of [20, 50, 90, 120]) await mouse('mouseMoved', p.x - dx, p.y);
      await mouse('mouseReleased', p.x - 120, p.y); await sleep(600);
      const open = await ev(`document.querySelectorAll('.row.open').length`); await shot('3-swipe');
      await click('.row.open .del'); return open === 1 && (await ev('S.items.length')) === before - 1;
    });
    await check('"?" opens the setup guide', async () => { await click('.a-help'); const s = await sheet(); await click('#setupSheet [data-act="close"]'); return s === 'setup'; });

    await nav(url('state=off'));
    await check('protection-off state is shown', async () => (await title()) === 'Chưa bật chặn');
    await check('"Bật ngay" opens setup; "Mở Cài đặt" turns protection on; "Xong" closes', async () => { await click('[data-st-cta]'); const s = await sheet(); await click('[data-act="setupgo"]'); const done = await ev(`!!document.querySelector('#setupSheet').dataset.done`); await click('#setupSheet .done .btn'); return s === 'setup' && done && (await sheet()) === '' && (await title()) === 'Đang bảo vệ'; });

    await nav(url('state=empty'));
    await check('empty state is shown', async () => (await title()) === 'Đã bật' && (await ev(`document.querySelector('.a-list .empty b').textContent`)) === 'Chưa chặn số nào');
    await check('first number can be added from empty', async () => { await click('[data-act="add"]'); await click('#num'); await type('0901234567'); await click('#saveBtn'); return (await ev('S.items.length')) === 1 && (await title()) === 'Đang bảo vệ'; });

    for (const [name, q] of [['home', 'state=home'], ['add-full', 'state=home&sheet=full'], ['add-prefix', 'state=home&sheet=prefix'], ['empty', 'state=empty'], ['off', 'state=off']]) {
      await nav(pathToFileURL(join(ROOT, file)).href + '?shot=1&' + q);
      await shot(`${n}-${name}`);
    }
  }
  // Comparison page: four phones, and each "Show" button must switch all of them.
  await size(1320, 1120);
  const index = pathToFileURL(join(ROOT, 'index.html')).href;
  const srcs = () => ev(`[...document.querySelectorAll('iframe')].map(f => f.getAttribute('src'))`);
  const ixcheck = async (name, fn) => { try { const ok = await fn(); if (ok !== true) throw new Error('got ' + JSON.stringify(ok)); results.push(`PASS  index.html  ${name}`); } catch (e) { failed++; results.push(`FAIL  index.html  ${name}  -> ${e.message}`); } };
  await nav(index); await sleep(1200);
  await ixcheck('shows four phones, original first', async () => { const s = await srcs(); return s.length === 4 && s[0].startsWith('../mockups/a-la-chan.html') && s.every((u) => u.includes('state=home')); });
  await shot('index');
  for (const [label, q, file] of [['Add a full number', 'state=home&sheet=full', 'index-add-full'], ['Add prefix 028888', 'state=home&sheet=prefix', 'index-add-prefix'], ['Empty', 'state=empty', 'index-empty'], ['Protection off', 'state=off', 'index-off']]) {
    await ixcheck(`"${label}" switches all four phones`, async () => { await click(`#bar button[data-q="${q}"]`); await sleep(1200); const s = await srcs(); await shot(file); return s.every((u) => u.endsWith(q)) && (await ev(`document.querySelector('#bar button[aria-pressed="true"]').dataset.q`)) === q; });
  }
  ws.close();
}

try { await main(); } catch (e) { failed++; results.push('ERROR ' + e.message); }
finally { chrome.kill('SIGTERM'); await sleep(300); rmSync(profile, { recursive: true, force: true }); }
console.log(results.join('\n'));
console.log(`\n${results.length - failed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
