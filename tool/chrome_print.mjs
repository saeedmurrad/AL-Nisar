#!/usr/bin/env node
// Drive Chrome's DevTools Protocol to print a local HTML file to PDF *with a
// page-number footer*. The `--print-to-pdf` CLI flag cannot do footers; only
// Page.printToPDF's displayHeaderFooter/footerTemplate can.
//
// Usage: node tool/chrome_print.mjs <devtools-port> <file-url> <out.pdf> [totalPagesLabel]
// Requires Node >= 22 for the global WebSocket. No npm dependencies.

import { writeFileSync } from 'node:fs';

const [port, fileUrl, outPath] = process.argv.slice(2);
if (!port || !fileUrl || !outPath) {
  console.error('usage: chrome_print.mjs <port> <file-url> <out.pdf>');
  process.exit(2);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function browserWsUrl() {
  // Chrome needs a moment to open the debugging port after launch.
  for (let i = 0; i < 60; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/json/version`);
      const json = await res.json();
      if (json.webSocketDebuggerUrl) return json.webSocketDebuggerUrl;
    } catch {
      // not listening yet
    }
    await sleep(500);
  }
  throw new Error(`Chrome never opened a devtools port on ${port}`);
}

class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    this.listeners = [];
    ws.addEventListener('message', (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.id != null && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
      } else if (msg.method) {
        for (const l of this.listeners) l(msg);
      }
    });
  }
  send(method, params = {}, sessionId) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params, sessionId }));
    });
  }
  once(method, sessionId) {
    return new Promise((resolve) => {
      const l = (msg) => {
        if (msg.method === method && (!sessionId || msg.sessionId === sessionId)) {
          this.listeners = this.listeners.filter((x) => x !== l);
          resolve(msg.params);
        }
      };
      this.listeners.push(l);
    });
  }
}

const wsUrl = await browserWsUrl();
const ws = new WebSocket(wsUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener('open', resolve, { once: true });
  ws.addEventListener('error', reject, { once: true });
});

const cdp = new Cdp(ws);
const { targetId } = await cdp.send('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await cdp.send('Target.attachToTarget', { targetId, flatten: true });

await cdp.send('Page.enable', {}, sessionId);
const loaded = cdp.once('Page.loadEventFired', sessionId);
await cdp.send('Page.navigate', { url: fileUrl }, sessionId);
await loaded;

// Let the embedded fonts finish loading before laying out for print; Nastaliq
// metrics differ enough from the fallback to change where pages break.
await cdp.send(
  'Runtime.evaluate',
  { expression: 'document.fonts.ready.then(() => true)', awaitPromise: true },
  sessionId,
);
await sleep(1500);

const footer = `
  <div style="width:100%;font-family:Georgia,'Times New Roman',serif;font-size:9px;
              color:#000;text-align:center;margin:0 16mm;padding-top:2mm;">
    <span class="pageNumber"></span>
  </div>`;

const { data } = await cdp.send(
  'Page.printToPDF',
  {
    paperWidth: 8.27, // A4
    paperHeight: 11.69,
    marginTop: 0.71, // 18mm
    marginBottom: 0.71,
    marginLeft: 0.63, // 16mm
    marginRight: 0.63,
    printBackground: true,
    preferCSSPageSize: false,
    displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate: footer,
  },
  sessionId,
);

writeFileSync(outPath, Buffer.from(data, 'base64'));
console.log(`wrote ${outPath}`);
ws.close();
process.exit(0);
