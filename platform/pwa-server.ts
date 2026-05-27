// PWA proxy server — serves manifest.json + sw.js as static files and
// reverse-proxies everything else (including WebSocket upgrades) directly to
// OpenVSCode Server. No path prefix stripping: the browser URL and the
// upstream URL are identical, so OpenVSCode's own client-side routing works
// without any redirects.
//
// Run: node --experimental-strip-types pwa-server.ts
// Requires /app/package.json with {"type":"module"} so Node treats this as ESM.

import http  from "node:http";
import fs    from "node:fs";
import path  from "node:path";
import net   from "node:net";
import { fileURLToPath }        from "node:url";
import { request as httpRequest } from "node:http";

const PORT        = parseInt(process.env.PORT         ?? "5173", 10);
const VSCODE_PORT = parseInt(process.env.VSCODE_PORT  ?? "7777", 10);
const IDLE_MS     = parseInt(process.env.IDLE_MINUTES ?? "30",   10) * 60_000;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const publicDir = path.resolve(process.env.PWA_DIR ?? path.join(__dirname, "pwa"));

const MIME: Record<string, string> = {
  ".html":        "text/html; charset=utf-8",
  ".js":          "application/javascript",
  ".json":        "application/json",
  ".webmanifest": "application/manifest+json",
  ".css":         "text/css",
  ".png":         "image/png",
  ".svg":         "image/svg+xml",
  ".ico":         "image/x-icon",
  ".pdf":         "application/pdf",
};

// ── Idle shutdown ─────────────────────────────────────────────────────────────
let lastActivity = Date.now();
function touch() { lastActivity = Date.now(); }

setInterval(() => {
  if (Date.now() - lastActivity > IDLE_MS) {
    console.log(`Idle for ${IDLE_MS / 60_000} min — shutting down`);
    process.exit(0);
  }
}, 60_000).unref();

// ── Static files (PWA shell only — manifest + service worker) ─────────────────
function serveStatic(req: http.IncomingMessage, res: http.ServerResponse): void {
  const urlPath = (req.url ?? "/").split("?")[0];
  const full    = path.resolve(publicDir, "." + urlPath);

  if (!full.startsWith(publicDir + path.sep)) {
    res.writeHead(403); res.end("Forbidden"); return;
  }

  let stat: fs.Stats;
  try { stat = fs.statSync(full); }
  catch { res.writeHead(404); res.end("Not found"); return; }

  if (!stat.isFile()) { res.writeHead(404); res.end("Not found"); return; }

  const mime = MIME[path.extname(full)] ?? "application/octet-stream";
  res.writeHead(200, { "Content-Type": mime });
  fs.createReadStream(full)
    .on("error", () => { if (!res.writableEnded) res.end(); })
    .pipe(res);
}

// ── Reverse proxy → OpenVSCode Server ────────────────────────────────────────
function proxy(req: http.IncomingMessage, res: http.ServerResponse): void {
  touch();

  const proxyReq = httpRequest(
    {
      hostname: "127.0.0.1",
      port:     VSCODE_PORT,
      path:     req.url,
      method:   req.method,
      headers:  req.headers,
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode ?? 502, proxyRes.headers);
      proxyRes.pipe(res);
    },
  );

  proxyReq.on("error", () => {
    if (!res.headersSent) {
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(`<!DOCTYPE html>
<html><head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="1">
  <title>Starting…</title>
  <style>
    body{margin:0;background:#1e1e2e;color:#cdd6f4;font-family:monospace;
         display:flex;align-items:center;justify-content:center;height:100vh;gap:1rem}
  </style>
</head><body>
  <span>⏳</span><span>Starting editor…</span>
</body></html>`);
    }
  });

  req.on("error", () => proxyReq.destroy());
  req.pipe(proxyReq);
}

// Only manifest.json and sw.js are served from the local filesystem.
// Everything else — including / — is proxied straight through to OpenVSCode
// so its own routing and resource loading work without any prefix confusion.
const PWA_STATIC = new Set(["/manifest.json", "/sw.js"]);

// Workspace root — matches the volume mount in the container
const WORKSPACE_ROOT = process.env.WORKSPACE_ROOT ?? "/workspace";

// ── Workspace file server ─────────────────────────────────────────────────────
// GET /workspace-files/<path> → serves the file from WORKSPACE_ROOT/<path>
// Used by extensions to open PDFs and other assets in the host browser without
// going through OpenVSCode's internal resource port (which isn't exposed).
function serveWorkspaceFile(req: http.IncomingMessage, res: http.ServerResponse): void {
  const PREFIX = "/workspace-files";
  const raw    = (req.url ?? "").split("?")[0];
  const rel    = decodeURIComponent(raw.slice(PREFIX.length)) || "/";
  const full   = path.resolve(WORKSPACE_ROOT, "." + rel);

  // Path traversal guard
  if (!full.startsWith(WORKSPACE_ROOT + path.sep) && full !== WORKSPACE_ROOT) {
    res.writeHead(403); res.end("Forbidden"); return;
  }

  let stat: fs.Stats;
  try { stat = fs.statSync(full); }
  catch { res.writeHead(404); res.end("Not found"); return; }

  if (!stat.isFile()) { res.writeHead(404); res.end("Not found"); return; }

  const mime = MIME[path.extname(full).toLowerCase()] ?? "application/octet-stream";
  res.writeHead(200, {
    "Content-Type":  mime,
    "Cache-Control": "no-cache",
    "Content-Length": stat.size,
  });
  fs.createReadStream(full)
    .on("error", () => { if (!res.writableEnded) res.end(); })
    .pipe(res);
}

const server = http.createServer((req, res) => {
  const urlPath = (req.url ?? "/").split("?")[0];
  if (PWA_STATIC.has(urlPath)) {
    serveStatic(req, res);
    return;
  }
  if (urlPath.startsWith("/workspace-files/")) {
    serveWorkspaceFile(req, res);
    return;
  }
  proxy(req, res);
});

// ── WebSocket upgrade — raw TCP tunnel so the VSCode protocol is untouched ────
server.on("upgrade", (req, socket, head) => {
  touch();
  // Keep the idle timer alive for as long as the WebSocket is open
  const keepAliveInterval = setInterval(touch, 60_000);
  socket.once("close", () => clearInterval(keepAliveInterval));

  // TCP keepalive prevents the Apple Container bridge from dropping idle connections
  socket.setKeepAlive(true, 20_000);

  const upstream = net.connect(VSCODE_PORT, "127.0.0.1", () => {
    upstream.setKeepAlive(true, 20_000);

    const headers =
      `${req.method} ${req.url} HTTP/1.1\r\n` +
      Object.entries(req.headers)
        .map(([k, v]) => `${k}: ${Array.isArray(v) ? v.join(", ") : v}`)
        .join("\r\n") +
      "\r\n\r\n";

    upstream.write(headers);
    if (head?.length) upstream.write(head);
    upstream.pipe(socket);
    socket.pipe(upstream);
    socket.on("error",   () => upstream.destroy());
    upstream.on("error", () => socket.destroy());
  });

  upstream.on("error", () => socket.destroy());
});

server.listen(PORT, "0.0.0.0", () =>
  console.log(`PWA proxy → http://localhost:${PORT}  (OpenVSCode on :${VSCODE_PORT}, idle: ${IDLE_MS / 60_000} min)`),
);
