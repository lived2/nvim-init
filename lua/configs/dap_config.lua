--vim.keymap.set("n", "<Leader>dt", ':DapToggleBreakpoint<CR>')
--vim.keymap.set("n", "<Leader>dx", ':DapTerminate<CR>')
--vim.keymap.set("n", "<Leader>do", ':DapStepOver<CR>')
--vim.keymap.set("n", "<Leader>di", ':DapStepInto<CR>')
--vim.keymap.set("n", "<Leader>du", ':DapStepOut<CR>')

local dap = require("dap")

local keymap = vim.keymap
local function set(mode, lhs, rhs)
  keymap.set(mode, lhs, rhs, { silent = true })
end


dap.listeners.after.event_initialized['me.dap.keys'] = function()
  set("n", "<down>", dap.step_over)
  set("n", "<left>", dap.step_out)
  set("n", "<right>", dap.step_into)
  --set("n", "<F12>", dap.terminate)
end
local reset_keys = function()
  pcall(keymap.del, "n", "<down>")
  pcall(keymap.del, "n", "<left>")
  pcall(keymap.del, "n", "<right>")
  --pcall(keymap.del, "n", "<F12>")
  --set('n', '<F12>', ':qall<CR>')
end
dap.listeners.after.event_terminated['me.dap.keys'] = reset_keys
dap.listeners.after.disconnected['me.dap.keys'] = reset_keys

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function target_path(sub_path)
  local target_program = vim.fn.getcwd() .. sub_path .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  if file_exists(target_program) then
    return target_program
  else
    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. sub_path .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), 'file')
  end
end

local launch_name = 'LLDB: Launch'
local launch_args_name = 'LLDB: Launch (args)'

-- C/C++/Rust/C3
local os = vim.loop.os_uname().sysname
local jit = require("jit")
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
