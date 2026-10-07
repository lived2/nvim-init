require("neo-tree").setup({
  close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
  popup_border_style = "", -- "NC"(default) or "" to use 'winborder' on Neovim v0.11+
  sources = {
    "filesystem",
    "buffers",
    "git_status",
    "document_symbols",
  },
  filesystem = {
    commands = {
      add = require("configs.neo-tree_create").add,
      add_directory = require("configs.neo-tree_create").add_directory,
    },
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },

    hijack_netrw_behavior = "open_default",
    --hijack_netrw_behavior = "disabled",
  },
  buffers = {
    window = {
      mappings = {
        ["d"] = require("configs.neo-tree_popup").close_nvchad_buffer,
      }
    }
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
      ["<RightMouse>"] = "none",
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

local function move_focus_to_nt_source(source)
  local state = require("neo-tree.sources.manager").get_state(source)

  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_set_current_win(state.winid)
  end
end

map("n", "<leader>ee", function()
  --vim.cmd("Neotree toggle last")
  --vim.api.nvim_set_current_win(Win_code)

  -- Neotree show toggle last
  require("neo-tree.command").execute({
    source = "last",
    action = "show",
    toggle = true,
  })
end)

map("n", "<leader>ef", function()
  nt.execute({
    source = "filesystem",
    position = "left",
    reveal = true,
    action = "focus",
  })
  move_focus_to_nt_source("filesystem")
end)

map("n", "<leader>eb", function()
  nt.execute({
    source = "buffers",
    position = "left",
    action = "focus",
  })
  move_focus_to_nt_source("buffers")
end)

map("n", "<leader>eg", function()
  nt.execute({
    source = "git_status",
    position = "left",
    action = "focus",
  })
  move_focus_to_nt_source("git_status")
end)

map("n", "<leader>es", function()
  nt.execute({
    source = "document_symbols",
    position = "left",
    action = "focus",
  })
  move_focus_to_nt_source("document_symbols")
end)
