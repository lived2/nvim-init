local M = {}

function M.is_panel()
  local state = package.loaded["dap-view.state"]
  return state ~= nil and state.winnr == vim.api.nvim_get_current_win()
end

local function idle()
  local dap = package.loaded.dap
  return not dap or next(dap.sessions()) == nil
end

function M.close_if_idle()
  if not M.is_panel() or not idle() then return false end
  require("dap-view").close()
  return true
end

function M.clear_breakpoints()
  require("dap").clear_breakpoints()
  local state = package.loaded["dap-view.state"]
  if state and state.current_section == "breakpoints" then
    -- Refresh the data without opening the panel or moving focus into it.
    require("dap-view.views").switch_to_view("breakpoints")
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("IdleDapPanelKeys", { clear = true }),
    callback = function(event)
      if not M.is_panel() then return end
      for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, function()
          if M.is_panel() and idle() then
            -- Close outside the expression mapping's textlock.
            return "<Cmd>lua require('configs.dap_panel').close_if_idle()<CR>"
          end
          return key
        end, { buffer = event.buf, expr = true, silent = true, desc = "Close DAP panel when not debugging" })
      end
    end,
  })
end

return M
