require ('mason-nvim-dap').setup({
  ensure_installed = {'stylua', 'jq'},
  handlers = {
    function(config)
      -- all sources with no handler get passed here

      -- Keep original functionality
      require('mason-nvim-dap').default_setup(config)
    end,
    codelldb = function(config)
      config.configurations = {
        {
          name = 'LLDB: Launch',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},
          console = 'integratedTerminal',
        },
        {
          name = 'LLDB: Launch (args)',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = function()
            return vim.split(vim.fn.input('Args: '), ' +', { trimempty = true })
          end,
          console = 'integratedTerminal',
        },
      }
      require('mason-nvim-dap').default_setup(config) -- don't forget this!
    end,
  },
})
