return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      opts.defaults = opts.defaults or {}
      opts.defaults.mappings = opts.defaults.mappings or {}
      opts.defaults.mappings.i = opts.defaults.mappings.i or {}

      local actions = require "telescope.actions"
      opts.defaults.mappings.i["<esc>"] = actions.close

      vim.api.nvim_set_hl(0, "TelescopePromptCounter", { fg = "#cba6f7" })
    end,
  },
}
