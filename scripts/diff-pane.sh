#!/bin/sh
# Runs inside the split pane: LazyVim with diffview.nvim on the pane's cwd.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
state="$HERDR_PLUGIN_STATE_DIR/nvim"

# nvim reads $XDG_CONFIG_HOME/nvim, i.e. this plugin's nvim/ directory.
export XDG_CONFIG_HOME="$root"
export XDG_DATA_HOME="$state/data" XDG_STATE_HOME="$state/state" XDG_CACHE_HOME="$state/cache"

exec nvim -c DiffviewOpen
