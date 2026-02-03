require "nvchad.mappings"

-- add yours here

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
--map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
--
-- Key mapping
-- Navigate vim panes better
map('n', '<C-k>', ':wincmd k<CR>')
map('n', '<C-j>', ':wincmd j<CR>')
map('n', '<C-h>', ':wincmd h<CR>')
map('n', '<C-l>', ':wincmd l<CR>')

-- Fn keys
map("n", "<F3>", '<cmd>:lua ReduceLSPDiag()<CR>')
map("i", "<F3>", '<ESC><cmd>:lua ReduceLSPDiag()<CR>a')

map("n", "<F4>", ':Outline<CR>')
map("i", "<F4>", '<ESC>:Outline<CR>')

map("n", "<F5>", '<cmd>:lua RunDebug()<CR>')
map("i", "<F5>", '<ESC>:w!<CR><cmd>:lua RunDebug()<CR>')
map("n", "<F7>", ':DapStepOver<CR>')
if not vim.g.neovide then
  map("n", "<F35>", ':DapStepInto<CR>')
  map("n", "<F23>", ':DapStepOut<CR>')
  map("n", "<F17>", ':DapTerminate<CR>')
  if vim.loop.os_uname().sysname ~= 'Darwin' then
    map("n", "<F41>", '<cmd>:lua require("dap").restart()<CR>')
  end
else
  map("n", "<C-F11>", ':DapStepInto<CR>')
  map("n", "<S-F11>", ':DapStepOut<CR>')
  map("n", "<S-F5>", ':DapTerminate<CR>')
  if vim.loop.os_uname().sysname == 'Darwin' then
    map("n", "<D-S-F5>", '<cmd>:lua require("dap").restart()<CR>')
  else
    map("n", "<C-S-F5>", '<cmd>:lua require("dap").restart()<CR>')
  end
end
map("n", "<F9>", ':DapToggleBreakpoint<CR>')
map("i", "<F9>", '<ESC>:DapToggleBreakpoint<CR>')

map('n', '<F10>', ':w!<CR>')
map('i', '<F10>', '<ESC>:w!<CR>')

map('n', '<F12>', ':qall<CR>')
map('i', '<F12>', '<ESC>:qall<CR>')

-- MacOS Start
if vim.loop.os_uname().sysname == 'Darwin' then
  map('v', "<M-c>", '"*y', { desc = "Copy" })      -- It's for MacOS
  map('v', "<D-c>", '"*y', { desc = "Copy" })      -- It's for MacOS
end
-- MacOS End

if vim.g.neovide then
  -- Scroll reverse for MacBook only [Start]
  --map({'n', 'i'}, '<ScrollWheelDown>', '<ScrollWheelDown>')
  --map({'n', 'i'}, '<ScrollWheelUp>', '<ScrollWheelUp>')
  -- Scroll reverse for MacBook only [End]
  map({'n', 'i', 'c'}, "<D-v>", "<C-r>+", { desc = "Paste" }) -- CMD-V in MacOS
  map({'n', 'i', 'c'}, "<C-v>", "<C-r>+", { desc = "Paste" }) -- Ctrl-V
  if vim.loop.os_uname().sysname == 'Darwin' then
    map({'n', 'v'}, "<D-s>", "<cmd>w<CR>", { desc = "Save file" })
    map({'i'}, "<D-s>", "<ESC>:w<CR>", { desc = "Save file" })
  end
end
-- Key mapping END

--[[
vim.keymap.set({ 'n' }, '<C-k>', function()       require('lsp_signature').toggle_float_win()
end, { silent = true, noremap = true, desc = 'toggle signature' })

vim.keymap.set({ 'n' }, '<Leader>k', function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = 'toggle signature' })
]]

LspDiagReducedChanged = 1

function ReduceLSPDiag()
  -- Configure LSP diagnostic level
  LspDiagReducedChanged = 1
  if LspDiagReduced == 1 then
    LspDiagReduced = 0
    vim.diagnostic.config({
      virtual_text = {severity = {min = vim.diagnostic.severity.HINT}},
      signs = {severity = {min = vim.diagnostic.severity.HINT}},
      underline = {severity = {min = vim.diagnostic.severity.HINT}},
    })
  else
    LspDiagReduced = 1
    vim.diagnostic.config({
      virtual_text = {severity = {min = vim.diagnostic.severity.ERROR}},
      signs = {severity = {min = vim.diagnostic.severity.ERROR}},
      underline = {severity = {min = vim.diagnostic.severity.ERROR}},
    })
  end
end

function RunDebugPython()
  local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
  require("dap-python").setup(path)
  require('dap-python').test_method()
  --require('dap-python').debug_selection()
  --require('dap-python').test_class()
end

function RunDebug()
  local dap_session = require("dap").session() ~= nil
  if vim.bo.filetype == 'rust' then
    --vim.cmd.RustLsp('debug')
    --vim.cmd.RustLsp('debuggables')
    if not dap_session then
      vim.cmd('!cargo build -j8')
    end
    vim.cmd('DapContinue')
  elseif vim.bo.filetype == 'cpp' or vim.bo.filetype == 'c' then
    if not dap_session then
      vim.cmd('!cmake --build target/debug -j8')
    end
    vim.cmd('DapContinue')
  elseif vim.bo.filetype == 'python' then
    RunDebugPython()
  else
    vim.cmd('DapContinue')
  end
end

--[[
function Run()
  --if vim.bo.filetype == 'rust' then
    --vim.cmd.RustLsp('run')
    --vim.cmd.RustLsp('runnables')
    --vim.cmd('!cargo run')
  --else
  --if vim.bo.filetype == 'cpp' or vim.bo.filetype == 'c' then
  --  vim.cmd('!cd target/debug ; make -j4 ; ./run.sh')
  --else
  if vim.bo.filetype == 'python' then
    vim.cmd('!python3 %')
  elseif vim.bo.filetype == 'go' then
    vim.cmd('!go run %')
  end
end
]]

autocmd('BufEnter', {
  callback = function()
  end
})


local toggle_modes = {'n', 't'}
local mappings = {
  -- General
  --{ 'v', "<M-c>", '"*y', "Copy"},      -- It's for MacOS
  --{ 'v', "<D-c>", '"*y', "Copy"},      -- It's for MacOS
  --{ 'i', "<D-v>", "<C-r>+", "Paste" }, -- It's for MacOS
  { 'v', "<C-c>", '"*y', "Copy"},
  { 'i', "<C-v>", "<C-r>+", "Paste" },
  -- save
  {{ 'n', 'v' }, "<C-s>", "<cmd> w <CR>", "Save file" },
  { 'i', "<C-s>", "<ESC>:w <CR>", "Save file" },

  { 'n', "<C-c>", '"*y', "Copy" },
  --{ 'n', "<C-F11>", function() vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen end, "Toggle Fullscreen" },
  { 'n', "<D-Enter>", function() vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen end, "Toggle Fullscreen" },
  { 'n', "<leader>fg", "<cmd> lua require'telescope.builtin'.live_grep({default_text = vim.fn.expand(\"<cword>\")})<CR>", "Live grep with cword" },
  { 'n', "<Leader>cf", "<cmd> echo expand('%:p') <CR>", "Current File Path" },
  -- close buffer + hide terminal buffer
  { 'n', "<C-w>", function() require("nvchad.tabufline").close_buffer() end, "Close buffer" },
  { 'n', "<C-x>", ':q<CR>', "Close Window" },
  { 'n', "<Leader>i", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, "Toggle Inlay Hints" },

  -- Crates
  { 'n', "<Leader>rcu", function() require('crates').upgrade_all_crates() end, "Update crates" },

  -- Term
  { toggle_modes, "<F2>", function() require("nvchad.term").toggle { pos = "sp", id = "bottom term" } end, "Toggle Terminal" },

  -- NvimTree
  { 'n', "<Leader>fe", "<cmd> NvimTreeToggle <CR>", "NvimTreeToggle" },

  -- DAP
  { 'n', "<Leader>dt", "<cmd> DapToggleBreakpoint <CR>", "Add breakpoint at line" },
  { 'n', "<Leader>dr", "<cmd> DapContinue <CR>", "Start or continue the debugger" },
  { 'n', "<Leader>dx", "<cmd> DapTerminate <CR>", "Terminate the debugger" },
  { 'n', "<Leader>do", "<cmd> DapStepOver <CR>", "Step Over" },
  { 'n', "<Leader>di", "<cmd> DapStepInto <CR>", "Step Into" },
  { 'n', "<Leader>du", "<cmd> DapStepOut <CR>", "Step Out" },

  -- DAP python
  { 'n', "<Leader>dpr", function() require('dap-python').test_method() end, "DAP Python" },
}

for _, mapping in ipairs(mappings) do
  local opts = { noremap = true, silent = true, desc = mapping[4] }
  map(mapping[1], mapping[2], mapping[3], opts)
end


--[[
local M = {}

M.crates = {
  plugin = true,

  n = {
    ["<Leader>rcu"] = {
      function ()
        require('crates').upgrade_all_crates()
      end,
      "Update crates"
    }
  }
}

M.dap = {
  plugin = true,
  n = {
    ["<Leader>dt"] = {
      "<cmd> DapToggleBreakpoint <CR>",
      "Add breakpoint at line",
    },
    ["<Leader>dr"] = {
      "<cmd> DapContinue <CR>",
      "Start or continue the debugger",
    },
    ["<Leader>dx"] = {
      "<cmd> DapTerminate <CR>",
      "Terminate the debugger",
    },
    ["<Leader>do"] = {
      "<cmd> DapStepOver <CR>",
      "Step Over",
    },
    ["<Leader>di"] = {
      "<cmd> DapStepInto <CR>",
      "Step Into",
    },
    ["<Leader>du"] = {
      "<cmd> DapStepOut <CR>",
      "Step Out",
    },
  }
}

M.dap_python = {
  plugin = true,
  n = {
    ["<Leader>dpr"] = {
      function()
        require('dap-python').test_method()
      end
    }
  }
}

M.general = {
  v = {
    ["<M-c>"] = { '"*y', "Copy" }, -- It's for MacOS
    ["<C-c>"] = { '"*y', "Copy" },
  },
  i = {
    ["<C-v>"] = { "<C-r>+", "Paste" },
    -- save
    ["<C-s>"] = { "<ESC>:w <CR>", "Save file" },
  },
  n = {
    ["<C-c>"] = { '"*y', "Copy" },
    ["<C-F11>"] = {
      function()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
      end,
      "Toggle Fullscreen"
    },
    ["<leader>fg"] = { "<cmd> lua require'telescope.builtin'.live_grep({default_text = vim.fn.expand(\"<cword>\")})<CR>", "Live grep with cword" },
    ["<Leader>cf"] = {
      "<cmd> echo expand('%:p') <CR>",
      "Current File Path",
    },
    -- close buffer + hide terminal buffer
    ["<C-w>"] = {
      function()
        require("nvchad.tabufline").close_buffer()
      end,
      "Close buffer",
    },
    ["<C-x>"] = { ':q<CR>', "Close Window" },
    ["<Leader>i"] = {
      function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end,
      "Toggle Inlay Hints",
    },
  },
}

M.nvimtree = {
  n = {
    ["<Leader>fe"] = {
      "<cmd> NvimTreeToggle <CR>",
      "NvimTreeToggle",
    },
  },
}

return M
]]
