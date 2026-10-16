# Git Diff

Toggles a LazyVim tab that shows the git diff (via diffview.nvim) of the repository the focused pane is in. Meant for watching what Claude Code changes. When the focused pane is in a parent folder that holds several repositories (not itself a repository), it looks up to two levels down and opens one diffview tab per repository with uncommitted changes (`gt` / `gT` to switch). If none have changes, it only shows a notification.

## Requirements

`nvim` (0.10+), `git`, `jq`, a C compiler (treesitter parsers). LazyVim, diffview.nvim and the parsers are installed into the plugin state directory on first open, which takes a while and needs network; the user's own nvim config and data are not used.

The colorscheme (`nvim/colors/cursor-dark.lua`) mirrors IntelliJ's Cursor Dark scheme with its Java/Kotlin overrides, on a `#151515` background. Java, Kotlin, Groovy, SQL and Dockerfile parsers are added for highlighting.

## Install

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
