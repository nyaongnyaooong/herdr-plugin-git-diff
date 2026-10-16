-- Isolated config: leaves the user's own nvim setup untouched.
vim.opt.runtimepath:prepend(vim.env.HERDR_PLUGIN_STATE_DIR .. "/diffview.nvim")
require("diffview").setup({ use_icons = false })

-- Claude edits files from outside nvim, so poll for new changes.
-- shortcut: fixed 3s poll, switch to a git/fs watcher if it feels heavy.
vim.uv.new_timer():start(3000, 3000, vim.schedule_wrap(function()
  pcall(vim.cmd, "DiffviewRefresh")
end))

vim.keymap.set("n", "q", "<cmd>qa<cr>")
