local opts = {
  auto_toggle = true,
  winbar = {
    --sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "disassembly", "repl" },
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "disassembly", "repl", "console" },
    --default_section = "disassembly",
    default_section = "console",
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
    size = 0.5,
    position = "left",
    terminal = {
      size = 0.3,
      position = "right",
      -- List of debug adapters for which the terminal should be ALWAYS hidden
      --hide = {},
      hide = true,
    },
  },
}

return opts
--require("dap-view").setup(opts)
