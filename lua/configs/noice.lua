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
    cmdline_output = {
      enter = true,
      size = "35%", -- Percentage of the editor height.
    },
    messages = {
      -- Keep history below the invoking window so closing returns there.
      --relative = "win",
      relative = "editor",
      position = "bottom",
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
      --relative = "win",
      relative = "editor",
      position = "bottom",
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
    signature = {
      enabled = false,
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

local NuiView = require("noice.view.nui")

if not NuiView._remember_split_height then
  NuiView._remember_split_height = true
  local heights = {}
  local windows = {}
  local tracked_views = { cmdline_output = true, split = true, messages = true }
  local original_layout = NuiView.get_layout
  local original_show = NuiView.show
  local original_hide = NuiView.hide

  local function remember(win)
    local tracked = windows[win]
    if not tracked then return end
    if not vim.api.nvim_win_is_valid(win) then
      windows[win] = nil
      return
    end
    local height = vim.api.nvim_win_get_height(win)
    if height ~= tracked.height then
      heights[tracked.name] = height
      tracked.height = height
    end
  end

  function NuiView:get_layout()
    local layout = original_layout(self)
    if self._opts.type == "split" and tracked_views[self._opts.view]
      and (layout.position == "bottom" or layout.position == "top")
    then
      local win = self._nui and self._nui.winid
      if win then remember(win) end
      local height = heights[self._opts.view]
      if height then
        -- Keep the saved preference while allowing smaller editor sizes.
        layout.size = math.min(height, math.max(1, vim.o.lines - vim.o.cmdheight - 3))
      end
    end
    return layout
  end

  function NuiView:show()
    original_show(self)
    local win = self._nui and self._nui.winid
    if self._opts.type == "split" and tracked_views[self._opts.view]
      and (self._opts.position == "bottom" or self._opts.position == "top")
      and win and vim.api.nvim_win_is_valid(win)
    then
      -- Establish a baseline so opening a view does not save its default size.
      windows[win] = {
        name = self._opts.view,
        height = vim.api.nvim_win_get_height(win),
      }
    end
  end

  function NuiView:hide()
    local win = self._nui and self._nui.winid
    if win then
      -- Capture a resize even if the window closes before WinResized fires.
      remember(win)
      windows[win] = nil
    end
    return original_hide(self)
  end

  vim.api.nvim_create_autocmd("WinResized", {
    group = vim.api.nvim_create_augroup("NoiceSplitHeight", { clear = true }),
    callback = function()
      for win in pairs(windows) do remember(win) end
    end,
  })
end

if not NuiView._split_return_focus then
  NuiView._split_return_focus = true
  local original_show = NuiView.show

  function NuiView:show()
    local previous_win = self._nui and self._nui.winid
    if self._opts.type == "split"
      and (not previous_win or not vim.api.nvim_win_is_valid(previous_win))
    then
      -- Refresh the origin each time a cached view is opened again.
      self._return_win = vim.api.nvim_get_current_win()
    end

    original_show(self)

    if self._opts.type ~= "split" then return end
    local win = self._nui and self._nui.winid
    if not win or not vim.api.nvim_win_is_valid(win) then return end
    local buf = vim.api.nvim_win_get_buf(win)

    local function close_and_return()
      local return_win = self._return_win
      local was_focused = vim.api.nvim_get_current_win() == win
      self:hide()

      -- Restore focus only when closing the active view successfully.
      if was_focused and not vim.api.nvim_win_is_valid(win)
        and return_win and vim.api.nvim_win_is_valid(return_win)
      then
        vim.api.nvim_set_current_win(return_win)
      end
    end

    for _, key in ipairs({ "q", "<Esc>" }) do
      vim.keymap.set("n", key, close_and_return, {
        buffer = buf,
        silent = true,
        nowait = true,
        desc = "Close Noice and return to the invoking window",
      })
    end

    if self._opts.view == "cmdline_output" or self._opts.view == "split" then
      -- Run after Noice's scheduled initial scroll to the top.
      vim.schedule(function()
        if not vim.api.nvim_win_is_valid(win)
          or vim.api.nvim_win_get_buf(win) ~= buf
        then
          return
        end
        vim.api.nvim_win_call(win, function()
          vim.cmd("noautocmd normal! G$zb")
        end)
        if self._scroll then self._scroll:update() end
      end)
    end
  end
end

if not NuiView._notification_follow_tail then
  NuiView._notification_follow_tail = true
  local original_show = NuiView.show

  function NuiView:show()
    original_show(self)

    -- Follow the latest message only in the notification popup.
    if self._opts.view ~= "notification_popup" then return end

    local win = self._nui and self._nui.winid
    if not win or not vim.api.nvim_win_is_valid(win) then return end

    -- Show the end of the last line, including wrapped text.
    vim.api.nvim_win_call(win, function()
      vim.cmd("noautocmd normal! G$zb")
    end)

    -- Refresh the scrollbar after scrolling.
    if self._scroll then
      self._scroll:update()
    end
  end
end
