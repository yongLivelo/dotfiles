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
    "gbprod/yanky.nvim",
    opts = {
      system_clipboard = {
        -- LazyVim defers unnamedplus until VeryLazy; pin "+" so yanky doesn't fall back to "*" (primary)
        clipboard_register = "+",
      },
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
      image = {
        enabled = true,
      },
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
    keys = {
      { "<leader>Cp", "<cmd>CompetiTest receive problem<cr>", desc = "Receive problem (competitest)" },
      { "<leader>Cr", "<cmd>CompetiTest run<cr>", desc = "Run testcases (competitest)" },
    },
    config = function()
      require("competitest").setup()
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "gdscript-formatter",
        "gdtoolkit",
        "pgformatter",
        "postgres-language-server",
        "badness",
      },
    },
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
        gdscript = {},
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
  {
    "pwntester/octo.nvim",
    keys = {
      { "<leader>gC", "<cmd>Octo pr create<cr>", desc = "Create PR (Octo)" },
    },
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- use latest release, remove to use latest commit
    lazy = false,
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      ui = {
        enable = false,
      },
      workspaces = {
        {
          name = "personal",
          path = "~/vaults/personal/",
        },
      },
      checkbox = {
        order = { " ", "x" },
      },
    },
    keys = {
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New Obsidian note" },
      { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Open Obsidian note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search Obsidian vault" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Show backlinks" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      pipe_table = {
        enabled = true,
        preset = "round", -- Options: "none", "round", "double", "heavy"
        style = "full", -- Draws top and bottom borders
      },
      checkbox = {
        enabled = true, -- Re-enables checkboxes if using LazyVim's markdown extra
      },
    },
  },

  {
    "stevearc/overseer.nvim",
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run task" },
      { "<leader>ol", "<cmd>OverseerRestartLast<cr>", desc = "Restart last task" },
    },
    -- LazyVim's overseer extra already calls overseer.setup(); only add the custom command here.
    init = function()
      vim.api.nvim_create_user_command("OverseerRestartLast", function()
        local overseer = require("overseer")
        -- default sort is newest first; finished-first would restart an older task
        local tasks = overseer.list_tasks()
        if vim.tbl_isempty(tasks) then
          vim.notify("No tasks found", vim.log.levels.WARN)
        else
          overseer.run_action(tasks[1], "restart")
        end
      end, {})
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local orig = opts.on_attach
      opts.on_attach = function(buf)
        if orig then
          orig(buf)
        end
        vim.keymap.set(
          "n",
          "<leader>ghD",
          "<cmd>Gitsigns diff<cr>",
          { buffer = buf, desc = "Diff Repo", silent = true }
        )
      end
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (Diffview)" },
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
    },
  },
}
