local M = {}

function M.close(force, write)
  local suffix = force and "!" or ""
  if vim.fn.getcmdwintype() ~= "" then
    vim.cmd("quit" .. suffix)
    return
  end

  local panel = require("configs.dap_panel")
  if panel.is_panel() then
    panel.close_if_idle()
    return
  end

  if write then
    vim.cmd("write" .. suffix)
  end
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype ~= "" or not vim.bo[current].buflisted then
    vim.cmd("quit" .. suffix)
    return
  end
  if vim.bo[current].modified and not force then
    vim.api.nvim_echo({ { "No write since last change (add ! to override)", "ErrorMsg" } }, true, {})
    return
  end

  local buffers = {}
  local function add(buf)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == "" and not vim.tbl_contains(buffers, buf) then
      buffers[#buffers + 1] = buf
    end
  end
  for _, buf in ipairs(vim.t.bufs or {}) do
    add(buf)
  end
  -- Prefer the tabline order, but do not lose hidden buffers missing from it.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    add(buf)
  end
  if #buffers > 1 then
    local index = 1
    for i, buf in ipairs(buffers) do
      if buf == current then
        index = i
        break
      end
    end
    local next_buf = buffers[index + 1] or buffers[index - 1]
    vim.cmd("buffer" .. suffix .. " " .. next_buf)
    if vim.api.nvim_buf_is_valid(current) then
      vim.api.nvim_buf_delete(current, { force = force or false })
    end
    vim.cmd.redrawtabline()
  else
    -- Exit before any window expands, so session saving sees the original layout.
    vim.cmd("qall" .. suffix)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("Q", function(opts)
    M.close(opts.bang, false)
  end, { bang = true })
  vim.api.nvim_create_user_command("Wq", function(opts)
    M.close(opts.bang, true)
  end, { bang = true })
  for from, to in pairs({ q = "Q", quit = "Q", wq = "Wq" }) do
    -- Only rewrite a command typed at the prompt, never arguments or searches.
    vim.cmd(string.format(
      "cnoreabbrev <expr> %s getcmdtype() == ':' && getcmdline() == '%s' && getcmdpos() == %d ? '%s' : '%s'",
      from, from, #from + 1, to, from
    ))
  end
end

return M
