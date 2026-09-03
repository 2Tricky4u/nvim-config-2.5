return {
  -- Disable which-key's register popup on " so nvim-surround can receive it as a delimiter
  {
    "folke/which-key.nvim",
    opts = {
      plugins = { registers = false },
      spec = {
        { "<leader>l", group = "lsp" },
      },
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
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPost",
    opts = { user_default_options = { names = false, rgb_fn = true, hsl_fn = true, RRGGBBAA = true } },
  },

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

  -- ── LSP peek / preview ─────────────────────────────────────────────────
  -- `gd` still jumps away; these peek instead. Results list on the right,
  -- live preview on the left, <Esc> backs out without moving the cursor.
  -- Fills the gap the built-ins leave: `grr`/`gri` only dump to the quickfix
  -- list, and Telescope auto-jumps whenever there is exactly one result.
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    keys = {
      { "<leader>ld", "<cmd>Glance definitions<CR>", desc = "Glance: definitions" },
      { "<leader>lr", "<cmd>Glance references<CR>", desc = "Glance: references" },
      { "<leader>li", "<cmd>Glance implementations<CR>", desc = "Glance: implementations" },
      { "<leader>lt", "<cmd>Glance type_definitions<CR>", desc = "Glance: type definitions" },
      { "<leader>ll", "<cmd>Glance resume<CR>", desc = "Glance: resume last" },
    },
    opts = function()
      local actions = require("glance").actions
      return {
        -- eldritch is dark, and base46 transparency leaves Normal with no bg
        -- for 'auto' to sample -- so pin the derivation direction explicitly.
        theme = { enable = true, mode = "brighten" },
        -- With transparency on, these rules are the only thing separating the
        -- peek window from the buffer showing through behind it.
        border = { enable = true },
        -- <C-q> hands results to trouble.nvim (already installed) instead of
        -- the plain quickfix list, so it lands next to <leader>xx and friends.
        use_trouble_qf = true,
        -- Start expanded: peeking is meant to be immediate. Set this back to
        -- true to get the collapsed per-file overview on big reference lists.
        folds = { folded = false },
        mappings = {
          list = {
            -- The list sits right, the preview left, so <C-h>/<C-l> keep the
            -- same directional meaning they have everywhere else in mappings.lua.
            ["<C-h>"] = actions.enter_win "preview",
            -- Glance binds <leader>l itself; reclaim it as the LSP prefix.
            ["<leader>l"] = false,
          },
          preview = {
            ["<C-l>"] = actions.enter_win "list",
            ["<leader>l"] = false,
            ["q"] = actions.close,
          },
        },
      }
    end,
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
    event = "VeryLazy", -- load shortly after startup so keymaps + :Svd/:Rtt/:Mem exist
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text", -- inline variable values while stepping
    },
    config = function()
      require "configs.dap"
    end,
  },

  -- ── Rust ───────────────────────────────────────────────────────────────
  -- rustaceanvim owns rust-analyzer — do NOT add rust-analyzer to lspconfig
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
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
              checkOnSave = true,
              check = { command = "clippy" },
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

  -- ── Diagrams in markdown (mermaid/d2/plantuml/gnuplot) ──────────────────
  -- Renders ```mermaid blocks as real inline images via image.nvim (Kitty).
  -- Prereq: sudo pacman -S mermaid-cli   (provides `mmdc`)
  {
    "3rd/diagram.nvim",
    dependencies = { "3rd/image.nvim" },
    ft = { "markdown", "norg" },
    opts = {
      -- Each render spawns mmdc (chromium), ~1s, so don't fire on every keystroke.
      -- Results are cached by content hash, so unchanged diagrams are instant.
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter" },
        clear_buffer = { "BufLeave" },
      },
      renderer_options = {
        mermaid = {
          theme = "dark",
          background = "transparent",
          scale = 3, -- render big, image.nvim scales down -> crisp
        },
      },
    },
    keys = {
      { "<leader>mm", function() require("diagram").show_diagram_hover() end,
        ft = { "markdown", "norg" }, desc = "Diagram: open at cursor in new tab" },
      { "<leader>mr", function() require("diagram").render() end,
        ft = { "markdown", "norg" }, desc = "Diagram: re-render buffer" },
      { "<leader>mc", function() require("diagram").clear() end,
        ft = { "markdown", "norg" }, desc = "Diagram: clear images" },
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
