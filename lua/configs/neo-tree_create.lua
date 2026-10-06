local M = {}

local function create(state, command)
  local win, buf = state.winid, state.bufnr
  local function window_exists()
    return win and vim.api.nvim_win_is_valid(win)
      and vim.api.nvim_win_get_buf(win) == buf
  end

  require("neo-tree.sources.common.commands")[command](state, function(destination)
    if not destination or not window_exists() then return end
    local utils = require("neo-tree.utils")
    destination = utils.remove_trailing_slash(utils.normalize_path(destination))
    require("neo-tree.sources.filesystem").navigate(state, state.path, destination, function()
      if not window_exists() then return end
      require("neo-tree.ui.renderer").focus_node(state, destination)
    end)
  end)
end

function M.add(state)
  create(state, "add")
end

function M.add_directory(state)
  create(state, "add_directory")
end

return M
