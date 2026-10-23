local M = {}

require("neo-tree").setup({
  close_if_last_window = false, -- Buffer-aware quitting is handled by configs.smart_quit.
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
    kinds = {
      Namespace = {
        hl = "NeoTreeSymbolNamespace",
      },
    },
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
local echo = vim.api.nvim_echo

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
local manager = require("neo-tree.sources.manager")
local map = vim.keymap.set

local function dismiss()
  require("configs.noice_config").dismiss()
  --[[
  require("noice").cmd("dismiss")
  local state = package.loaded["noice.ui.state"]
  if state then state.clear("msg_show") end
  ]]
end

local function move_focus_to_nt_source(source)
  local state = manager.get_state(source)

  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_set_current_win(state.winid)
  end
end

map("n", "<Leader>ee", function()
  --vim.cmd("Neotree toggle last")
  --vim.api.nvim_set_current_win(Win_code)

  -- Neotree show toggle last
  require("neo-tree.command").execute({
    source = "last",
    action = "show",
    toggle = true,
  })
end)

map("n", "<Leader>ef", function()
  nt.execute({
    source = "filesystem",
    position = "left",
    reveal = true,
    action = "focus",
  })
  move_focus_to_nt_source("filesystem")
end)

map("n", "<Leader>eb", function()
  nt.execute({
    source = "buffers",
    position = "left",
    action = "focus",
  })
  move_focus_to_nt_source("buffers")
end)

map("n", "<Leader>eg", function()
  nt.execute({
    source = "git_status",
    position = "left",
    action = "focus",
  })
  move_focus_to_nt_source("git_status")
end)

map("n", "<Leader>es", function()
  M.open_symbols(function()
    move_focus_to_nt_source("document_symbols")
  end)
end)

map("n", "<Leader>ec", function()
  vim.api.nvim_set_current_win(Code_win)
end)

set_hl(0, "NeoTreeNoticeFilesystem", {
  fg = "#89b4fa",
  bold = true,
})

set_hl(0, "NeoTreeNoticeSymbols", {
  fg = "#cba6f7",
  bold = true,
})

set_hl(0, "NeoTreeSymbolNamespace", {
  fg = "#cba6f7", -- Mauve
})

local symbols_loading = false

function M.open_symbols(on_open)
  if symbols_loading then return end

  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_get_current_buf()
  local source_tab = vim.api.nvim_get_current_tabpage()
  local code_win = vim.bo[source_buf].buftype == "" and source_win or Code_win
  if not code_win or not vim.api.nvim_win_is_valid(code_win) then
    vim.notify("No code window is available.", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_win_get_buf(code_win)
  if #vim.lsp.get_clients({
    bufnr = buf,
    method = "textDocument/documentSymbol",
  }) == 0 then
    vim.notify("No LSP supporting document symbols is attached yet.", vim.log.levels.INFO)
    return
  end

  symbols_loading = true

  local finished = false
  local delayed = false

  -- Show a loading message only when the response takes time.
  vim.defer_fn(function()
    if finished then return end
    delayed = true
    vim.notify("Loading symbols…")
  end, 100)

  local cancel_request
  local function context_unchanged()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local in_source = current_win == source_win and current_buf == source_buf
    local in_code = current_win == code_win and current_buf == buf
    return vim.api.nvim_get_current_tabpage() == source_tab
      and vim.api.nvim_win_is_valid(code_win)
      and vim.api.nvim_win_get_buf(code_win) == buf
      and (in_source or in_code or vim.bo[current_buf].filetype == "neo-tree")
  end

  cancel_request = vim.lsp.buf_request_all(
    buf,
    "textDocument/documentSymbol",
    { textDocument = { uri = vim.uri_from_bufnr(buf) } },
    vim.schedule_wrap(function(results)
      if finished then return end
      finished = true
      symbols_loading = false

      -- Allow movement between the code and tree, but not to another file.
      if not context_unchanged() then
        vim.notify("Symbols switch cancelled: the active tab, window, or file changed.", vim.log.levels.INFO)
        return
      end

      local has_symbols = false
      local request_error
      for _, response in pairs(results) do
        if response.error then
          request_error = response.error.message
        elseif type(response.result) == "table" and #response.result > 0 then
          has_symbols = true
        end
      end

      if not has_symbols then
        vim.notify(request_error or "No symbols found in this file.", vim.log.levels.INFO)
        return
      end

      if delayed then
        dismiss()
        echo({{ "Symbol", "NeoTreeNoticeSymbols" }, { " Tab" }}, true, {})
      end
      local subscription
      local completed = false
      local function cleanup()
        completed = true
        symbols_loading = false
        if subscription then
          manager.unsubscribe("document_symbols", subscription)
          subscription = nil
        end
      end

      local function complete(state)
        if completed or state.name ~= "document_symbols"
          or state.tabid ~= source_tab or state.lsp_bufnr ~= buf
        then
          return
        end
        local win = state.winid
        if not win or not vim.api.nvim_win_is_valid(win)
          or vim.api.nvim_win_get_buf(win) ~= state.bufnr
        then
          return
        end

        cleanup()
        if context_unchanged() then on_open() end
      end

      if type(on_open) == "function" then
        symbols_loading = true
        subscription = {
          event = require("neo-tree.events").AFTER_RENDER,
          id = "user_document_symbols_on_open",
          handler = complete,
        }
        manager.subscribe("document_symbols", subscription)
      end

      local ok, err = pcall(nt.execute, {
        source = "document_symbols",
        position = "left",
        action = "focus",
      })
      if not ok then
        cleanup()
        vim.notify(tostring(err), vim.log.levels.ERROR)
        return
      end

      if subscription then
        -- A visible view can be focused without triggering another render.
        complete(manager.get_state("document_symbols"))

        -- Remove the listener if the second, Neo-tree-owned request stalls.
        vim.defer_fn(function()
          if completed then return end
          cleanup()
          vim.notify("Document symbols rendering timed out.", vim.log.levels.WARN)
        end, 120000)
      end
    end)
  )

  -- Keep the request alive while the server finishes its initial loading.
  vim.defer_fn(function()
    if finished then return end
    vim.notify("Still waiting for document symbols; the view will open when ready.", vim.log.levels.INFO)
  end, 10000)

  -- Bound stalled requests without discarding normal startup responses.
  vim.defer_fn(function()
    if finished then return end
    finished = true
    symbols_loading = false
    if cancel_request then cancel_request() end
    vim.notify("Document symbols request timed out after 120 seconds.", vim.log.levels.WARN)
  end, 120000)
end

function M.toggle_view()
  local next_source = "document_symbols"

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local state = manager.get_state_for_window(win)
    if state then
      next_source = state.name == "document_symbols" and "filesystem" or "document_symbols"
      break
    end
  end

  local highlight = next_source == "filesystem" and "NeoTreeNoticeFilesystem" or "NeoTreeNoticeSymbols"
  local label = next_source == "filesystem" and "File" or "Symbol"

  dismiss()

  if next_source == "document_symbols" then
    M.open_symbols(function()
      echo({{ label, highlight }, { " Tab" }}, true, {})
    end)
    return
  end

  echo({{ label, highlight }, { " Tab" }}, true, {})
  nt.execute({
    source = next_source,
    position = "left",
    action = "focus",
  })
end

require("neo-tree.ui.selector")

local original_click = _G.___neotree_selector_click

_G.___neotree_selector_click = function(id, clicks, button, mods)
  local sources = require("neo-tree").config.source_selector.sources or {}
  local source_index = id % (#sources + 1)
  local source = sources[source_index]

  if id > 0
    and button == "l"
    and source
    and source.source == "document_symbols"
  then
    vim.schedule(function()
      M.open_symbols()
    end)
    return
  end

  return original_click(id, clicks, button, mods)
end

return M
