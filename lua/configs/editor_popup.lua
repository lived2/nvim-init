local M = {}

local dap_mode = false
local popup_actions = {}

local separator_name = "────────────────────────"

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

local function add_menu(priority, name, id, action)
  popup_actions[id] = action

  local command = (
    "amenu %s PopUp.%s "
    .. "<Cmd>lua require('configs.editor_popup').execute(%q)<CR>"
  ):format(
    priority,
    escape_menu_name(name),
    id
  )

  registry.register(escape_menu_name(name))

  vim.cmd(command)
end

local function add_separator(priority)
  add_menu(
    priority,
    separator_name,
    "separator",
    function() end
  )
end

local function add_blank(priority, name)
  add_menu(
    priority,
    name,
    "blank",
    function() end
  )
end

function M.execute(id)
  if id == "separator" then
    return
  end

  local action = popup_actions[id]

  if not action then
    vim.notify(
      "Editor popup action not found: " .. tostring(id),
      vim.log.levels.ERROR
    )
    return
  end

  -- Delay execution until the Vim PopUp menu is closed.
  vim.schedule(function()
    action()
  end)
end

function M.set_dap_mode(enabled)
  dap_mode = enabled
end

function M.is_dap_mode()
  return dap_mode
end

local function enable_mouse_selection(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)

  local function move_cursor_to_mouse()
    local mouse = vim.fn.getmousepos()

    if mouse.winid ~= win then
      return false
    end

    if mouse.line <= 0 then
      return false
    end

    vim.api.nvim_set_current_win(win)

    local line_count = vim.api.nvim_buf_line_count(buf)
    local row = math.min(mouse.line, line_count)
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    local col = math.max(0, math.min(mouse.column - 1, #line))
    vim.api.nvim_win_set_cursor(win, {row, col})

    return true
  end

  -- Single click: select only.
  vim.keymap.set("n", "<LeftMouse>", function()
    move_cursor_to_mouse()
  end, {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = "Select Rust action",
    })

  -- Double click: select and execute the existing <CR> action.
  vim.keymap.set("n", "<2-LeftMouse>", function()
    if not move_cursor_to_mouse() then
      return
    end

    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end

      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      vim.api.nvim_set_current_win(win)

      local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)

      -- "m" resolves Rustaceanvim's existing buffer-local <CR> mapping.
      vim.api.nvim_feedkeys(enter, "m", false)
    end)
  end, {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = "Execute Rust action",
    })

  vim.keymap.set("n", "<Esc>", "<Cmd>close<CR>", {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close Rust action window",
  })

  vim.keymap.set("n", "q", "<Cmd>close<CR>", {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close Rust action window",
  })
end

local function configure_rust_float()
  vim.defer_fn(function()
    local current_tab = vim.api.nvim_get_current_tabpage()

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
      local config = vim.api.nvim_win_get_config(win)

      if config.relative ~= ""
        and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        enable_mouse_selection(win)
        return
      end
    end
  end, 100)
end

local function rust_hover_actions()
  -- First call opens the Hover Actions window.
  vim.cmd.RustLsp({'hover', 'actions'})

  -- Second call focuses the existing Hover Actions window.
  vim.defer_fn(function()
    vim.cmd.RustLsp({'hover', 'actions'})
    configure_rust_float()
  end, 50)
end

local function rust_code_action()
  vim.cmd.RustLsp('codeAction')
  configure_rust_float()
end

local function add_rust_menu()
  if vim.bo.filetype ~= "rust" then
    return
  end

  add_menu("10.40", "🦀 Hover Actions", "rust_hover_actions", rust_hover_actions)
  add_menu("10.50", "💡 Code Actions", "rust_code_action", rust_code_action)
  --[[
  add_menu("10.50", "📖 Open Docs", "rust_open_docs", function()
    vim.cmd("RustLsp openDocs")
  end)
  add_menu("10.60", "❓ Explain Error", "rust_explain_error", function()
    vim.cmd("RustLsp explainError")
  end)
  ]]
end

local function add_normal_menu()
  add_menu("10.10", "🚀 Run", "run", function() Run() end)
  add_menu("10.20", "🐞 Run Debug", "run_debug", function() RunDebug() end)
  add_menu("10.30", "🔴 Toggle Breakpoint", "toggle_breakpoint", function()
    require("dap").toggle_breakpoint()
  end)
  add_rust_menu()
  add_separator("10.99")
end

local function add_debug_menu()
  add_menu("10.10", "⤼ Step Over", "dap_step_over", function() require("dap").step_over() end)
  add_menu("10.20", "⤵ Step Into", "dap_step_into", function() require("dap").step_into() end)
  add_menu("10.30", "⤴ Step Out", "dap_step_out", function() require("dap").step_out() end)
  add_blank("10.35", "-SEP1-")
  add_menu("10.40", "🐞 Evaluate", "dap_evaluate", function() vim.cmd("DapViewHover!") end)
  add_menu("10.50", "👁 Add Watch", "dap_add_watch", function()
    require('dap-view').add_expr(vim.fn.expand('<cword>'))
  end)
  add_menu("10.60", "🔴 Toggle Breakpoint", "dap_toggle_breakpoint", function()
    require("dap").toggle_breakpoint()
  end)
  add_blank("10.65", "-SEP2-")
  add_menu("10.70", "▶ Continue", "dap_continue", function() require("dap").continue() end)
  add_menu("10.80", "⏸  Pause", "dap_pause", function() require("dap").pause() end)
  add_menu("10.90", "🔄 Restart", "dap_restart", function() require("dap").restart() end)
  add_menu("10.90", "⏹  Stop", "dap_terminate", function() require("dap").terminate() end)

  add_separator("10.99")
end

function M.show()
  clear_popup()

  if dap_mode then
    add_debug_menu()
  else
    add_normal_menu()
  end

  vim.cmd("popup PopUp")
end

function M.clear()
  clear_popup()
end

return M
