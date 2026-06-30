require("nvchad.configs.lspconfig").defaults()

-- Simple servers with no extra config needed
vim.lsp.enable { "html", "cssls", "pylsp" }

-- lua_ls: teach it about the Neovim runtime and lazy.nvim so `vim.*` is not flagged
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
        },
      },
    },
  },
})
vim.lsp.enable "lua_ls"

-- clangd: C/C++ LSP; set ARM target per-project via a .clangd file at project root
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
  },
})
vim.lsp.enable "clangd"

vim.lsp.enable "cmake"

-- rust-analyzer is NOT enabled here; rustaceanvim manages it exclusively
