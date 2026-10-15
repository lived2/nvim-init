local M = {}
local directory = "workspace-sessions"
local using_stdin = false

local function session_name()
  -- Use the global cwd so a sidebar's local cwd cannot change the workspace.
  local cwd = vim.fn.getcwd(-1, -1)
  cwd = vim.fs.normalize(vim.uv.fs_realpath(cwd) or cwd)
  return vim.fn.fnamemodify(cwd, ":t") .. "-" .. vim.fn.sha256(cwd)
end

local function file_buffer(buf)
  return vim.bo[buf].buftype == "" and vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function sync_tabufline()
  if not package.loaded["nvchad.tabufline.lazyload"] then
    return
  end
  local files = vim.tbl_filter(file_buffer, vim.api.nvim_list_bufs())
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local buffers = {}
    -- Keep the current order, discard stale IDs, then add restored files.
    for _, buf in ipairs(vim.t[tab].bufs or {}) do
      if vim.api.nvim_buf_is_valid(buf) and file_buffer(buf) and not vim.tbl_contains(buffers, buf) then
        buffers[#buffers + 1] = buf
      end
    end
    for _, buf in ipairs(files) do
      if not vim.tbl_contains(buffers, buf) then
        buffers[#buffers + 1] = buf
      end
    end
    vim.t[tab].bufs = buffers
  end
  -- Resession suppresses the events that normally initialize the tabline.
  if vim.fn.exists("#TabuflineLazyLoad") == 1 then
    vim.api.nvim_exec_autocmds("BufRead", { group = "TabuflineLazyLoad", modeline = false })
  end
  vim.cmd.redrawtabline()
end

function M.save(automatic)
  local resession = require("resession")
  if resession.is_loading() then
    return
  end
  local name = session_name()
  -- Do not replace an existing session that the user has not restored yet.
  if automatic and resession.get_current() ~= name and vim.tbl_contains(resession.list(), name) then
    return
  end
  if not vim.iter(vim.api.nvim_list_bufs()):any(file_buffer) then
    return
  end
  resession.save(name, { notify = not automatic })
end

function M.load(automatic)
  local dap = package.loaded.dap
  if dap and next(dap.sessions()) then
    vim.notify("End the debug session before restoring a workspace.", vim.log.levels.WARN)
    return
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified then
      vim.notify("Save or discard modified buffers before restoring a workspace.", vim.log.levels.WARN)
      return
    end
  end
  local resession = require("resession")
  local name = session_name()
  if not vim.tbl_contains(resession.list(), name) then
    if not automatic then
      vim.notify("No saved session for this workspace.", vim.log.levels.INFO)
    end
    return
  end
  resession.load(name, { reset = true })
  require("resession.extensions.workspace_neotree").restore_pending()
  sync_tabufline()
  return true
end

function M.restore_on_startup()
  if using_stdin then
    return false
  end
  local files = {}
  local args = vim.fn.argv(-1, -1)
  ---@cast args string[]

  for _, arg in ipairs(args) do
    local path = vim.fn.fnamemodify(arg, ":p")
    if vim.fn.isdirectory(path) == 0 then
      files[#files + 1] = path
    end
  end
  -- Preserve files opened by another startup command or plugin.
  if #files == 0 and vim.iter(vim.api.nvim_list_bufs()):any(file_buffer) then
    return false
  end
  local ok, restored = pcall(M.load, true)
  if not ok then
    vim.notify("Workspace restore failed: " .. tostring(restored), vim.log.levels.ERROR)
  end
  if ok and restored and #files > 0 then
    -- Keep explicit file arguments alongside the restored workspace buffers.
    for _, path in ipairs(files) do
      local buf = vim.fn.bufadd(path)
      vim.bo[buf].buflisted = true
    end
    local target = vim.fn.bufnr(files[1])
    local code_win
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if
        vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[buf].buftype == ""
        and not vim.wo[win].winfixbuf
      then
        code_win = code_win or win
        if buf == target then
          code_win = win
          break
        end
      end
    end
    if code_win then
      vim.api.nvim_set_current_win(code_win)
    else
      vim.cmd("botright vnew")
    end
    vim.cmd.buffer(target)
    sync_tabufline()
  end
  return ok and restored == true
end

function M.delete()
  local resession = require("resession")
  local sessions = resession.list()
  local this_session = false
  if #sessions == 0 then
    vim.notify("No saved workspace sessions.", vim.log.levels.INFO)
    return
  end
  vim.ui.select(sessions, { prompt = "Delete workspace session:" }, function(name)
    if not name then
      return
    end
    if resession.get_current() == name then
      this_session = true
      resession.detach()
    end
    resession.delete(name, { notify = false })
    if this_session then
      -- Do not recreate the deleted snapshot when this Neovim instance exits.
      vim.api.nvim_clear_autocmds({ group = "WorkspaceSession", event = "VimLeavePre" })
      local indent = "          "
      vim.notify(string.format("Workspace %s session deleted.\n%sExit autosave disabled for this instance.", name, indent))
    else
      vim.notify(string.format("Workspace %s session deleted.", name))
    end
  end)
end

function M.setup()
  require("resession").setup({
    dir = directory,
    buf_filter = file_buffer,
    extensions = {
      workspace_breakpoints = {},
      workspace_neotree = {},
      workspace_tabufline = {},
    },
  })
  vim.keymap.set("n", "<leader>ss", function()
    M.save(false)
  end, { desc = "Save workspace session" })
  vim.keymap.set("n", "<leader>sl", M.load, { desc = "Restore workspace session" })
  vim.keymap.set("n", "<leader>sd", M.delete, { desc = "Delete workspace session" })
  vim.api.nvim_create_user_command("WorkspaceSave", function()
    M.save(false)
  end, {})
  vim.api.nvim_create_user_command("WorkspaceLoad", function()
    M.load(false)
  end, {})
  vim.api.nvim_create_user_command("WorkspaceDelete", M.delete, {})
  local group = vim.api.nvim_create_augroup("WorkspaceSession", { clear = true })
  vim.api.nvim_create_autocmd("StdinReadPre", {
    group = group,
    callback = function()
      using_stdin = true
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      local ok, err = pcall(M.save, true)
      if not ok then
        vim.notify("Workspace save failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    end,
  })
end

return M
