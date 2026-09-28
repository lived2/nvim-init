require("aerial").setup({
  layout = {
    placement = "window",
    default_direction = "prefer_left",
  },
  attach_mode = "window",
  placement_editor_edge = false,
  --highlight_on_hover = false,
  --highlight_on_jump = false,
  -- optionally use on_attach to set keymaps when aerial has attached to a buffer
  on_attach = function(bufnr)
    -- Jump forwards/backwards with '{' and '}'
    vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
  end,
})


--[[
local map = vim.keymap.set
map("n", "<leader>a", "<cmd>AerialToggle!<CR>")
]]

local set_hl = vim.api.nvim_set_hl

set_hl(0, "AerialLine", {
  bg = "#313244",
  fg = "#f5c2e7",
  --fg = "#cba6f7",
  --fg = "#b4befe", -- Lavender
  bold = true,
})

set_hl(0, "AerialFunction", {
  fg = "#89b4fa",
})

set_hl(0, "AerialStruct", {
  fg = "#94e2d5",
})

set_hl(0, "AerialEnum", {
  fg = "#fab387",
})

set_hl(0, "AerialGuide", {
  fg = "#585b70",
})
