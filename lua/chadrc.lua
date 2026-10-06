-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	--theme = "onedark",
  theme = 'catppuccin',
  hl_override = require("highlights").override,
  hl_add = require("highlights").add,

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }
M.ui = {
  tabufline = {
    lazyload = false
  },
  telescope = {
    style = "bordered",
  },
  statusline = {
    modules = {
      git = function()
        local buf = require("nvchad.stl.utils").stbufnr()
        local status = vim.b[buf].gitsigns_status_dict
        if not vim.b[buf].gitsigns_head or vim.b[buf].gitsigns_git_status or not status then
          return ""
        end

        local branch = (status.head or vim.b[buf].gitsigns_head):gsub("%%", "%%%%")
        local parts = { "%#St_gitBranch#  " .. branch }
        for _, item in ipairs({
          { "added", "St_gitAdded", "" },
          { "changed", "St_gitChanged", "" },
          { "removed", "St_gitRemoved", "" },
        }) do
          local count = status[item[1]] or 0
          if count > 0 then
            parts[#parts + 1] = ("%%#%s# %s %d"):format(item[2], item[3], count)
          end
        end
        return table.concat(parts) .. "%#StatusLine# "
      end,
      --sep = "%#St_file_sep#",  --   ,   ,  
      cur_file = function()
        local buf = require("nvchad.stl.utils").stbufnr()
        local path = vim.api.nvim_buf_get_name(buf)
        if path == "" then path = "[No Name]" end

        return "%#StatusLine# " .. path:gsub("%%", "%%%%") .. " "
      end,
    },
    -- Available styles: 'default', 'round', 'block', 'arrow'
    separator_style = "arrow",
    -- Customize component order
    order = {
      "mode",
      "file",
      "git",
      "cur_file",
      "%=",
      "lsp_msg",
      "%=",
      "diagnostics",
      "lsp",
      "cwd",
      "cursor",
    }
  },
}

return M
