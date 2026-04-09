local opts = require("configs.dap_view_config")

opts.winbar.sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" }
opts.winbar.default_section = "repl"

return opts
--require("dap-view").setup(opts)
