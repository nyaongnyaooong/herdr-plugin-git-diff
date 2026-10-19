# Git Diff

Toggles a LazyVim tab that shows the git diff (via diffview.nvim) of the repository the focused pane is in. Meant for watching what Claude Code changes. When the focused pane is in a parent folder that holds several repositories (not itself a repository), it looks up to two levels down and opens one diffview tab per repository with uncommitted changes (`gt` / `gT` to switch). If none have changes, it only shows a notification.

## Requirements

`nvim` (0.11.2+), `git`, `jq`, `curl`, `unzip`, a C compiler and the `tree-sitter` CLI (treesitter parsers). On Ubuntu 26.04: `sudo apt install neovim git jq curl unzip build-essential tree-sitter-cli ripgrep fd-find`. LazyVim, diffview.nvim and the parsers are installed into the plugin state directory on first open, which takes a while and needs network; the user's own nvim config and data are not used. The bundled dependency lockfile seeds a per-machine lockfile in the plugin state directory, so opening the viewer does not modify the plugin checkout.

The colorscheme (`nvim/colors/cursor-dark.lua`) mirrors IntelliJ's Cursor Dark scheme with its Java/Kotlin overrides, on a `#151515` background. Java, Kotlin, Groovy, SQL and Dockerfile parsers are added for highlighting.

## Install

### Windows

Windows uses native Python/PowerShell entrypoints, with no Bash or jq requirement. Install Python 3.9+, Neovim 0.11.2+, Git, a C compiler and the Tree-sitter CLI. The launcher also detects Neovim under `%LOCALAPPDATA%\herdr\tools\nvim-win64\bin`, Tree-sitter under `%LOCALAPPDATA%\herdr\tools`, and GCC under `C:\QMK_MSYS\ucrt64\bin`. Set `HERDR_NVIM` or add tools to PATH for other locations. Python can be selected with `HERDR_PYTHON`.

Bind `prefix+d` to `git-diff.toggle-windows` on Windows. Neovim state and dependency lockfiles stay outside the plugin checkout. Run `python scripts/test_windows.py` to test repository discovery and tab toggling without touching live panes.

```sh
herdr plugin link /path/to/herdr-plugin-git-diff
herdr server reload-config
```

Bind a key in `config.toml`:

```toml
[[keys.command]]
key = "prefix+d"
type = "plugin_action"
command = "git-diff.toggle"
description = "git diff pane"
```

The diff opens in a new tab (named `diff: <repo>`, or `diff: 레포 N개` for several) and takes focus. Press it again (inside the diff tab or from the original tab) to close the diff tab and return to the tab you were working in. `q` inside the pane quits nvim.
