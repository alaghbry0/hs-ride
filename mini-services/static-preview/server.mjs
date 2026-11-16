/**
 * static-preview/server.mjs — خادم المعاينة الثابت لتطبيق HS للنقل البري.
 * =============================================================================
 * خادم Node واحد بلا تبعيات: يقدم بناء Flutter Web (public/mobile_app)
 * في جذر البوابة (المنفذ 3000 خلف Caddy).
 *
 *   /            → تطبيق Flutter Web (index.html من public/mobile_app)
 *   /api/status  → {version, buildPresent, app} — فحص صحة للوكيل
 *   /logo.svg    → شعار HS من جذر public/
 *
 * - مسارات بلا امتداد تُسقط على index.html (SPA fallback).
 * - كاش الذاكرة يتحقق من mtime/size لكل ملف — إعادة البناء في منتصف
 *   الجلسة تظهر فوراً بعد تحديث الصفحة بلا إعادة تشغيل الخادم.
 * - حتى اكتمال البناء تُقدَّم بطاقة «المعاينة غير مبنية بعد» بدل الـ404.
 * =============================================================================
 */
import fs from "node:fs";
import pathMod from "node:path";
import http from "node:http";
import { fileURLToPath } from "node:url";

const __dirname = pathMod.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = pathMod.resolve(__dirname, "..", "..");
const APP_DIR = pathMod.join(PROJECT_ROOT, "public", "mobile_app");
const APP_INDEX = pathMod.join(APP_DIR, "index.html");
const PUBSPEC = pathMod.join(PROJECT_ROOT, "mobile_app", "pubspec.yaml");
const PORT = Number(process.env.PORT || 3000);

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".json": "application/json",
  ".webmanifest": "application/manifest+json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".css": "text/css; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
};

/** إصدار التطبيق من pubspec.yaml */
function appVersion() {
  try {
    const m = fs.readFileSync(PUBSPEC, "utf8").match(/^version:\s*(\S+)$/m);
    return m ? m[1] : "؟";
  } catch {
    return "؟";
  }
}

function buildExists() {
  return fs.existsSync(APP_INDEX);
}

/** كاش الذاكرة مع تحقق mtime/size — إعادة البناء تظهر فوراً بعد التحديث. */
const fileCache = new Map();
function readCached(full) {
  const st = fs.statSync(full);
  const hit = fileCache.get(full);
  if (hit && hit.mtime === st.mtimeMs && hit.size === st.size) return hit.buf;
  const buf = fs.readFileSync(full);
  fileCache.set(full, { mtime: st.mtimeMs, size: st.size, buf });
  return buf;
}

/** بطاقة «غير مبنى بعد» — تظهر بدل 404 حتى اكتمال أول بناء. */
function notBuiltPage() {
  const v = appVersion();
  return `<!DOCTYPE html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<title>HS للنقل البري — جارٍ التحضير</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body{margin:0;font-family:system-ui,'Segoe UI',Tahoma,sans-serif;background:#0E2A26;color:#fff;
       display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center}
  .card{background:rgba(255,255,255,.06);padding:40px 48px;border-radius:24px;max-width:420px}
  h1{font-size:22px;margin:0 0 10px} p{color:#b8d8d2;line-height:1.8;margin:0}
  .logo{width:72px;height:72px;border-radius:20px;background:linear-gradient(135deg,#00A98F,#00695C);
        display:flex;align-items:center;justify-content:center;font-weight:900;font-size:28px;margin:0 auto 18px}
  .meta{margin-top:14px;font-size:12px;color:#7fa8a1}
</style></head><body><div class="card">
<div class="logo">HS</div>
<h1>HS للنقل البري</h1>
<p>النسخة ${v} — بناء المعاينة قيد التنفيذ الآن.<br>حدّث الصفحة خلال دقيقة.</p>
<p class="meta">سيظهر التطبيق هنا فور اكتمال البناء.</p>
</div></body></html>`;
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");
  let pathname = decodeURIComponent(url.pathname);

  // فحص الصحة.
  if (pathname === "/api/status") {
    res.writeHead(200, { "Content-Type": "application/json", "Cache-Control": "no-store" });
    res.end(JSON.stringify({ app: "HS للنقل البري", version: appVersion(), buildPresent: buildExists() }));
    return;
  }

  // شعار الجذر.
  if (pathname === "/logo.svg") {
    const logo = pathMod.join(PROJECT_ROOT, "public", "logo.svg");
    if (fs.existsSync(logo)) {
      res.writeHead(200, { "Content-Type": "image/svg+xml", "Cache-Control": "no-store" });
      res.end(readCached(logo));
      return;
    }
  }

  if (!buildExists()) {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
    res.end(notBuiltPage());
    return;
  }

  // تقديم الملفات الثابتة من public/mobile_app مع SPA fallback.
  if (pathname === "/") pathname = "/index.html";
  let full = pathMod.normalize(pathMod.join(APP_DIR, pathname));
  if (!full.startsWith(APP_DIR)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }
  if (!fs.existsSync(full) || fs.statSync(full).isDirectory()) {
    // SPA fallback: كل مسار غير موجود يسقط على index.html.
    full = APP_INDEX;
  }
  const ext = pathMod.extname(full).toLowerCase();
  res.writeHead(200, {
    "Content-Type": MIME[ext] || "application/octet-stream",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
  });
  res.end(readCached(full));
});

server.listen(PORT, () => {
  console.log(`[static-preview] HS للنقل البري v${appVersion()} — http://127.0.0.1:${PORT}/`);
});
