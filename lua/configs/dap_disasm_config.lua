require("dap-disasm").setup({
  -- Add disassembly view to elements of nvim-dap-ui
  dapui_register = false,

  -- Add disassembly view to nvim-dap-view
  dapview_register = true,

  -- If registered, pass section configuration to nvim-dap-view
  dapview = {
    keymap = "D",
    label = "Disassembly",
    short_label = "󰒓 [D]",
  },

  -- Show winbar with buttons to step into the code with instruction granularity
  -- This settings is overriden (disabled) if the dapview integration is enabled and the plugin is installed
  winbar = {
    enabled = true,
    labels = {
      step_into = "Step Into",
      step_over = "Step Over",
      step_back = "Step Back",
    },
    order = {
      "step_into", "step_over", "step_back"
    }
  },

  -- The sign to use for instruction the exectution is stopped at
  sign = "DapStopped",

  -- Number of instructions to show before the memory reference
  ins_before_memref = 32,

  -- Number of instructions to show after the memory reference
  ins_after_memref = 32,

  -- Columns to display in the disassembly view
  columns = {
    "address",
    "instructionBytes",
    "instruction",
  },
})
