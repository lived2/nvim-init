local M = {}

local menus = {}
-- Capture Neovim's original entries before any context replaces PopUp.
local defaults = vim.fn.menu_get("PopUp")[1]

function M.restore_normal_defaults()
  if not defaults then return end
  for _, item in ipairs(defaults.submenus or {}) do
    local mapping = item.mappings and item.mappings.n
    if mapping then
      local name = item.name:gsub("\\", "\\\\"):gsub(" ", "\\ "):gsub("%.", "\\.")
      local command = mapping.noremap == 1 and "nnoremenu" or "nmenu"
      local rhs = mapping.rhs ~= "" and mapping.rhs or "<Nop>"
      vim.cmd(("%s %d.%d PopUp.%s %s"):format(command, defaults.priority, item.priority, name, rhs))
    end
  end

  -- The original callback uses :amenu, which fails while Visual entries are
  -- absent. Update the availability of restored Normal entries ourselves.
  local urls = require("vim.ui")._get_urls()
  local enabled = {
    ["Open in web browser"] = urls[1] ~= nil and vim.startswith(urls[1], "http"),
    ["Go to definition"] = #vim.lsp.get_clients({ bufnr = 0 }) > 0,
    ["Show Diagnostics"] = #vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 }) > 0,
    ["Show All Diagnostics"] = #vim.diagnostic.get(0) > 0,
    ["Configure Diagnostics"] = #vim.diagnostic.get(0) > 0,
  }
  for name, available in pairs(enabled) do
    if vim.fn.menu_info("PopUp." .. name, "n").name then
      vim.cmd(("nmenu %s PopUp.%s"):format(available and "enable" or "disable", name:gsub(" ", "\\ ")))
    end
  end
end

function M.register(name)
  menus[name] = true
end

function M.clear()
  -- Every caller rebuilds PopUp. Remove all modes together: separators left
  -- in other modes can still appear as blank rows in the native popup.
  -- Do this before removing entries the built-in callback expects to exist.
  pcall(vim.api.nvim_clear_autocmds, { group = "nvim.popupmenu", event = "MenuPopup" })
  vim.cmd("silent! aunmenu PopUp")

  menus = {}

  --vim.cmd("redraw!")
end

return M
