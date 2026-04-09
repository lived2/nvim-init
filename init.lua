vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)


-- ---
-- Global
local opt = vim.opt
opt.clipboard = ""
opt.wrapscan = false
opt.scrolloff = 10
opt.expandtab = true
opt.cinoptions = "l1,g0,:0,N-s"

if vim.g.neovide then
  opt.clipboard = "unnamedplus"
end

-- ---
-- Customizing flags
--[[
IsTerm = 0
local term = os.getenv("TERM")
if term ~= nil then
  IsTerm = 1
end
]]

IsMac = 0
IsWin = 0
local os = vim.loop.os_uname().sysname
if os == 'Darwin' then
  IsMac = 1
elseif os == "Windows_NT" then
  IsWin = 1
end

--[[
local jit = require("jit")
ARCH = jit.arch
]]

IsWork = 0
local hostname = vim.fn.hostname()
local work_hostnames = {
  "passat",
}

for _, work_hostname in ipairs(work_hostnames) do
  if hostname == work_hostname then
    IsWork = 1
  end
end
IsWorkSource = 0

-- ---
-- When editing a file, always jump to the last known cursor position.
-- Don't do it when the position is invalid, when inside an event handler
-- (happens when dropping a file on gvim) and for a commit message (it's
-- likely a different one than last time).
local autocmd = vim.api.nvim_create_autocmd
--local map = vim.keymap.set

-- adapted from https://github.com/ethanholz/nvim-lastplace/blob/main/lua/nvim-lastplace/init.lua
local ignore_buftype = { "quickfix", "nofile", "help" }
local ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" }

local function run()
  vim.opt_local.formatoptions:remove({ 'r', 'o' })
  if vim.tbl_contains(ignore_buftype, vim.bo.buftype) then
    return
  end

  if vim.tbl_contains(ignore_filetype, vim.bo.filetype) then
    -- reset cursor to first line
    vim.cmd[[normal! gg]]
    return
  end

  -- If a line has already been specified on the command line, we are done
  --   nvim file +num
  --[[
  if vim.fn.line(".") > 1 then
    return
  end
  ]]

  local last_line = vim.fn.line([['"]])
  local buff_last_line = vim.fn.line("$")

  -- If the last line is set and the less than the last line in the buffer
  if last_line > 0 and last_line <= buff_last_line then
    local win_last_line = vim.fn.line("w$")
    local win_first_line = vim.fn.line("w0")
    -- Check if the last line of the buffer is the same as the win
    if win_last_line == buff_last_line then
      -- Set line to last line edited
      vim.cmd[[normal! g`"]]
      -- Try to center
    elseif buff_last_line - last_line > ((win_last_line - win_first_line) / 2) - 1 then
      vim.cmd[[normal! g`"zz]]
    else
      vim.cmd[[normal! G'"<c-e>]]
    end
  end
end

autocmd({'BufWinEnter', 'FileType'}, {
  group    = vim.api.nvim_create_augroup('nvim-lastplace', {}),
  callback = run
})

autocmd('BufEnter', {
  callback = function()
    local ft = vim.bo.filetype
    --if ft == "rust" or ft == "cpp" then
    if ft == "rust" then
      opt.shiftwidth = 4
      opt.tabstop = 4
      opt.softtabstop = 4
    else
      opt.shiftwidth = 2
      opt.tabstop = 2
      opt.softtabstop = 2
    end

    local extension = vim.fn.expand('%:e')
    if ft == "text" or extension == "log" or extension == "dump" or extension == "lst" then
      require('cmp').setup.buffer { enabled = false }
    end
    -- Change tab size for specific path
    --[[
    local path = vim.fn.getcwd()
    if string.find(path, "qcom") then
      opt.shiftwidth = 2
      opt.tabstop = 2
      opt.softtabstop = 2
    end
    --]]
    if ft == "python" then
      local opts = require "configs.dap_view_python_config"
      require("dap-view").setup(opts)
    elseif ft == "go" then
      local opts = require "configs.dap_view_go_config"
      require("dap-view").setup(opts)
    end
    print(vim.fn.expand('%:p'))
  end
})

function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

local workspace_paths = {
  "/Users/lived/project/",
  "/home/lived/project",
  "/usr2/seonggoo/build/project/",
}

local ctags_paths = {
  "/vendor/qcom/opensource/",
  "/boot/QcomPkg/",
}

if IsWork == 1 then
  autocmd("BufReadPre", {
    pattern = "*",
    callback = function()
      --local cur_path = vim.fn.getcwd()
      local cur_path = vim.fn.expand('%:p')
      if string.starts(cur_path, "/usr2/seonggoo/build/") and not string.starts(cur_path, "/usr2/seonggoo/build/project/") then
        IsWorkSource = 1
        for _, path in ipairs(ctags_paths) do
          local start_pos, end_pos = string.find(cur_path, path, 1, true)
          if start_pos ~= nil then
            local cur_proj = cur_path:sub(1, end_pos)
            local cmd = "set tags+=" .. cur_proj .. "tags"
            vim.cmd(cmd)
          end
        end
      end
    end,
  })
end

autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    local cur_path = vim.fn.getcwd()
    for _, path in ipairs(workspace_paths) do
      if string.starts(cur_path, path) then
        require("conform").format { bufnr = args.buf }
        do return end
      end
    end
  end,
})

--[[
autocmd('BufReadPost', {
  callback = function()
    print(vim.fn.expand('%:p'))
  end,
})
]]

-- DAP View position
autocmd("FileType", {
  pattern = "dap-view",
  callback = function()
    vim.cmd("wincmd H")
    vim.cmd("vertical resize 100")
  end,
})

local function setup_dap()
  local ok, base46 = pcall(require, "base46")
  if not ok then return end
  local C = base46.get_theme_tb("base_30")

  local sign = vim.fn.sign_define
  local set_hl = vim.api.nvim_set_hl

  -- DAP
  -- Breakpoints
  --[[
  sign("DapBreakpoint", {
    text = "",
    texthl = "DapBreakpoint",
    linehl = "DapBreakpointLine",
    numhl = "",
  })
  ]]
  sign('DapBreakpoint', {
    text='🛑',
    texthl='DapBreakpoint',
    linehl='DapBreakpointLine',
    numhl='DapBreakpoint'
  })

  set_hl(0, "DapBreakpoint", { fg = C.red })
  set_hl(0, "DapBreakpointLine", {
    bg = C.light_grey
  })

  sign('DapBreakpointRejected', {
    text='',
    texthl='DapBreakpoint',
    linehl='DapBreakpoint',
    numhl= 'DapBreakpoint'
  })

  -- Stopped
  sign("DapStopped", {
    text = "",
    texthl = "DapStopped",
    linehl = "DapStoppedLine",
    numhl = "DapStoppedLineNr",
  })

  set_hl(0, "DapStopped", { fg = C.green, bold = true })
  set_hl(0, "DapStoppedLine", { bg = C.grey })
  set_hl(0, "DapStoppedLineNr", { fg = C.green, bold = true })

  -- DAP View
  -- ✅ SELECTED tab (REPL, Watches, etc.)
  set_hl(0, "NvimDapViewTabSelected", {
    fg = C.green,
    bg = C.base,
    bold = true,
  })

  -- Inactive tabs
  set_hl(0, "NvimDapViewTab", {
    fg = C.text,
    --fg = C.overlay1,
    bg = "NONE",
  })

  -- Tab background filler
  set_hl(0, "NvimDapViewTabFill", {
    fg = C.base,
    bg = C.base,
  })
end

--vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    vim.schedule(setup_dap)
  end,
})


local function open_nvim_tree(data)
  -- buffer is a directory
  local directory = vim.fn.isdirectory(data.file) == 1

  -- buffer is a [No Name]
  --local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

  --if not directory and not no_name then
  if not directory then
    return
  end
  if vim.g.neovide then
    return
  end

  if directory then
    -- change to the directory
    vim.cmd.cd(data.file)
  end

  -- open the tree
  require("nvim-tree.api").tree.open()
end
autocmd('VimEnter', { callback = open_nvim_tree })

if vim.g.neovide then
  -- Put anything you want to happen only in Neovide here
  if IsWin == 1 then
    local width = 0
    local handle = io.popen("wmic path Win32_VideoController get CurrentHorizontalResolution")
    if handle ~= nil then
      width = handle:read()
      width = handle:read("*n")
      handle:close()
    end

    if width == 1920 then
      vim.o.guifont = "JetBrainsMono Nerd Font:h10"
    elseif width == 2560 then
      vim.o.guifont = "JetBrainsMono Nerd Font:h11"
    else
      vim.o.guifont = "JetBrainsMono Nerd Font:h11"
    end
    vim.o.linespace = -2
  else
    vim.o.guifont = "JetBrainsMono Nerd Font:h13"
  end
  -- Additional neovide
  -- End of neovide
else
  vim.o.guifont = "JetBrainsMono Nerd Font:h13"
end
