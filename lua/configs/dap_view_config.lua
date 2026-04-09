local opts = {
  auto_toggle = true,
  winbar = {
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "disassembly", "repl" },
    default_section = "disassembly",
    show_keymap_hints = false,
    -- Add your own sections
    custom_sections = {},
    controls = {
      enabled = true,
      position = "right",
      buttons = {
        "play",
        "step_into",
        "step_over",
        "step_out",
        "step_back",
        "run_last",
        "terminate",
        "disconnect",
      },
      custom_buttons = {},
    }
  },
  windows = {
    size = 0.25,
    position = "below",
    terminal = {
      size = 0.5,
      position = "right",
      -- List of debug adapters for which the terminal should be ALWAYS hidden
      hide = {},
    },
  },
}

return opts
--require("dap-view").setup(opts)
