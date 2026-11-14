return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "gbprod/cutlass.nvim",
    opts = {
      cut_key = "x",
    },
  },
  {
    "max397574/better-escape.nvim",
    opts = {
      mappings = {
        t = {
          j = {
            k = false,
          },
        },
      },
    },
  },
  {
    "mikavilpas/yazi.nvim",
    keys = {
      {
        "<leader>y",
        "<cmd>Yazi<cr>",
        mode = { "n", "v" },
        desc = "Open yazi at the current file",
      },
    },
  },
  {
    "folke/noice.nvim",
    enabled = false,
  },
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = {
        configure = false,
      },
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          explore = { hidden = true },
        },
      },
      dashboard = {
        preset = {
          pick = function(cmd, opts)
            return LazyVim.pick(cmd, opts)()
          end,
          header = [[
        ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
        ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
        ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
        ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
        ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           
        ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           
 ]],
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = "󰌢", key = "v", desc = "Leetcode", action = ":Leet" },
          { icon = "", key = "q", desc = "Quit", action = ":qa" },
        },
        },
      },
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    opts = {
      settings = {
        save_on_toggle = true,
      },
    },
    keys = function()
      local keys = {
        {
          "<leader>h",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Harpoon Quick Menu",
        },
      }
      for i = 1, 9 do
        keys[#keys + 1] = {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "Harpoon to File " .. i,
        }
        keys[#keys + 1] = {
          "<leader>a" .. i,
          function()
            require("harpoon"):list():replace_at(i, { value = vim.fn.expand("%:p") })
          end,
          desc = "Harpoon current file to slot " .. i,
        }
      end
      return keys
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        gdscript = { "gdscript-formatter" },
        sql = { "pg_format" },
      },
    },
  },
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      lang = "python3",
      plugins = {
        non_standalone = true,
      },
    },
  },
  {
    "xeluxee/competitest.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    config = function()
      require("competitest").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              preferences = { importModuleSpecifier = "non-relative" },
            },
          },
        },
      },
    },
  },
  {
    "nickjvandyke/opencode.nvim",
    -- Defaults to "main", supporting OpenCode v2.
    -- Uncomment to pull the latest stable release, supporting OpenCode v1.
    -- version = "*",
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {}

      -- Recommended/example keymaps
      vim.keymap.set({ "n", "x" }, "<C-o>", function()
        require("opencode").ask("@this: ")
      end, { desc = "Ask OpenCode…" })
      vim.keymap.set({ "n", "x" }, "<C-x>", function()
        require("opencode").select()
      end, { desc = "Select OpenCode…" })
      vim.keymap.set({ "n", "x" }, "go", function()
        return require("opencode").operator("@this")
      end, { desc = "Send range to OpenCode", expr = true })
      vim.keymap.set({ "n" }, "goo", function()
        return require("opencode").operator("@this") .. "_"
      end, { desc = "Send line to OpenCode", expr = true })
    end,
  },
}
