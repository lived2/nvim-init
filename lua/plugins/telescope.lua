return {
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope-ui-select.nvim",
    },
    opts = function(_, opts)
      opts.defaults = opts.defaults or {}
      opts.defaults.file_ignore_patterns = vim.list_extend(
        opts.defaults.file_ignore_patterns or {},
        {
          "^tags$",
          "/tags$",
          "%.orig$",
          "%.rej$",
        }
      )
      opts.defaults.mappings = opts.defaults.mappings or {}
      opts.defaults.mappings.i = opts.defaults.mappings.i or {}

      local actions = require "telescope.actions"
      opts.defaults.mappings.i["<Esc>"] = actions.close

      opts.extensions = opts.extensions or {}
      opts.extensions["ui-select"] = require("telescope.themes").get_dropdown({
        previewer = false,
      })
    end,

    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("ui-select")
    end,
  },
}
