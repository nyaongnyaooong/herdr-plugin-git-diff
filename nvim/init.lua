-- LazyVim, isolated: diff-pane.sh points XDG_* at the plugin state dir,
-- so the user's own nvim config and data stay untouched.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    {
      "sindrets/diffview.nvim",
      cmd = { "DiffviewOpen", "DiffviewRefresh" },
      opts = { use_icons = false },
      keys = { { "q", "<cmd>qa<cr>", desc = "Quit" } },
    },
  },
  checker = { enabled = false },
  change_detection = { notify = false },
})

-- Claude edits files from outside nvim, so poll for new changes.
-- shortcut: fixed 3s poll, switch to a git/fs watcher if it feels heavy.
vim.uv.new_timer():start(3000, 3000, vim.schedule_wrap(function()
  if pcall(require, "diffview.lib") then pcall(vim.cmd, "DiffviewRefresh") end
end))
