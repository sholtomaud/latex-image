import * as vscode from "vscode";
import * as fs     from "fs";
import * as path   from "path";

// Icons that map nicely to each known template type
const TEMPLATE_ICONS: Record<string, string> = {
  latex:      "$(file-pdf)",
  fountain:   "$(book)",
  typescript: "$(symbol-namespace)",
  python:     "$(symbol-misc)",
};

function readTemplate(workspaceRoot: string): string | null {
  try {
    return fs.readFileSync(path.join(workspaceRoot, ".vscode-template"), "utf8").trim();
  } catch {
    return null;
  }
}

export function activate(context: vscode.ExtensionContext): void {
  const config = vscode.workspace.getConfiguration("projectStatus");
  if (!config.get<boolean>("showInStatusBar", true)) return;

  const item = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Left,
    -100,  // far left, low priority
  );

  function refresh(): void {
    const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!root) { item.hide(); return; }

    const template = readTemplate(root);
    if (!template) { item.hide(); return; }

    const icon = TEMPLATE_ICONS[template] ?? "$(tools)";
    item.text    = `${icon} ${template}`;
    item.tooltip = `Project template: ${template}`;
    item.show();
  }

  // Refresh on activation and whenever the workspace changes
  refresh();
  context.subscriptions.push(
    item,
    vscode.workspace.onDidChangeWorkspaceFolders(refresh),
    // Re-read if the template file is created or modified while the IDE is open
    vscode.workspace.onDidSaveTextDocument((doc) => {
      if (doc.fileName.endsWith(".vscode-template")) refresh();
    }),
  );
}

export function deactivate(): void {}
