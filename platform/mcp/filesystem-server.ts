// MCP Filesystem Server — exposes read-file and list-directory tools to any
// MCP client (e.g. a VSCode extension) over stdin/stdout using JSON-RPC 2.0.
//
// Run with Node 25: node --experimental-strip-types mcp/filesystem-server.ts
// Environment variables:
//   MCP_WORKSPACE — root directory the server is allowed to access (required)
//   MCP_PORT      — if set, listen on a TCP port instead of stdio

import fs      from "node:fs";
import path    from "node:path";
import net     from "node:net";
import process from "node:process";

const WORKSPACE = process.env.MCP_WORKSPACE ?? "/workspace";

// ── JSON-RPC 2.0 types ────────────────────────────────────────────────────────

interface JsonRpcRequest {
  jsonrpc: "2.0";
  id:      number | string | null;
  method:  string;
  params?: unknown;
}

interface JsonRpcResponse {
  jsonrpc: "2.0";
  id:      number | string | null;
  result?: unknown;
  error?:  { code: number; message: string; data?: unknown };
}

// ── Tool definitions (MCP tools/list response) ────────────────────────────────

const TOOLS = [
  {
    name:        "read_file",
    description: "Read the text content of a file inside the workspace",
    inputSchema: {
      type:       "object",
      properties: {
        path: { type: "string", description: "Path relative to workspace root" },
      },
      required: ["path"],
    },
  },
  {
    name:        "list_directory",
    description: "List files and directories at a path inside the workspace",
    inputSchema: {
      type:       "object",
      properties: {
        path: { type: "string", description: "Path relative to workspace root (default: .)" },
      },
    },
  },
  {
    name:        "write_file",
    description: "Write or overwrite a text file inside the workspace",
    inputSchema: {
      type:       "object",
      properties: {
        path:    { type: "string", description: "Path relative to workspace root" },
        content: { type: "string", description: "UTF-8 content to write"         },
      },
      required: ["path", "content"],
    },
  },
];

// ── Security: all paths must stay inside WORKSPACE ───────────────────────────

function safePath(relative: string): string {
  const resolved = path.resolve(WORKSPACE, relative);
  if (!resolved.startsWith(WORKSPACE + path.sep) && resolved !== WORKSPACE) {
    throw new Error(`Path escapes workspace: ${relative}`);
  }
  return resolved;
}

// ── Tool handlers ─────────────────────────────────────────────────────────────

function handleReadFile(params: Record<string, string>): unknown {
  const full    = safePath(params.path);
  const content = fs.readFileSync(full, "utf8");
  return { content };
}

function handleListDirectory(params: Record<string, string>): unknown {
  const rel  = params.path ?? ".";
  const full = safePath(rel);
  const entries = fs.readdirSync(full, { withFileTypes: true }).map((e) => ({
    name:      e.name,
    type:      e.isDirectory() ? "directory" : "file",
    path:      path.join(rel, e.name),
  }));
  return { entries };
}

function handleWriteFile(params: Record<string, string>): unknown {
  const full = safePath(params.path);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, params.content, "utf8");
  return { written: params.path };
}

// ── Request dispatch ──────────────────────────────────────────────────────────

function dispatch(req: JsonRpcRequest): JsonRpcResponse {
  const ok = (result: unknown): JsonRpcResponse =>
    ({ jsonrpc: "2.0", id: req.id, result });

  const err = (code: number, message: string): JsonRpcResponse =>
    ({ jsonrpc: "2.0", id: req.id, error: { code, message } });

  try {
    switch (req.method) {
      case "initialize":
        return ok({
          protocolVersion: "2024-11-05",
          serverInfo:      { name: "filesystem-server", version: "0.1.0" },
          capabilities:    { tools: {} },
        });

      case "tools/list":
        return ok({ tools: TOOLS });

      case "tools/call": {
        const p      = req.params as { name: string; arguments: Record<string, string> };
        const args   = p.arguments ?? {};
        switch (p.name) {
          case "read_file":       return ok(handleReadFile(args));
          case "list_directory":  return ok(handleListDirectory(args));
          case "write_file":      return ok(handleWriteFile(args));
          default:                return err(-32601, `Unknown tool: ${p.name}`);
        }
      }

      default:
        return err(-32601, `Method not found: ${req.method}`);
    }
  } catch (e) {
    return err(-32603, e instanceof Error ? e.message : String(e));
  }
}

// ── Transport: stdio or TCP ───────────────────────────────────────────────────

function makeHandler(send: (msg: string) => void) {
  let buffer = "";

  return (chunk: Buffer | string) => {
    buffer += chunk.toString();
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      try {
        const req  = JSON.parse(trimmed) as JsonRpcRequest;
        const resp = dispatch(req);
        send(JSON.stringify(resp) + "\n");
      } catch {
        const errResp: JsonRpcResponse = {
          jsonrpc: "2.0", id: null,
          error: { code: -32700, message: "Parse error" },
        };
        send(JSON.stringify(errResp) + "\n");
      }
    }
  };
}

const tcpPort = process.env.MCP_PORT ? parseInt(process.env.MCP_PORT, 10) : null;

if (tcpPort) {
  const server = net.createServer((socket) => {
    const handler = makeHandler((msg) => socket.write(msg));
    socket.on("data", handler);
    socket.on("error", () => socket.destroy());
  });
  server.listen(tcpPort, "127.0.0.1", () =>
    console.error(`MCP filesystem server listening on 127.0.0.1:${tcpPort}`),
  );
} else {
  // stdio mode — default for most MCP clients
  const handler = makeHandler((msg) => process.stdout.write(msg));
  process.stdin.on("data", handler);
  process.stdin.resume();
  console.error(`MCP filesystem server ready (stdio, workspace: ${WORKSPACE})`);
}
