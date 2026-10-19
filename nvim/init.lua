-- LazyVim, isolated: diff-pane.sh points XDG_* at the plugin state dir,
-- so the user's own nvim config and data stay untouched.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Lazy writes its lockfile at startup. Keep the checkout clean and seed each
-- machine's state from the repository's known dependency versions.
local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
if vim.fn.filereadable(lockfile) == 0 then
  vim.fn.mkdir(vim.fn.fnamemodify(lockfile, ":h"), "p")
  vim.fn.writefile(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"), lockfile)
end
-- The bundled lock can come from a newer Mac Neovim. Match LazyVim's
-- compatibility pin on stable Neovim 0.11 (Ubuntu's packaged version).
if vim.fn.has("nvim-0.12") == 0 then
  local pins = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  local compatible = "7caec274fd19c12b55902a5b795100d21531391f"
  if pins["nvim-treesitter"] and pins["nvim-treesitter"].commit ~= compatible then
    pins["nvim-treesitter"].commit = compatible
    vim.fn.writefile({ vim.json.encode(pins) }, lockfile)
  end
end

require("lazy").setup({
  lockfile = lockfile,
  -- Encoded Lua cache filenames can exceed Windows MAX_PATH in plugin state.
  performance = { cache = { enabled = vim.fn.has("win32") == 0 } },
  spec = {
    -- colors/cursor-dark.lua mirrors the IntelliJ Cursor Dark scheme.
    { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "cursor-dark" } },
    {
      "nvim-treesitter/nvim-treesitter",
      opts = { ensure_installed = { "java", "kotlin", "groovy", "sql", "dockerfile" } },
    },
    {
      "sindrets/diffview.nvim",
      cmd = { "DiffviewOpen", "DiffviewRefresh" },
      -- enhanced_diff_hl: lines only in the old side show as deleted (red), not added.
      opts = { use_icons = false, enhanced_diff_hl = true },
      config = function(_, opts)
        require("diffview").setup(opts)
        -- diffview's setup resets this group, so set it after (IntelliJ red-tinted bg).
        vim.api.nvim_set_hl(0, "DiffviewDiffAddAsDelete", { bg = "#4a2421" })
      end,
      keys = { { "q", "<cmd>qa<cr>", desc = "Quit" } },
    },
  },
  checker = { enabled = false },
  change_detection = { notify = false },
})

-- toggle.sh writes the repos to show into $GIT_DIFF_REPOS; one diffview tab per repo.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local file = vim.env.GIT_DIFF_REPOS
    if not file or vim.fn.filereadable(file) == 0 then return end
    for _, repo in ipairs(vim.fn.readfile(file)) do
      -- Lua API, not :DiffviewOpen, so paths with spaces stay one argument.
      require("diffview").open({ "-C" .. repo })
    end
    -- Drop the empty startup tab, keep the first repo in front.
    if #vim.api.nvim_list_tabpages() > 1 then vim.cmd("1tabclose") end
    vim.cmd("tabfirst")
  end,
})

-- Claude edits files from outside nvim, so poll for new changes.
-- shortcut: fixed 3s poll, switch to a git/fs watcher if it feels heavy.
vim.uv.new_timer():start(3000, 3000, vim.schedule_wrap(function()
  if pcall(require, "diffview.lib") then pcall(vim.cmd, "DiffviewRefresh") end
end))
