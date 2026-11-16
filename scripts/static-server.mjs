#!/usr/bin/env node
// static-server.mjs — zero-dependency static server for the Flutter web
// build. Use it when the template runs STANDALONE (no gateway-hub): it
// serves build/web on PORT (default 3000) with correct MIME types,
// no-store caching, an SPA fallback for deep links and permissive CORS —
// everything a sandbox preview proxy chain needs.
//
// Env: PORT (default 3000), ROOT (default ./build/web), BASE (default '')
//      — set BASE=/flutter if you serve the app under a subpath and built
//      it with --base-href /flutter/.

import http from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join, normalize, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT || 3000);
const BASE = (process.env.BASE || '').replace(/\/+$/, '');
const ROOT = process.env.ROOT || join(HERE, '..', 'build', 'web');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.manifest': 'application/json',
  '.bin': 'application/octet-stream',
  '.map': 'application/json',
  '.symbols': 'application/octet-stream',
  '.part': 'application/octet-stream',
};

const server = http.createServer((req, res) => {
  let pathname = (req.url || '/').split('?')[0];
  if (BASE && pathname === BASE) {
    res.writeHead(301, { location: `${BASE}/` });
    res.end();
    return;
  }
  if (BASE && pathname.startsWith(`${BASE}/`)) {
    pathname = pathname.slice(BASE.length) || '/';
  }
  if (pathname === '/' || pathname === '') pathname = '/index.html';

  const file = normalize(join(ROOT, pathname));
  if (!file.startsWith(ROOT + sep)) {
    res.writeHead(403, { 'access-control-allow-origin': '*' });
    res.end('forbidden');
    return;
  }

  const target =
    existsSync(file) && statSync(file).isFile()
      ? file
      : join(ROOT, 'index.html'); // SPA fallback

  if (!existsSync(target)) {
    res.writeHead(404, { 'access-control-allow-origin': '*' });
    res.end('not found — run scripts/build-web.sh first');
    return;
  }

  const headers = {
    'content-type': MIME[extname(target)] || 'application/octet-stream',
    'cache-control': 'no-store',
    'access-control-allow-origin': '*',
  };
  if (req.method === 'HEAD') {
    res.writeHead(200, headers);
    res.end();
    return;
  }
  res.writeHead(200, headers);
  createReadStream(target).pipe(res);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[static-server] :${PORT} serving ${ROOT}${BASE ? ` under ${BASE}/` : ''}`);
});
