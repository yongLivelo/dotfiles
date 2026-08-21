return {
  {
    "nickjvandyke/opencode.nvim",
    -- version = "*", -- Latest stable release
    config = function()
      vim.keymap.set({ "n", "x" }, "<leader>oa", function()
        require("opencode").ask()
      end, { desc = "Ask OpenCode" })
      vim.keymap.set({ "n", "x" }, "<leader>ot", function()
        require("opencode").ask("@this: ")
      end, { desc = "Ask OpenCode to file…" })
      vim.keymap.set({ "n", "x" }, "<leader>os", function()
        require("opencode").select()
      end, { desc = "Select OpenCode…" })
      vim.keymap.set({ "n", "x" }, "ga", function()
        return require("opencode").operator("@this ")
      end, { desc = "Append range to OpenCode", expr = true })
      vim.keymap.set({ "n" }, "gaa", function()
        return require("opencode").operator("@this ") .. "_"
      end, { desc = "Append line to OpenCode", expr = true })
      vim.keymap.set({ "n" }, "<a-u>", function()
        require("opencode").command("session.half.page.up")
      end, { desc = "Scroll OpenCode up" })
      vim.keymap.set({ "n" }, "<a-d>", function()
        require("opencode").command("session.half.page.down")
      end, { desc = "Scroll OpenCode down" })
    end,
  },
  {
    "folke/snacks.nvim",
    opts = {
      input = {
        enabled = true,
      },
      picker = {
        enabled = true,
        win = {
          input = {
            keys = {
              ["<a-o>"] = { "opencode_send", mode = { "n", "i" } },
            },
          },
        },
        actions = {
          opencode_send = function(picker) ---@param picker snacks.Picker
            local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
              return item.file and require("opencode").format({ path = item.file, from = item.pos, to = item.end_pos })
                or item.text
            end, picker:selected({ fallback = true }))

            require("opencode").prompt(table.concat(items, ", ") .. " ")
          end,
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lsp", "buffer" },
        per_filetype = {
          opencode_ask = { "lsp", "buffer" },
        },
        providers = { lsp = { fallbacks = {} } },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_z = {
          {
            function()
              return require("opencode").statusline()
            end,
            cond = function()
              return package.loaded["opencode"] ~= nil
            end,
          },
        },
      },
    },
  },
}
