local M = {}

function M.on_save()
  local result = {}
  local breakpoints = package.loaded["dap.breakpoints"]
  if not breakpoints then
    return result
  end
  for buf, points in pairs(breakpoints.get()) do
    local path = vim.api.nvim_buf_get_name(buf)
    if path ~= "" and vim.bo[buf].buftype == "" then
      local saved = {}
      for _, point in ipairs(points) do
        saved[#saved + 1] = {
          line = point.line,
          condition = point.condition,
          hit_condition = point.hitCondition,
          log_message = point.logMessage,
        }
      end
      result[path] = saved
    end
  end
  return result
end

function M.on_post_load(data)
  require("dap") -- Define breakpoint signs before placing them.
  local breakpoints = require("dap.breakpoints")
  breakpoints.clear()
  for path, points in pairs(data) do
    if vim.fn.filereadable(path) == 1 then
      local buf = vim.fn.bufadd(path)
      vim.fn.bufload(buf)
      for _, point in ipairs(points) do
        if point.line > 0 and point.line <= vim.api.nvim_buf_line_count(buf) then
          breakpoints.set({
            condition = point.condition,
            hit_condition = point.hit_condition,
            log_message = point.log_message,
          }, buf, point.line)
        end
      end
    end
  end
end

return M
