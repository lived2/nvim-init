local M = {}

local saved = {
  virtual_text = true,
  signs = true,
  underline = true,
}

function M.hide()
  local current = vim.diagnostic.config()
  if current == nil then return end

  -- Preserve the saved settings when already hidden.
  if current.virtual_text == false
    and current.signs == false
    and current.underline == false
  then
    return
  end

  for key in pairs(saved) do
    saved[key] = vim.deepcopy(current[key])
  end

  vim.diagnostic.config({
    virtual_text = false,
    signs = false,
    underline = false,
  })
end

function M.show()
  vim.diagnostic.config(vim.deepcopy(saved))
end

local set_hl = vim.api.nvim_set_hl
local echo = vim.api.nvim_echo
set_hl(0, "DiagnosticToggleShow", {
  fg = "#a6e3a1",
  bold = true,
})

set_hl(0, "DiagnosticToggleHide", {
  fg = "#cba6f7",
  bold = true,
})

function M.toggle()
  local current = vim.diagnostic.config()
  if current == nil then return end

  if current.virtual_text == false
    and current.signs == false
    and current.underline == false
  then
    require("noice").cmd("dismiss")
    echo({{ "Diagnostics: " }, { "Show", "DiagnosticToggleShow" }, }, true, {})
    M.show()
  else
    require("noice").cmd("dismiss")
    echo({{ "Diagnostics: " }, { "Hide", "DiagnosticToggleHide" }, }, true, {})
    M.hide()
  end
end

return M
