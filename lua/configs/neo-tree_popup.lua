local M = {}

local common_commands = require("neo-tree.sources.common.commands")
local filesystem_commands = require("neo-tree.sources.filesystem.commands")
local create_commands = require("configs.neo-tree_create")
--local buffer_commands = require("neo-tree.sources.buffers.commands")
local git_commands = require("neo-tree.sources.git_status.commands")
local symbol_commands = require("neo-tree.sources.document_symbols.commands")

local popup_context = {
  state = nil,
  actions = {},
}

--local separator_name = "────────────────────────"

-- Escape characters used by the :menu command.
local function escape_menu_name(name)
  return name
    :gsub("\\", "\\\\")
    :gsub(" ", "\\ ")
    :gsub("%.", "\\.")
end

local registry = require("configs.popup_registry")

local function clear_popup()
  registry.clear()
end

-- Register an action and create the corresponding PopUp entry.
local function add_menu(priority, name, id, action)
  --popup_context.actions[id] = action
  popup_context.actions[id] = function(state)
    state.config = state.config or {}
    return action(state)
  end

  local command = (
    "amenu %s PopUp.%s "
    .. "<Cmd>lua require('configs.neo-tree_popup').execute(%q)<CR>"
  ):format(
    priority,
    escape_menu_name(name),
    id
  )

  --registry.register(escape_menu_name(name))

  vim.cmd(command)
end

-- Add a non-functional menu entry that looks like a separator line.
--[[
local function add_separator(priority)
  add_menu(priority, separator_name, "separator", function() end)
end
]]

-- Temporarily select the root line before invoking an action.
local function run_on_root(state, action)
  if not state or not state.winid then
    return
  end

  if not vim.api.nvim_win_is_valid(state.winid) then
    return
  end

  local previous_cursor = vim.api.nvim_win_get_cursor(state.winid)

  -- Neo-tree normally renders its root node on line 1.
  vim.api.nvim_win_set_cursor(state.winid, {1, 0})

  action(state)

  -- Restore the original cursor after the action has started.
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(state.winid) then
      return
    end

    local line_count = vim.api.nvim_buf_line_count(state.bufnr)
    local row = math.min(previous_cursor[1], line_count)
    vim.api.nvim_win_set_cursor(state.winid, {row, previous_cursor[2]})
  end)
end

-- Build filesystem menus according to the selected node type.
local function add_filesystem_menu(node)
  --vim.notify(("MENU BUILD : %s (%s)"):format(node.name, node.type))

  if node.type == "file" then
    add_menu("10.10", "📂 Open", "filesystem_open", common_commands.open)
    add_menu("10.20", "✏ Rename", "filesystem_rename", filesystem_commands.rename)
    add_menu("10.30", "🗑 Delete", "filesystem_delete", filesystem_commands.delete)
    add_menu("10.40", "🔄 Refresh", "filesystem_refresh", filesystem_commands.refresh)
    --add_separator("10.99")
    return
  end

  if node.type == "directory" then
    --add_menu("10.10", "📁 Expand or Collapse", "filesystem_toggle_directory", common_commands.open)
    --add_menu("10.10", "📁 Expand or Collapse", "filesystem_toggle_directory", require("configs.neo-tree_popup").toggle_dir)
    add_menu("10.10", "📁 Expand or Collapse", "filesystem_toggle_directory", filesystem_commands.toggle_node)
    add_menu("10.20", "📂 Set as Root", "filesystem_set_root", filesystem_commands.set_root)
    add_menu("10.30", "📄 New File", "filesystem_add_file", create_commands.add)
    add_menu("10.40", "📁 New Directory", "filesystem_add_directory", create_commands.add_directory)
    add_menu("10.50", "✏ Rename", "filesystem_rename", filesystem_commands.rename)
    add_menu("10.60", "🗑 Delete", "filesystem_delete", filesystem_commands.delete)
    add_menu("10.70", "🔄 Refresh", "filesystem_refresh", filesystem_commands.refresh)
    --add_separator("10.99")
    return
  end

  -- Fallback for root, message, or unknown node types.
  add_menu("10.10", "📄 New File", "filesystem_add_file", create_commands.add)
  add_menu("10.20", "📁 New Directory", "filesystem_add_directory", create_commands.add_directory)
  add_menu("10.30", "🔄 Refresh", "filesystem_refresh", filesystem_commands.refresh)
  --add_separator("10.99")
end

-- Build the filesystem menu for a right-click on empty space.
local function add_filesystem_empty_menu()
  add_menu("10.10", "📄 New File in Root", "filesystem_add_file_root", function(state)
    run_on_root(state, create_commands.add)
  end)

  add_menu("10.20", "📁 New Directory in Root", "filesystem_add_directory_root", function(state)
    run_on_root(state, create_commands.add_directory)
  end)

  add_menu("10.30", "🔄 Refresh", "filesystem_refresh", filesystem_commands.refresh)
  --add_separator("10.99")
end

-- Build the buffers-source menu.
local function add_buffers_menu(node)
  if node.type == "root" or node.type == "message" then
    return
  end

  add_menu("10.10", "📄 Open Buffer", "buffer_open", common_commands.open)
  --add_menu("10.20", "❌ Delete Buffer", "buffer_delete", buffer_commands.buffer_delete)
  add_menu("10.20", "❌ Close Buffer", "buffer_delete", require("configs.neo-tree_popup").close_nvchad_buffer)
  --add_separator("10.99")
end

-- Build the git-status-source menu.
local function add_git_menu(node)
  if node.type == "directory" then
    add_menu("10.10", "📁 Expand or Collapse", "git_toggle_directory", common_commands.open)
    add_menu("10.20", "➕ Stage", "git_stage_directory", git_commands.git_add_file)
    add_menu("10.30", "↩ Unstage", "git_unstage_directory", git_commands.git_unstage_file)
    --add_separator("10.99")
    return
  end

  if node.type == "root" or node.type == "message" then
    return
  end

  add_menu("10.10", "📂 Open", "git_open", common_commands.open)
  add_menu("10.20", "➕ Stage", "git_stage", git_commands.git_add_file)
  add_menu("10.30", "↩ Unstage", "git_unstage", git_commands.git_unstage_file)
  add_menu("10.40", "⚠ Revert", "git_revert", git_commands.git_revert_file)
  add_menu("10.50", "✓ Commit", "git_commit", git_commands.git_commit)
  --add_separator("10.99")
end

-- Build the document-symbols-source menu.
local function add_symbols_menu(node)
  if node.type == "root" then
    add_menu("10.10", "📁 Expand or Collapse", "symbol_toggle_root", common_commands.open)
    --add_separator("10.99")
    return
  end

  if node.type ~= "symbol" then
    return
  end

  add_menu("10.10", "📍 Jump to Symbol", "symbol_jump", symbol_commands.jump_to_symbol)
  add_menu("10.20", "🔍 Preview Symbol", "symbol_preview", symbol_commands.preview)
  add_menu("10.30", "✏ Rename Symbol", "symbol_rename", symbol_commands.rename)
  add_menu("10.40", "↔ Open in Split", "symbol_split", symbol_commands.open_split)
  add_menu("10.50", "↕ Open in VSplit", "symbol_open_vsplit", symbol_commands.open_vsplit)
  --add_separator("10.99")
end

-- Build and display the appropriate menu.
function M.prepare(state, node)
  M.clear()

  if not state or not state.tree then
    return false
  end

  popup_context.state = state
  popup_context.actions = {}

  local source = state.name or vim.b[state.bufnr].neo_tree_source or vim.b[state.bufnr].source

  if not node then
    if source ~= "filesystem" then
      return false
    end
    add_filesystem_empty_menu()
  elseif source == "filesystem" then
    add_filesystem_menu(node)
  elseif source == "buffers" then
    add_buffers_menu(node)
  elseif source == "git_status" then
    add_git_menu(node)
  elseif source == "document_symbols" then
    add_symbols_menu(node)
  else
    return false
  end

  return true
end

function M.open(state, node)
  if M.prepare(state, node) then
    vim.cmd("popup PopUp")
  end
end

-- Remove every menu entry managed by this module.
function M.clear()
  clear_popup()
  popup_context.actions = {}
  popup_context.state = nil
end

function M.execute(id)
  if id == "separator" then
    return
  end

  local action = popup_context.actions[id]
  local state = popup_context.state

  if not action then
    vim.notify(
      "Neo-tree popup action not found: "
      .. tostring(id),
      vim.log.levels.ERROR
    )
    return
  end

  if not state then
    vim.notify(
      "Neo-tree popup state is not available",
      vim.log.levels.ERROR
    )
    return
  end

  vim.schedule(function()
    action(state)
  end)
end

M.close_nvchad_buffer = function(state)
  if not state or not state.tree then
    vim.notify("Cannot find Neo-tree state.", vim.log.levels.ERROR)
    return
  end

  local node = state.tree:get_node()
  if node and node.type == "file" then
    local bufnr = node.extra.bufnr
    if bufnr then
      require("nvchad.tabufline").close_buffer(bufnr)
    end
  end
end

return M
