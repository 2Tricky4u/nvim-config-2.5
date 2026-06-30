local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format", "black", stop_after_first = true },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    sh = { "shfmt" },
    c = { "clang_format" },
    cpp = { "clang_format" },
    rust = { "rustfmt" },
    toml = { "taplo" },
  },

  -- format_on_save = {
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
