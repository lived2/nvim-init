local M = {}

-- Map a line boundary through formatter edits without expanding the selection.
local function map_boundary(boundary, hunks)
  local delta = 0
  for _, hunk in ipairs(hunks) do
    local start, count, target, replacement = unpack(hunk)
    local before = count == 0 and start or start - 1
    if boundary <= before then return boundary + delta end
    if boundary < before + count then
      if count ~= replacement then return nil end
      return target - 1 + boundary - before
    end
    delta = delta + replacement - count
  end
  return boundary + delta
end

function M.lua(buf, range)
  local function warn(message)
    vim.notify(message, vim.log.levels.WARN)
  end
  local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local first, last = range.start[1], range["end"][1]
  if original[first]:sub(1, range.start[2]):match("%S")
    or original[last]:sub(range["end"][2] + 1):match("%S")
  then
    warn("Lua selection formatting: select complete lines (V).")
    return
  end

  local conform = require("conform")
  if not conform.get_formatter_info("stylua", buf).available then
    warn("Lua selection formatting: StyLua is unavailable. See :ConformInfo.")
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  -- No range: StyLua needs the enclosing syntax, including return-table entries.
  -- format_lines computes output without editing or saving the source buffer.
  local err, formatted = conform.format_lines({ "stylua" }, original, { bufnr = buf })
  if err or not formatted then
    warn("Lua selection formatting failed. See :ConformInfo.")
    return
  end
  if vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end

  local hunks = vim.text.diff(
    table.concat(original, "\n") .. "\n",
    table.concat(formatted, "\n") .. "\n",
    {
      result_type = "indices",
      algorithm = "histogram",
    })
  local start = map_boundary(first - 1, hunks)
  local finish = map_boundary(last, hunks)
  if not start or not finish then
    warn("Lua selection crosses a formatter edit that changes line count. Select the complete surrounding block.")
    return
  end

  local replacement = vim.list_slice(formatted, start + 1, finish)
  local candidate = vim.list_slice(original, 1, first - 1)
  vim.list_extend(candidate, replacement)
  vim.list_extend(candidate, vim.list_slice(original, last + 1))
  -- Do not apply a clipped edit that would break otherwise valid Lua syntax.
  if loadstring(table.concat(original, "\n")) and not loadstring(table.concat(candidate, "\n")) then
    warn("Lua selection formatting would break syntax. Select the complete surrounding block.")
    return
  end
  if not vim.deep_equal(original, candidate) then
    vim.api.nvim_buf_set_lines(buf, first - 1, last, false, replacement)
  end
end

return M
