require("conform").setup({
  -- Map of filetype to formatters
  formatters_by_ft = {
    lua = { "stylua" },
    cpp = { "clang-format" },
    -- Conform will run multiple formatters sequentially
    go = { "goimports", "gofmt" },
    -- You can also customize some of the format options for the filetype
    rust = { "rustfmt", lsp_format = "fallback" },
    sh = { "shfmt" },
    --bash = { "shfmt" },
    -- You can use a function here to determine the formatters dynamically
    python = function(bufnr)
      if require("conform").get_formatter_info("ruff_format", bufnr).available then
        return { "ruff_format" }
      else
        return { "isort", "black" }
      end
    end,
    -- Use the "*" filetype to run formatters on all filetypes.
    ["*"] = { "codespell" },
    -- Use the "_" filetype to run formatters on filetypes that don't
    -- have other formatters configured.
    ["_"] = { "trim_whitespace" },
  },
  formatters = {
    shfmt = {
      -- -i 2: indent with 2 spaces (default is tab)
      -- -ci: switch case statement indentation
      -- -bn: binary operators at the start of the next line
      prepend_args = { "-i", "2", "-ci", "-bn" },
    },
  },
  -- Set this to change the default values when calling conform.format()
  default_format_opts = {
    lsp_format = "fallback",
    timeout_ms = 5000,
  },
  -- init.lua owns format-on-save and restricts it to workspace_paths.
  -- Loading Conform for manual formatting must not enable global save hooks.
  -- Set the log level. Use `:ConformInfo` to see the location of the log file.
  log_level = vim.log.levels.ERROR,
  -- Conform will notify you when a formatter errors
  notify_on_error = true,
  -- Conform will notify you when no formatters are available for the buffer
  notify_no_formatters = true,
})
