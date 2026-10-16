#!/bin/sh
# Runs inside the split pane: Neovim with diffview.nvim on the pane's cwd.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
plugin_dir="$HERDR_PLUGIN_STATE_DIR/diffview.nvim"

if [ ! -d "$plugin_dir" ]; then
    git clone --depth 1 https://github.com/sindrets/diffview.nvim "$plugin_dir"
fi

exec nvim -u "$root/nvim/init.lua" -c DiffviewOpen
