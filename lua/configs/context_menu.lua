local M = {}
local request_serial = 0

local function move_cursor_to_mouse(mouse)
  if not mouse or mouse.winid == 0 or not vim.api.nvim_win_is_valid(mouse.winid) then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(mouse.winid)
  local line_count = vim.api.nvim_buf_line_count(buf)

  if line_count == 0 then
    return false
  end

  local row = math.max(1, math.min(mouse.line, line_count))
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local col = math.max(0, math.min(mouse.column - 1, #line))

  vim.api.nvim_set_current_win(mouse.winid)
  vim.api.nvim_win_set_cursor(mouse.winid, { row, col })

  return true
end

function M.open_at_mouse(mouse)
  request_serial = request_serial + 1
  local request_id = request_serial

  mouse = mouse or vim.fn.getmousepos()

  if not mouse or mouse.winid == 0 or not vim.api.nvim_win_is_valid(mouse.winid) then
    return
  end
  if not move_cursor_to_mouse(mouse) then
    return
  end

  pcall(function()
    require("configs.popup_registry").clear()
  end)

  local buf = vim.api.nvim_win_get_buf(mouse.winid)
  local ft = vim.bo[buf].filetype

  if ft == "neo-tree" then
    local row = math.max(1, math.min(mouse.line, vim.api.nvim_buf_line_count(buf)))
    local source = vim.b[buf].neo_tree_source or vim.b[buf].source or "filesystem"
    local state = require("neo-tree.sources.manager").get_state(source)

    if not state or not state.tree then return end

    vim.api.nvim_set_current_win(mouse.winid)
    vim.api.nvim_win_set_cursor(mouse.winid, { row, math.max(0, mouse.column - 1) })
    vim.cmd("redraw")

    local node = state.tree:get_node(row)

    if node then
      require("configs.neo-tree_popup").open(state, node)
      return
    end

    -- Re-try at next tick if Neo-tree line mapping is on-going
    vim.schedule(function()
      if request_id ~= request_serial then
        return
      end

      if not vim.api.nvim_win_is_valid(mouse.winid) then
        return
      end

      if vim.api.nvim_win_get_buf(mouse.winid) ~= buf then
        return
      end

      if vim.api.nvim_get_current_win() ~= mouse.winid then
        return
      end

      local current_state = require("neo-tree.sources.manager").get_state(source)
      if not current_state or not current_state.tree then
        return
      end

      local current_node = current_state.tree:get_node(row)

      if not current_node then
        vim.notify(
          ("No Neo-tree node at row %d"):format(row),
          vim.log.levels.DEBUG
        )
        return
      end

      require("configs.neo-tree_popup").open(current_state, current_node)
    end)

    return
  end

  vim.schedule(function()
    if request_id ~= request_serial then
      return
    end

    if not vim.api.nvim_win_is_valid(mouse.winid) then
      return
    end

    if vim.api.nvim_win_get_buf(mouse.winid) ~= buf then
      return
    end

    if vim.api.nvim_get_current_win() ~= mouse.winid then
      return
    end
    require("configs.editor_popup").show()
  end)
end

-- This config owns PopUp; the built-in callback assumes its default entries
-- exist in every mode and errors after we replace the Visual menu.
pcall(vim.api.nvim_clear_autocmds, { group = "nvim.popupmenu", event = "MenuPopup" })
local group = vim.api.nvim_create_augroup("DynamicContextMenu", { clear = true })

vim.api.nvim_create_autocmd("MenuPopup", {
  group = group,
  pattern = { "n", "v" },
  callback = function(event)
    request_serial = request_serial + 1

    if event.match == "v" then
      require("configs.selection_popup").prepare()
      return
    end

    local mouse = vim.fn.getmousepos()

    --print("MENU_POPUP", vim.inspect(mouse))

    if mouse.winid == 0
      or not vim.api.nvim_win_is_valid(mouse.winid)
    then
      return
    end

    local buf = vim.api.nvim_win_get_buf(mouse.winid)
    if vim.bo[buf].filetype ~= "neo-tree" then
      if not move_cursor_to_mouse(mouse) then
        return
      end

      require("configs.editor_popup").prepare()
      return
    end

    local source = vim.b[buf].neo_tree_source or vim.b[buf].source or "filesystem"

    vim.api.nvim_set_current_win(mouse.winid)

    local state = require("neo-tree.sources.manager").get_state(source)

    if not state or not state.tree then
      return
    end

    local node
    local row = mouse.line
    local count = vim.api.nvim_buf_line_count(buf)

    if row >= 1 and row <= count then
      vim.api.nvim_win_set_cursor(mouse.winid, { row, 0 })
      node = state.tree:get_node(row)
    end

    --print("MENU_POPUP NODE", node and node.name, node and node.type)

    require("configs.neo-tree_popup").prepare(state, node)
  end,
})

return M
