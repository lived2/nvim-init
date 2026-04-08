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
