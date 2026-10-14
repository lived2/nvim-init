--vim.keymap.set("n", "<Leader>dt", ':DapToggleBreakpoint<CR>')
--vim.keymap.set("n", "<Leader>dx", ':DapTerminate<CR>')
--vim.keymap.set("n", "<Leader>do", ':DapStepOver<CR>')
--vim.keymap.set("n", "<Leader>di", ':DapStepInto<CR>')
--vim.keymap.set("n", "<Leader>du", ':DapStepOut<CR>')

local dap = require("dap")

local editor_popup = require("configs.editor_popup")
local active_sessions = {}
local saved_keys = {}
local listener_id = "user.dap_lifecycle"
local neotree_restore

local function temporary_key(lhs, rhs)
  if saved_keys[lhs] then return end
  local expanded = vim.api.nvim_replace_termcodes(lhs, true, true, true)
  local original
  -- Inspect global mappings only; a focused panel may have local mappings.
  for _, mapping in ipairs(vim.fn.maplist()) do
    if mapping.buffer == 0 and (mapping.mode:find("n") or mapping.mode == " ")
      and vim.api.nvim_replace_termcodes(mapping.lhs, true, true, true) == expanded
    then
      original = mapping
      break
    end
  end
  saved_keys[lhs] = { original = original }
  vim.keymap.set("n", lhs, rhs, { silent = true })
end

local function restore_key(lhs)
  local saved = saved_keys[lhs]
  if not saved then return end
  if saved.original then
    vim.fn.mapset("n", false, saved.original)
  else
    pcall(vim.keymap.del, "n", lhs)
  end
  saved_keys[lhs] = nil
end

local function has_cpp_session()
  for _, ft in pairs(active_sessions) do
    if ft == "c" or ft == "cpp" then return true end
  end
  return false
end

local function enter_dap_mode(session)
  if active_sessions[session] then return end
  local first_session = next(active_sessions) == nil
  active_sessions[session] = session.filetype or ""

  if first_session then
    neotree_restore = { was_open = false }
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        neotree_restore.was_open = true
        break
      end
    end
    editor_popup.set_dap_mode(true)
    temporary_key("<F12>", "<cmd>DapTerminate<CR>")
  end
  if has_cpp_session() then
    temporary_key("<Leader>dh", "<cmd>DapViewHover!<CR>")
    temporary_key("<Leader>dw", "<cmd>DapViewWatch<CR>")
  end
  if first_session and neotree_restore.was_open then vim.cmd("Neotree close") end
end

local function leave_dap_mode(session)
  -- Termination and disconnect can both arrive for the same session.
  if not active_sessions[session] then return end
  active_sessions[session] = nil

  if not has_cpp_session() then
    restore_key("<Leader>dh")
    restore_key("<Leader>dw")
  end
  if next(active_sessions) then return end

  restore_key("<F12>")
  editor_popup.set_dap_mode(false)
  local restore = neotree_restore
  if not restore or not restore.was_open then return end
  -- Run after dap-view's synchronous close handlers, regardless of their order.
  vim.schedule(function()
    -- Ignore a pending restore if another debugging cycle has started.
    if neotree_restore == restore and not next(active_sessions) then
      vim.cmd("Neotree show last")
    end
  end)
end

dap.listeners.after.event_initialized[listener_id] = enter_dap_mode
-- Process exit alone does not mean the debugging session has ended.
dap.listeners.after.event_terminated[listener_id] = leave_dap_mode
dap.listeners.after.disconnect[listener_id] = function(session, err)
  if not err then leave_dap_mode(session) end
end

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local os = vim.loop.os_uname().sysname
local jit = require("jit")

local function target_path(sub_path)
  local target_program = vim.fn.getcwd() .. sub_path .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  if os == "Windows_NT" then
    target_program = target_program .. '.exe'
  end
  if file_exists(target_program) then
    return target_program
  else
    target_program = vim.fn.getcwd() .. sub_path .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    if os == "Windows_NT" then
      target_program = target_program .. '.exe'
    end
    return vim.fn.input('Path to executable: ', target_program, 'file')
  end
end

local launch_name = 'LLDB: Launch'
local launch_args_name = 'LLDB: Launch (args)'

-- C/C++/Rust/C3
if os == "Windows_NT" then
  LLDB_PATH = 'C:\\msys64\\clang64\\bin\\lldb-dap.exe'
  if jit.arch == "arm64" then
    LLDB_PATH = 'C:\\msys64\\clangarm64\\bin\\lldb-dap.exe'
  end
  dap.adapters.lldb = {
    type = 'executable',
    command = LLDB_PATH,
    name = 'lldb'
  }

  dap.configurations.cpp = {
    {
      name = launch_name,
      type = 'lldb',
      request = 'launch',
      program = function()
        return target_path('/target/debug/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = {}
    },
    {
      name = launch_args_name,
      type = 'lldb',
      request = 'launch',
      program = function()
        return target_path('/target/debug/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = function()
        return vim.split(vim.fn.input('Args: '), ' +', { trimempty = true })
      end,
    },
  }

  dap.adapters.codelldb = {
    type = "executable",
    command = LLDB_PATH,
  }

  dap.configurations.c3 = {
    {
      name = launch_name,
      type = 'lldb',
      request = 'launch',
      program = function()
        return target_path('/build/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = {}
    },
    {
      name = launch_args_name,
      type = 'lldb',
      request = 'launch',
      program = function()
        return target_path('/build/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = function()
        return vim.split(vim.fn.input('Args: '), ' +', { trimempty = true })
      end,
    },
  }
else
  -- MacOS/Linux
  dap.adapters.codelldb = {
    type = "executable",
    command = "codelldb",
  }

  dap.configurations.cpp = {
    {
      name = launch_name,
      type = 'codelldb',
      request = 'launch',
      program = function()
        return target_path('/target/debug/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = {},
      console = 'integratedTerminal',
    },
    {
      name = launch_args_name,
      type = 'codelldb',
      request = 'launch',
      program = function()
        return target_path('/target/debug/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = function()
        return vim.split(vim.fn.input('Args: '), ' +', { trimempty = true })
      end,
      console = 'integratedTerminal',
    },
  }

  dap.adapters.c3 = {
    type = 'executable',
    command = "codelldb",
  }

  dap.configurations.c3 = {
    {
      name = launch_name,
      type = 'c3',
      request = 'launch',
      program = function()
        return target_path('/build/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = {},
      console = 'integratedTerminal',
    },
    {
      name = launch_args_name,
      type = 'c3',
      request = 'launch',
      program = function()
        return target_path('/build/')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = function()
        return vim.split(vim.fn.input('Args: '), ' +', { trimempty = true })
      end,
      console = 'integratedTerminal',
    }
  }
end
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp


-- golang
dap.adapters.delve = function(callback, config)
  if config.mode == 'remote' and config.request == 'attach' then
    callback({
      type = 'server',
      host = config.host or '127.0.0.1',
      port = config.port or '38697'
    })
  else
    callback({
      type = 'server',
      port = '${port}',
      executable = {
        command = 'dlv',
        args = { 'dap', '-l', '127.0.0.1:${port}', '--log', '--log-output=dap' },
        detached = vim.fn.has("win32") == 0,
      }
    })
  end
end

-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}",
    outputMode = "remote",
  },
  {
    type = "delve",
    name = "Debug test", -- configuration for debugging test files
    request = "launch",
    mode = "test",
    program = "${file}",
    outputMode = "remote",
  },
  -- works with go.mod packages and sub packages
  {
    type = "delve",
    name = "Debug test (go.mod)",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}",
    outputMode = "remote",
  }
}
