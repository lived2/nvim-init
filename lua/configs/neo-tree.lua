require("neo-tree").setup({
  close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
  popup_border_style = "", -- "NC"(default) or "" to use 'winborder' on Neovim v0.11+
  --[[
  source_selector = {
    winbar = true,
    statusline = false,
  },
  ]]
  sources = {
    "filesystem",
    "buffers",
    "git_status",
    "document_symbols",
  },
  document_symbols = {
    follow_cursor = true, -- Automatically highlights and tracks the symbol under the cursor in the current buffer
  },
  source_selector = {
    winbar = true, -- or statusline = true
    sources = {
      --[[
      { source = "filesystem", display_name = " 📁 Files " },
      { source = "buffers", display_name = " 🗂️ Buffers " },
      { source = "git_status", display_name = " 🌿 Git " },
      { source = "document_symbols", display_name = " 🏷️ Symbols " },
      ]]
      { source = "filesystem" },
      { source = "buffers" },
      { source = "git_status" },
      { source = "document_symbols" },
    },
  },
  window = {
    width = 60,
    mappings = {
      ["<Tab>"] = "next_source",
      ["<S-Tab>"] = "prev_source",
    },
  },
  default_component_configs = {
    git_status = {
      symbols = {
        -- Change type
        added = "✚",
        modified = "",
        deleted = "✖", -- this can only be used in the git_status source
        renamed = "󰁕", -- this can only be used in the git_status source
        -- Status type
        untracked = "",
        ignored = "",
        unstaged = "󰄱",
        staged = "",
        conflict = "",
      },
    },
  },
})


--[[
local map = vim.keymap.set
map("n", "<leader>o", function()
  vim.cmd("Neotree reveal toggle")
end)
]]

local set_hl = vim.api.nvim_set_hl

set_hl(0, "NeoTreeTabActive", {
  fg = "#1e1e2e",
  bg = "#cba6f7", -- Mauve
  bold = true,
})

set_hl(0, "NeoTreeTabInactive", {
  fg = "#bac2de",
  bg = "#313244",
})

set_hl(0, "NeoTreeTabSeparatorActive", {
  fg = "#cba6f7",
  bg = "#cba6f7",
})

set_hl(0, "NeoTreeTabSeparatorInactive", {
  fg = "#313244",
  bg = "#313244",
})

set_hl(0, "NeoTreeFileName", {
  fg = "#cdd6f4", -- Catppuccin text
})

set_hl(0, "NeoTreeGitUntracked", {
  fg = "#a6adc8",
})

set_hl(0, "NeoTreeGitModified", {
  fg = "#f9e2af",
})

set_hl(0, "NeoTreeGitAdded", {
  fg = "#a6e3a1",
})

local nt = require("neo-tree.command")
local map = vim.keymap.set

map("n", "<leader>ee", function()
  vim.cmd("Neotree toggle last")
  vim.api.nvim_set_current_win(Win_code)
end)

map("n", "<leader>ef", function()
  nt.execute({
    source = "filesystem",
    position = "left",
    reveal = true,
    focus = false,
  })
end)

map("n", "<leader>eb", function()
  nt.execute({
    source = "buffers",
    position = "left",
    focus = false,
  })
end)

map("n", "<leader>eg", function()
  nt.execute({
    source = "git_status",
    position = "left",
    focus = false,
  })
end)

map("n", "<leader>es", function()
  nt.execute({
    source = "document_symbols",
    position = "left",
    focus = false,
  })
end)
