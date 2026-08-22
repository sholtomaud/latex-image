# AGENTS.md

Guidance for coding agents working in this repository. `CLAUDE.md` points here;
this file is the single source of truth.

## What this repo is

A macOS host runs no TeX toolchain at all. Instead, Apple's `container` CLI hosts
a persistent Linux VM ("container machine") named **`ubuntu-latex`** that carries
TeX Live, latexmk, latexindent, biber and pandoc. Thin wrapper scripts in
`/usr/local/bin` make those tools look native to the host and to VS Code's
LaTeX Workshop extension.

```
VS Code / shell  →  /usr/local/bin/latexmk-container  →  container machine run -n ubuntu-latex  →  latexmk
      (host)                  (wrapper)                          (Apple container CLI)              (Linux VM)
```

`platform/` is a separate concern: it builds OpenVSCode Server images layered on
top of `ubuntu-latex`, so a browser-based editor can be launched per directory.

## Hard rules

1. **Never install or invoke a TeX toolchain on the host.** No MacTeX, no
   `brew install texlive`. Everything TeX runs in the machine.
2. **Never run `node`, `npm`, or `npx` directly on the host.** All JS/TS work
   happens inside a container, driven by `make` targets in `platform/`
   (`make -C platform dev` builds and installs the extensions).
3. **`sudo` is required to install wrappers.** Ask before running any
   `make install*` target — do not run it unprompted.

## Facts about the Apple `container` CLI that are easy to get wrong

These were established by reading `container --help` and by direct experiment
against `container CLI version 1.0.0`. Do not "fix" code that depends on them.

- **There is no `container machine start`.** The subcommands are `create`,
  `delete`, `inspect`, `list`, `logs`, `run`, `set`, `set-default`, `stop`.
  `container machine run` boots the machine on demand. Any wrapper calling
  `machine start` is stale.
- **`ubuntu-latex` is the default machine** (`*` in `container machine ls`), so
  omitting `-n` happens to work. Pass `-n "${MACHINE_NAME}"` anyway — the
  default is user-global state that can change under you.
- **The macOS home directory is mounted at the same path inside the machine.**
  `/Users/<user>/…` resolves identically on both sides, so host paths need no
  translation. Note `$HOME` inside the machine is `/home/<user>`, *not*
  `/Users/<user>` — never derive paths from `$HOME` across the boundary.
- **The working directory is inherited when the host cwd is under that mount**,
  and silently falls back to `/home/<user>` when it is not (e.g. from `/tmp`).
  Do not rely on the fallback: pass `-w "${PWD}"` explicitly.
- **`-w` accepts any path without error**, including one that does not exist
  inside the machine, so it is safe to pass unconditionally.
- **Flags after the executable are passed through, not consumed by the CLI.**
  `container machine run -n ubuntu-latex latexmk --version` works; the `--`
  separator shown in `container help machine` is optional here.

## Wrapper script contract

`scripts/*-container.sh` are **transparent proxies**. Each one does exactly:

```bash
exec container machine run -n "${MACHINE_NAME}" -w "${PWD}" <tool> "$@"
```

`latexmk-container.sh` is the one exception, and only to add stale-`.fdb_latexmk`
recovery (see the comment in that file, and commit `0b19b59`) — it still forwards
argv verbatim.

**Do not add argument parsing to a wrapper.** Earlier versions extracted the
`.tex` file with `TEX_FILE="${!#}"` and ran `dirname`/`basename` on it. That
breaks on any invocation whose last argument is a flag:

```
$ latexmk --version
dirname: illegal option -- -
```

which matters because LaTeX Workshop's `Plan.isMikTeX()` runs
`pdflatex --version` whenever a tool's `command` is literally `pdflatex` or
`latexmk` — and the Makefile installs the wrappers under those bare names as
well as the `-container` names.

**Build flags belong in the recipe, not the wrapper.** They live in
`latex-workshop.latex.tools` in `.vscode/settings.json`. A wrapper that
substitutes its own flags silently overrides whatever the caller asked for.

## LaTeX Workshop integration

Placeholders are expanded in `out/src/utils/utils.js` of the extension:

| Placeholder | Expands to |
|---|---|
| `%DOC%` | absolute path, **no** extension |
| `%DOC_EXT%` | absolute path **with** extension ← **use this one** |
| `%DOCFILE%` | bare basename, no directory, no extension |
| `%DIR%` | directory of the root file |

`%DOCFILE%` is a trap: it yields `article`, not `/path/to/article.tex`. It only
resolves because the extension spawns tools with cwd set to the root file's
directory (`getWorkingFolder(rootFile)` in `out/src/compile/recipe.js`). Use
`%DOC_EXT%` so correctness does not depend on the spawn cwd.

### VS Code gives spawned tools a minimal PATH

Tools are spawned with `{ cwd, shell: false }`, so they inherit the PATH of the
VS Code process itself. When VS Code is opened from Finder, the Dock or
Spotlight that is:

```
$PATH: /usr/bin:/bin:/usr/sbin:/sbin
```

`/usr/local/bin` is absent, so this bites **twice**, and both hops must be fixed:

1. VS Code cannot find the wrapper → `Error: spawn latexmk ENOENT`.
   Fixed by absolute `command` values in `latex-workshop.latex.tools`
   (`/usr/local/bin/latexmk-container`).
2. The wrapper cannot find `container` → `line 21: container: command not found`.
   Fixed by resolving `CONTAINER_BIN` to `/usr/local/bin/container` inside each
   wrapper, falling back to a PATH lookup.

Do not "tidy" either back to a bare name — launching VS Code via `code .` from a
shell inherits a full PATH and masks the problem on one machine but not the next.

Test wrappers under that environment, not your shell's:

```bash
env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME="$HOME" \
    bash scripts/latexmk-container.sh --version
```

The container system daemon is started at login by the launchd agent
(`make launchd-install`); `container machine run` then boots the machine on
demand.

### autoClean races the next build

`latex-workshop.latex.autoClean.run` must stay `never` while latexmk is the
default recipe. LaTeX Workshop calls `lw.extra.clean()` after **every** build,
success or failure (`out/src/compile/executor.js`), and the repo's
`clean.fileTypes` glob includes `*.aux`, `*.fls`, `*.log` and `*.fdb_latexmk` —
latexmk's own state files.

Two consequences. First, latexmk can never work incrementally; every build
reports `Category 'never_run': pdflatex`. Second, since `autoBuild.run` defaults
to `onFileChange`, a save during a build queues the next build while the
previous build's cleaner is still unlinking, and the symptoms read like
filesystem corruption rather than a config problem:

```
Latexmk: Couldn't read 'article.fdb_latexmk' even though it exists
./article.tex:0: I can't write on file `article.log'.
```

The same race is reachable without autoClean by having two VS Code windows
auto-building the same root file into the same directory.

Before blaming the container mount for an I/O error, confirm the mount is
actually at fault:

```bash
container machine run -n ubuntu-latex -w "$DOC_DIR" touch .probe && ls "$DOC_DIR/.probe"
```

Note `~/Documents` is TCC-protected on macOS, but the shared home mount reads
and writes there normally once access is granted — a one-off I/O error there is
far more likely to be this race.

### Profiles do not inherit the default profile's settings

Each VS Code profile keeps its own `settings.json` under
`~/Library/Application Support/Code/User/profiles/<id>/`, and a profile with no
`settings.json` behaves as *empty* — not as "same as default". A window bound to
such a profile silently falls back to LaTeX Workshop's built-in `latexmk` recipe.
The log gives it away:

```
[Build][Recipe] Preparing to run recipe: latexmk.
```

A configured window reports `latexmk (full — biber + refs)` instead.

Profile ids map to names in
`~/Library/Application Support/Code/User/globalStorage/storage.json`
(`userDataProfiles`), and folders map to profiles in the same file
(`profileAssociations.workspaces`). `scripts/merge-vscode-settings.sh` writes to
the default profile *and* every named profile, creating the file where missing.

`latexmk` defaults to **DVI**. Without `-pdf` in the recipe args there is no PDF
output. Do not drop it while "simplifying".

## Installed copies drift

`/usr/local/bin/*` are **copies**, not symlinks. They go stale the moment
`scripts/` is edited. Before debugging any wrapper behaviour, check:

```bash
diff /usr/local/bin/latexmk scripts/latexmk-container.sh
```

Reinstall with `make install install-latexmk install-pandoc install-latexindent`
(needs `sudo` — ask first). Each target installs the script twice: under its
`-container` name and under the bare tool name.

## Common commands

```bash
make help                     # target list
make check                    # verify machine is up and all four tools respond
make install-all              # first-time setup (builds image, creates machine, sudo installs)
make machine-shell            # interactive shell inside ubuntu-latex
make install-vscode-settings  # merge latex-workshop.* keys into VS Code user settings

make -C platform help         # OpenVSCode Server image targets
make -C platform dev          # rebuild + install extensions into the running editor container
```

## Verifying a wrapper change

Test against `scripts/` directly — no `sudo`, no install step:

```bash
# Always under VS Code's minimal PATH -- your shell's PATH hides real failures.
V="env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME=$HOME bash"
$V scripts/latexmk-container.sh --version       # must print the latexmk version
$V scripts/pdflatex-container.sh --version      # must print the pdfTeX version
cd /tmp/probe && scripts/latexmk-container.sh \
    -pdf -bibtex -cd -interaction=nonstopmode -file-line-error /abs/path/article.tex
echo $?                                          # must be non-zero on a TeX error
```

Both the version probe and a real build must pass. A wrapper that builds but
dies on `--version` is the exact regression this repo already had.

Use a scratch directory under `$HOME` — anywhere outside the home mount is
invisible inside the machine.

## Repo layout notes

- `Makefile` / `Containerfile` — the `ubuntu-latex` machine image and wrapper installation.
- `scripts/` — wrapper sources plus launchd install/uninstall and the VS Code settings merger.
- `.vscode/settings.json` — the canonical LaTeX Workshop config; `scripts/merge-vscode-settings.sh` copies its `latex-workshop.*` keys into the user profile.
- `settings.json` at the repo root is a **stale duplicate** predating the latexmk recipe. Nothing reads it.
- `platform/` — OpenVSCode Server images, extensions, PWA server. Has its own Makefile.
