return {
  {
    name = "ai-harness",
    dir = vim.fn.stdpath("config") .. "/lua/ai_harness",
    lazy = false,
    config = function()
      require("ai_harness").setup()
    end,
    keys = {
      { "<leader>aa", "<cmd>AIToggle<cr>", desc = "Toggle AI prompt & terminal" },
      { "<leader>as", ":AISend<cr>", mode = { "n", "v" }, desc = "Send prompt/selection to AI" },
      { "<leader>aw", "<cmd>AISwitch<cr>", desc = "Switch AI harness" },
      { "<leader>ai", ":AIInline<cr>", mode = { "n", "v" }, desc = "Inline AI request" },
      { "<leader>ac", "<cmd>AICommand<cr>", desc = "Run AI slash command / skill" },
      {
        "<leader>at",
        function()
          require("ai_harness").pick_template()
        end,
        desc = "AI prompt template",
      },
      {
        "<leader>aj",
        function()
          require("ai_harness").scroll_output(10)
        end,
        desc = "Scroll AI output down",
      },
      {
        "<leader>ak",
        function()
          require("ai_harness").scroll_output(-10)
        end,
        desc = "Scroll AI output up",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return require("ai_harness").statusline()
        end,
        cond = function()
          return package.loaded["ai_harness"] ~= nil
        end,
      })
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "ai_harness" },
        providers = {
          ai_harness = {
            name = "AI Harness",
            module = "ai_harness.completion",
            score_offset = 100,
          },
        },
      },
    },
  },
}
