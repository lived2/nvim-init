local M = {}

local saved = {
  virtual_text = true,
  signs = true,
  underline = true,
}

function M.hide()
  local current = vim.diagnostic.config()
  if current == nil then return end

  -- Preserve the saved settings when already hidden.
  if current.virtual_text == false
    and current.signs == false
    and current.underline == false
  then
    return
  end

  for key in pairs(saved) do
    saved[key] = vim.deepcopy(current[key])
  end

  vim.diagnostic.config({
    virtual_text = false,
    signs = false,
    underline = false,
  })
end

function M.show()
  vim.diagnostic.config(vim.deepcopy(saved))
end

function M.toggle()
  print('toggle')
  local current = vim.diagnostic.config()
  if current == nil then return end

  if current.virtual_text == false
    and current.signs == false
    and current.underline == false
  then
    M.show()
  else
    M.hide()
  end
end

return M
