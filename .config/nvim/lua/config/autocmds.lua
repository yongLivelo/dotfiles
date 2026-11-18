-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

-- prose in this repo is full of tool names; spell squiggles and markdown diagnostics are noise
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function(event)
    vim.opt_local.spell = false
    vim.diagnostic.enable(false, { bufnr = event.buf })
  end,
})

-- keep focus in Gitsigns diff file list when opening an entry (<S-CR> behavior is unreliable in some terminals)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitsigns-diff",
  callback = function(event)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end
      vim.keymap.set("n", "<CR>", "<S-CR>", { buffer = event.buf, remap = true, silent = true })
      vim.keymap.set("n", "<LeftRelease>", function()
        local mouse = vim.fn.getmousepos()
        if mouse.winid == vim.api.nvim_get_current_win() and mouse.line > 0 then
          vim.api.nvim_feedkeys(vim.keycode("<S-CR>"), "m", false)
        end
      end, { buffer = event.buf, silent = true })
    end)
  end,
})
