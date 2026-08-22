# CLAUDE.md

**Read [AGENTS.md](AGENTS.md) first.** It is the source of truth for this
repository: architecture, the Apple `container` CLI's real behaviour, the
wrapper-script contract, LaTeX Workshop placeholder semantics, and the
verification procedure. Everything below is additive.

## Claude-specific notes

- **Ask before `sudo`.** Every `make install*` target copies into
  `/usr/local/bin` with `sudo`. Never run one unprompted.
- **Test against `scripts/`, not `/usr/local/bin/`.** The installed copies are
  stale copies, not symlinks. `scripts/latexmk-container.sh --version` needs no
  privileges and exercises the same code.
- **Scratch files go under `$HOME`.** Paths outside the shared home mount are
  invisible inside the `ubuntu-latex` machine, so a probe in `/tmp` will not
  behave like a real document.
- **Verify claims about the `container` CLI by running it.** Its surface differs
  from Docker in ways that are easy to assume wrong — there is no
  `machine start`, and `machine run` takes `-w/--workdir`.
- **Read the extension, don't guess it.** LaTeX Workshop's real behaviour is in
  `~/.vscode/extensions/james-yu.latex-workshop-*/out/src/` — `utils/utils.js`
  for placeholder expansion, `compile/plan.js` for argument preprocessing and
  the `pdflatex --version` MiKTeX probe, `compile/recipe.js` for the spawn cwd.
- **Check the live config, not just the repo — and check the right profile.**
  `.vscode/settings.json` only reaches VS Code via `make install-vscode-settings`.
  Worse, the effective file may not be
  `~/Library/Application Support/Code/User/settings.json` at all: a window bound
  to a named profile reads
  `~/Library/Application Support/Code/User/profiles/<id>/settings.json`, which
  does **not** inherit the default. Resolve the folder → profile mapping in
  `globalStorage/storage.json` before concluding a setting is applied.
- **Read the build log's recipe name.** `Preparing to run recipe: latexmk` means
  LaTeX Workshop fell back to its built-ins; the configured name is
  `latexmk (full — biber + refs)`. That one line distinguishes a config problem
  from a wrapper problem.
