# Git Diff

Toggles a right-hand Neovim pane that shows the git diff (via diffview.nvim) of the repository the focused pane is in. Meant for watching what Claude Code changes. Outside a git repository it only shows a notification.

## Requirements

`nvim` (0.10+), `git`, `jq`. diffview.nvim is cloned once into the plugin state directory on first open; the user's own nvim config is not used.

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

Press it again to close the pane. `q` inside the pane quits nvim.
