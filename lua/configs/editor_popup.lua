local M = {}

local map = vim.keymap.set
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

  --registry.register(escape_menu_name(name))

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
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  local buf = vim.api.nvim_win_get_buf(win)

  local function close_float()
    if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
  end

  local function move_cursor_to_mouse(mouse)
    if not mouse or mouse.winid == 0 or not vim.api.nvim_win_is_valid(mouse.winid) then return false end

    local target_win = mouse.winid
    local target_buf = vim.api.nvim_win_get_buf(target_win)
    local line_count = vim.api.nvim_buf_line_count(target_buf)

    if line_count == 0 then
      return false
    end

    local row = math.max(1, math.min(mouse.line, line_count))
    local line = vim.api.nvim_buf_get_lines(target_buf, row - 1, row, false)[1] or ""
    local col = math.max(0, math.min(mouse.column - 1, #line))

    vim.api.nvim_set_current_win(target_win)
    vim.api.nvim_win_set_cursor(target_win, { row, col })

    return true
  end

  -- Single left click:
  -- Select inside the float, or close and focus the clicked window outside.
  map("n", "<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()

    if mouse.winid == win then
      move_cursor_to_mouse(mouse)
      return
    end

    close_float()
    vim.schedule(function() move_cursor_to_mouse(mouse) end)
  end, {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = "Select Rust action or close popup",
    })

  -- Double left click:
  -- Select and execute inside the float.
  map("n", "<2-LeftMouse>", function()
    local mouse = vim.fn.getmousepos()

    if mouse.winid ~= win then
      close_float()
      vim.schedule(function() move_cursor_to_mouse(mouse) end)
      return
    end

    if not move_cursor_to_mouse(mouse) then return end

    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(buf) then return end

      vim.api.nvim_set_current_win(win)

      local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      vim.api.nvim_feedkeys(enter, "m", false)
    end)
  end, {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = "Execute Rust action",
    })

  -- Right click:
  -- Keep the Rust float open when clicking inside it.
  -- Close it and open the corresponding context menu when clicking outside.
  map("n", "<RightMouse>", function()
    local mouse = vim.fn.getmousepos()

    if mouse.winid == win then
      return
    end

    close_float()

    vim.schedule(function()
      require("configs.context_menu").open_at_mouse(mouse)
    end)
  end, {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = "Close Rust popup and open context menu",
    })

  map("n", "<Esc>", close_float, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close Rust action popup",
  })

  map("n", "q", close_float, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close Rust action popup",
  })

  map("n", "<Tab>", "<Down>", {
    buffer = buf,
    silent = true,
    nowait = true,
    remap = false,
  })

  map("n", "<S-Tab>", "<Up>", {
    buffer = buf,
    silent = true,
    nowait = true,
    remap = false,
  })
end

local function is_rust_hover_float(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  if vim.api.nvim_win_get_config(win).relative == "" then
    return false
  end

  local ok, source_buf = pcall(
    vim.api.nvim_win_get_var,
    win,
    "rust-analyzer-hover-actions"
  )

  return ok and type(source_buf) == "number"
end

local function is_rust_action_float(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  if is_rust_hover_float(win) then
    return true
  end

  local config = vim.api.nvim_win_get_config(win)
  if config.relative == "" then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "nofile" or vim.bo[buf].filetype ~= "markdown" then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, math.min(20, vim.api.nvim_buf_line_count(buf)), false)
  if vim.tbl_isempty(lines) then
    return false
  end

  local enter_map = vim.api.nvim_buf_call(buf, function()
    return vim.fn.maparg("<CR>", "n", false, true)
  end)

  return type(enter_map) == "table"
    and enter_map.buffer == 1
    and enter_map.callback ~= nil
end

--[[
local function configure_rust_float()
  local attempts = 0

  local function find_float()
    attempts = attempts + 1

    local current_tab = vim.api.nvim_get_current_tabpage()

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
      if is_rust_action_float(win) then
        vim.api.nvim_set_current_win(win)
        enable_mouse_selection(win)
        return
      end
    end

    if attempts < 20 then vim.defer_fn(find_float, 25) end
  end

  vim.defer_fn(find_float, 25)
end
]]

local function configure_rust_float(kind)
  local attempts = 0

  local function matches(win)
    if kind == "hover" then
      return is_rust_hover_float(win)
    end

    -- Code Actions를 찾을 때 기존 Hover는 제외
    return not is_rust_hover_float(win)
      and is_rust_action_float(win)
  end

  local function find_float()
    attempts = attempts + 1

    local current_tab = vim.api.nvim_get_current_tabpage()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
      if matches(win) then
        vim.api.nvim_set_current_win(win)
        enable_mouse_selection(win)
        return
      end
    end

    if attempts < 20 then
      vim.defer_fn(find_float, 25)
    end
  end

  vim.defer_fn(find_float, 25)
end

local function rust_hover_actions()
  -- First call opens the Hover Actions window.
  vim.cmd.RustLsp({'hover', 'actions'})
  configure_rust_float("hover")

  -- Second call focuses the existing Hover Actions window.
  --vim.defer_fn(function()
    --vim.cmd.RustLsp({'hover', 'actions'})
    --configure_rust_float("hover")
  --end, 50)
end

local function rust_code_action()
  vim.cmd.RustLsp('codeAction')
  configure_rust_float("code_action")
end

local function add_rust_menu()
  if vim.bo.filetype ~= "rust" then
    return
  end

  add_menu("10.50", "🦀 Hover Actions", "rust_hover_actions", rust_hover_actions)
  add_menu("10.60", "💡 Code Actions", "rust_code_action", rust_code_action)
  --[[
  add_menu("10.50", "📖 Open Docs", "rust_open_docs", function()
    vim.cmd("RustLsp openDocs")
  end)
  add_menu("10.60", "❓ Explain Error", "rust_explain_error", function()
    vim.cmd("RustLsp explainError")
  end)
  ]]
end

local group = vim.api.nvim_create_augroup("RustActionNavigation", {
  clear = true,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function(ev)
    -- Wait until rustaceanvim has installed the Enter mapping.
    vim.schedule(function()
      local buf = ev.buf
      if not vim.api.nvim_buf_is_valid(buf) then return end
      if vim.bo[buf].buftype ~= "nofile" then return end

      -- Avoid applying these mappings to other Markdown windows.
      local is_code_action = false
      for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
        if mapping.lhs == "<CR>"
          and type(mapping.callback) == "function"
        then
          local info = debug.getinfo(mapping.callback, "S")
          local source = info.source:gsub("\\", "/")
          is_code_action = source:find(
            "/rustaceanvim/commands/code_action_group.lua",
            1,
            true
          ) ~= nil
          break
        end
      end

      if not is_code_action then return end

      local opts = {
        buffer = buf,
        silent = true,
        nowait = true,
        remap = false,
      }
      map("n", "<Tab>", "<Down>", opts)
      map("n", "<S-Tab>", "<Up>", opts)
    end)
  end,
})

local function add_normal_menu()
  add_menu("10.10", "🚀 Run", "run", function() Run() end)
  add_menu("10.20", "🐞 Run Debug", "run_debug", function() RunDebug() end)
  add_menu("10.30", "🔴 Toggle Breakpoint", "toggle_breakpoint", function() require("dap").toggle_breakpoint() end)
  add_menu("10.40", "🔍 Git: Preview Hunk", "git_preview_hunk", function() require("gitsigns").preview_hunk() end)
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

function M.prepare()
  clear_popup()
  registry.restore_normal_defaults()

  if dap_mode then
    add_debug_menu()
  else
    add_normal_menu()
  end
end

function M.show()
  M.prepare()
  vim.cmd("popup PopUp")
end

function M.clear()
  clear_popup()
end

return M
