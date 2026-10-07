-- Popup timeout hides the view without clearing Noice's last msg_show event.
-- Treat each Ex command as a fresh output, even when its text is unchanged.
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = vim.api.nvim_create_augroup("NoiceRepeatedCommandMessages", { clear = true }),
  pattern = ":",
  callback = function()
    local state = package.loaded["noice.ui.state"]
    if state then state.clear("msg_show") end
  end,
})

require("noice").setup({
  notify = {
    enabled = true,
    view = "notification_popup",
  },
  messages = {
    view = "notification_popup",
    view_error = "notification_popup",
    view_warn = "notification_popup",
  },
  views = {
    messages = {
      -- Keep history below the invoking window so closing returns there.
      relative = "win",
      close = {
        keys = { "q", "<Esc>" },
      },
    },
    notification_popup = {
      backend = "popup",
      relative = "editor",
      enter = false,
      focusable = false,

      position = {
        row = 2,
        col = "50%",
      },
      size = {
        --width = 60,
        width = "auto",
        height = "auto",
        --max_width = 80,
        max_height = 10,
      },
      border = {
        style = "rounded",
      },
      win_options = {
        wrap = true,
      },
      timeout = 3000,
    },

    cmdline_popup = {
      position = {
        row = "50%",
        col = "50%",
      },
    },
    split = {
      -- :Noice history/all use split directly, rather than the messages view.
      relative = "win",
      close = {
        keys = { "q", "<Esc>" },
      },
    },
    popup = {
      close = {
        keys = { "q", "<Esc>" },
      },
    },
  },
  lsp = {
    message = {
      view = "notification_popup",
    },
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = false, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
})
