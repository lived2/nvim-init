require("outline").setup({
  outline_window = {
    keymaps = {
       goto_location = {'<Cr>', 'A'},
    },
  },
})

vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>", { desc = "Toggle Outline" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "Outline",
  callback = function()
    local opts = { buffer = true }

    vim.keymap.set("n", "<LeftMouse>", "<CR>", opts)
    vim.keymap.set("n", "<2-LeftMouse>", "<CR>", opts)
  end,
})
