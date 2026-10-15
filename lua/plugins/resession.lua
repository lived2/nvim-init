return {
  "stevearc/resession.nvim",
  lazy = false,
  config = function()
    require("configs.workspace_session").setup()
  end,
}
