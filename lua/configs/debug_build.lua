local M = {}
local configured = false

local function setup_picker_cleanup()
  if configured then return end
  configured = true

  local ui = require("dap.ui")
  local pick_if_many = ui.pick_if_many
  ui.pick_if_many = function(items, prompt, label_fn, callback)
    -- Only the debugger configuration picker owns the build output.
    if prompt ~= "Configuration: " or not callback then
      return pick_if_many(items, prompt, label_fn, callback)
    end

    local view = require("noice.view").get_view("debug_build", {})
    if not view or not view._visible then
      return pick_if_many(items, prompt, label_fn, callback)
    end

    return pick_if_many(items, prompt, label_fn, function(choice)
      -- A nil choice means cancellation; both paths close only this view.
      view:clear()
      view:display()
      callback(choice)
    end)
  end
end

function M.run(command)
  setup_picker_cleanup()
  require("noice").redirect(function()
    vim.cmd(command)
  end, {
    { filter = { event = "msg_show" }, view = "debug_build" },
  })
end

return M
