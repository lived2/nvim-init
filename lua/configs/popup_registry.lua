local M = {}

local menus = {}

function M.register(name)
  menus[name] = true
end

function M.clear()
  for name, _ in pairs(menus) do
    pcall(function()
      vim.cmd("silent! aunmenu PopUp." .. name)
    end)
  end

  menus = {}
end

return M
