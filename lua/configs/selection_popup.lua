local M = {}
local selection
local menu = "PopUp"
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)

local function normal(keys)
  vim.cmd.normal({ args = { keys }, bang = true })
end

local function restore(saved)
  normal(esc)
  vim.fn.setpos(".", saved.anchor)
  normal(saved.mode)
  vim.fn.setpos(".", saved.cursor)
end

local function format_range(saved)
  local first, last = saved.anchor, saved.cursor
  if first[2] > last[2] or (first[2] == last[2] and first[3] > last[3]) then
    first, last = last, first
  end
  local start_col, end_col = first[3] - 1, last[3] - 1
  local line = vim.api.nvim_buf_get_lines(saved.buf, last[2] - 1, last[2], false)[1]
  -- Formatters accept contiguous ranges, not rectangular selections.
  if saved.mode ~= "v" then
    start_col = 0
    end_col = #line
  else
    end_col = math.min(end_col, #line)
    -- Conform's range end is exclusive. Include the entire final UTF-8
    -- character when Visual selection includes its endpoint.
    if saved.selection ~= "exclusive" then
      end_col = end_col + #vim.fn.strcharpart(line:sub(end_col + 1), 0, 1)
    end
  end
  return { start = { first[2], start_col }, ["end"] = { last[2], end_col } }
end

function M.execute(action)
  local saved = selection
  selection = nil
  if not saved then return end

  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(saved.win)
      or vim.api.nvim_get_current_win() ~= saved.win
      or vim.api.nvim_win_get_buf(saved.win) ~= saved.buf
      or vim.bo[saved.buf].buftype ~= ""
      or vim.api.nvim_buf_get_changedtick(saved.buf) ~= saved.tick
    then
      return
    end
    if action ~= "copy" and not vim.bo[saved.buf].modifiable then
      vim.notify("This buffer is not modifiable", vim.log.levels.WARN)
      return
    end

    if action == "format" then
      normal(esc)
      local range = format_range(saved)
      if vim.bo[saved.buf].filetype == "lua" then
        require("configs.selection_format").lua(saved.buf, range)
      else
        require("conform").format({ bufnr = saved.buf, range = range })
      end
    elseif action == "copy" or action == "delete" then
      restore(saved)
      if action == "delete" then
        normal("d")
      else
        normal("y")
        if vim.fn.has("clipboard") == 1 then
          vim.fn.setreg("+", vim.fn.getreg('"', 1, true), vim.fn.getregtype('"'))
        end
      end
    end
  end)
end

function M.prepare()
  local mode = vim.fn.mode()
  local win = vim.api.nvim_get_current_win()
  local mouse = vim.fn.getmousepos()
  if vim.bo.buftype ~= "" or mouse.winid ~= win
    or (mode ~= "v" and mode ~= "V" and mode ~= "\22")
  then
    return false
  end

  selection = {
    buf = vim.api.nvim_get_current_buf(), win = win, mode = mode,
    anchor = vim.fn.getpos("v"), cursor = vim.fn.getpos("."),
    selection = vim.o.selection,
    tick = vim.api.nvim_buf_get_changedtick(0),
  }
  require("configs.popup_registry").clear()
  for i, item in ipairs({
    { "Format Selection", "format" },
    { "Delete Selection", "delete" },
    { "Copy Selection", "copy" },
  }) do
    vim.cmd(("vnoremenu %d %s.%s <Cmd>lua require('configs.selection_popup').execute(%q)<CR>")
      :format(i * 10, menu, item[1]:gsub(" ", "\\ "), item[2]))
    require("configs.popup_registry").register(item[1]:gsub(" ", "\\ "))
  end
  return true
end

function M.open_at_mouse()
  -- Visual right-click may be the first context-menu interaction this session.
  -- Install the native MenuPopup handler before modifying the shared menu.
  require("configs.context_menu")
  if M.prepare() then
    vim.cmd("popup! " .. menu)
  end
end

return M
