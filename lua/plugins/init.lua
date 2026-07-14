return {
  -- Disable which-key's register popup on " so nvim-surround can receive it as a delimiter
  {
    "folke/which-key.nvim",
    opts = {
      plugins = { registers = false },
    },
  },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Surround motions (ys/cs/ds, Lua-native with dot-repeat)
  { "kylechui/nvim-surround", event = "BufReadPost", opts = {} },

  -- Highlight word under cursor across buffer
  { "RRethy/vim-illuminate", event = "BufReadPost" },

  -- CSS color preview (#fff, rgb(), etc.)
  { "ap/vim-css-color", event = "BufReadPost" },

  -- Smooth <C-d>/<C-u> scrolling
  { "terryma/vim-smooth-scroll", event = "BufReadPost" },

  -- Inline git blame annotations
  { "f-person/git-blame.nvim", event = "BufReadPost" },

  -- Crystal language support
  { "vim-crystal/vim-crystal", ft = "crystal" },

  -- GitHub Copilot (lazy-loaded on first insert)
  { "github/copilot.vim", event = "InsertEnter" },

  -- Treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "python",
        "c", "cpp", "cmake",
        "rust", "toml",
        "markdown", "markdown_inline",
      },
    },
  },

  -- Mason: auto-install LSP servers and tools
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server", "python-lsp-server",
        "clangd", "clang-format",
        -- cmake-language-server: installed via pipx (not in Arch repos)
        -- luacheck: installed via pacman (luarocks fails on Arch)
        "cpptools",      -- DAP: C/C++ via OpenOCD/GDB (STM32)
        "codelldb",      -- DAP: Rust + native C/C++
        "rust-analyzer",
        "taplo",         -- TOML formatter
      },
    },
  },

  -- ── Linting ────────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-lint",
    event = "BufReadPost",
    config = function()
      require "configs.lint"
    end,
  },

  -- ── File management ────────────────────────────────────────────────────
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = false,
      view_options = { show_hidden = true },
    },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Oil: open parent dir" },
    },
  },

  -- ── Extended text objects ──────────────────────────────────────────────
  {
    "echasnovski/mini.ai",
    event = "BufReadPost",
    opts = {},
  },

  -- ── Navigation ─────────────────────────────────────────────────────────
  -- s = jump (n/x only — keep o free so nvim-surround ys/cs/ds work)
  -- S (n/o only) = treesitter; visual S left for nvim-surround
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x" }, function() require("flash").jump() end, desc = "Flash: jump" },
      { "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash: treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash: remote" },
    },
  },

  -- ── Diagnostics ────────────────────────────────────────────────────────
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Trouble: workspace diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Trouble: buffer diagnostics" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Trouble: location list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Trouble: quickfix" },
    },
  },

  -- ── Git ────────────────────────────────────────────────────────────────
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
    opts = {},
  },

  -- ── Debugging ──────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require "configs.dap"
    end,
  },

  -- ── Rust ───────────────────────────────────────────────────────────────
  -- rustaceanvim owns rust-analyzer — do NOT add rust-analyzer to lspconfig
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = "rust",
    opts = function()
      local codelldb = vim.fn.stdpath "data" .. "/mason/bin/codelldb"
      return {
        server = {
          on_attach = function(_, bufnr)
            local map = vim.keymap.set
            map("n", "<leader>ra", function() vim.cmd.RustLsp "codeAction" end,
              { buffer = bufnr, desc = "Rust: code action" })
            map("n", "K", function() vim.cmd.RustLsp { "hover", "actions" } end,
              { buffer = bufnr, desc = "Rust: hover" })
            map("n", "<leader>rr", function() vim.cmd.RustLsp "runnables" end,
              { buffer = bufnr, desc = "Rust: runnables" })
            map("n", "<leader>rd", function() vim.cmd.RustLsp "debuggables" end,
              { buffer = bufnr, desc = "Rust: debuggables" })
          end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              checkOnSave = { command = "clippy" },
              inlayHints = { lifetimeElisionHints = { enable = "always" } },
            },
          },
        },
        dap = {
          adapter = {
            type = "server",
            port = "${port}",
            host = "127.0.0.1",
            executable = {
              command = codelldb,
              args = { "--port", "${port}" },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      vim.g.rustaceanvim = opts
    end,
  },

  -- Cargo.toml: inline crate versions, upgrade hints, docs
  {
    "saecki/crates.nvim",
    ft = "toml",
    opts = {},
  },

  -- ── Build / task runner ────────────────────────────────────────────────
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerBuild" },
    opts = {},
    keys = {
      { "<leader>or", "<cmd>OverseerRun<CR>",    desc = "Overseer: run task" },
      { "<leader>ot", "<cmd>OverseerToggle<CR>", desc = "Overseer: toggle panel" },
    },
  },

  -- CMake project integration (auto-generates compile_commands.json, build, flash)
  {
    "Civitasv/cmake-tools.nvim",
    ft = { "cmake", "c", "cpp" },
    dependencies = { "stevearc/overseer.nvim" },
    opts = {
      cmake_build_directory = "build",
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
    },
  },

  -- ── Image viewer (Kitty backend) ────────────────────────────────────────
  -- Prereq: sudo pacman -S imagemagick
  {
    "3rd/image.nvim",
    event = "BufReadPost",
    opts = {
      backend = "kitty",
      processor = "magick_cli", -- ImageMagick CLI; avoids the magick luarock (broken on Arch)
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
        },
      },
      max_width_window_percentage = 70,
      max_height_window_percentage = 50,
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
  },

  -- ── Markdown renderer ───────────────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      heading = { enabled = true },
      code = { enabled = true, style = "full" },
      pipe_table = { enabled = true },
      checkbox = { enabled = true },
    },
  },
}
