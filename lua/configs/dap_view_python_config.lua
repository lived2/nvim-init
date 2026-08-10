local opts = require("configs.dap_view_config")

opts.winbar.sections = { "watches", "scopes", "exceptions", "repl", "sessions", "breakpoints", "threads", "console" }
--opts.winbar.default_section = "repl"
--opts.winbar.default_section = "console"

return opts
--require("dap-view").setup(opts)
