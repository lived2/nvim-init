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
