require('hlslens').setup({
  auto_enable = true,
  enable_incsearch = false,
  override_lens = function(render, posList, nearest, idx, _)
    local indicator, text, chunks
    indicator = '▶'

    local lnum, col = unpack(posList[idx])
    local cnt = #posList
    if nearest then
      if indicator ~= '' then
        text = ('[%s %d/%d]'):format(indicator, idx, cnt)
      else
        text = ('[%d/%d]'):format(idx, cnt)
      end
      chunks = {{' '}, {text, 'HlSearchLensNear'}}
    else
      text = ('[%d/%d]'):format(idx, cnt)
      chunks = {{' '}, {text, 'HlSearchLens'}}
    end
    render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
  end
})

local kopts = {noremap = true, silent = true}

vim.api.nvim_set_keymap('n', 'n',
    [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', 'N',
    [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

vim.api.nvim_set_keymap('n', '<Leader>l', '<Cmd>noh<CR>', kopts)
