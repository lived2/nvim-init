
local M = {}

M.override = {
  TelescopePromptBorder = {
    fg = "#f38ba8", -- Pink
  },
  TelescopeBorder = {
    fg = "#89b4fa", -- Blue
  },
  TelescopeSelection = {
    bg = "#474656", -- grey
    bold = true,
  },
  TelescopeSelectionCaret = {
    fg = "#F38BA8",
    bold = true,
  },
  CursorLine = {
    bg = "#89b4fa",
    fg = "#11111b",
    bold = true,
  },
  Pmenu = {
    fg = "#cdd6f4",
    bg = "#1e1e2e",
  },
  PmenuSel = {
    fg = "#11111b",
    bg = "#89b4fa",
    bold = true,
  },
}

M.add = {
  PmenuBorder = {
    fg = "#89b4fa",
    bg = "#1e1e2e",
  },
  TelescopePromptCounter = {
    fg = "#cba6f7",
    bg = "#1e1e2e",
  },
}

return M
