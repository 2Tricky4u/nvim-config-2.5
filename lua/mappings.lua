require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "jj", "<ESC>", { desc = "Escape insert mode" })

map("n", "<leader>dd", "<cmd>w<CR><cmd>term python3 %<CR>", { desc = "Run Python file" })
map("n", "<leader>k", "<cmd>bd!<CR>", { desc = "Force close buffer" })

-- One-key window navigation (also switches between dap-ui panels).
-- NB: this takes <C-l> over from its default (clear search highlight); use :noh instead.
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Copilot (disable Tab so cmp can use it)
vim.g.copilot_no_tab_map = true
map("n", "<leader>ce", "<cmd>Copilot enable<CR>", { desc = "Enable Copilot" })
map("n", "<leader>cd", "<cmd>Copilot disable<CR>", { desc = "Disable Copilot" })
map("i", "<S-Tab>", 'copilot#Accept("")', { expr = true, replace_keycodes = false, desc = "Accept Copilot suggestion" })
map("i", "<C-n>", "copilot#Next()", { expr = true, desc = "Next Copilot suggestion" })

-- ── Terminals ───────────────────────────────────────────────────────────
-- NvChad's toggleable terminals default to <A-h>/<A-v>/<A-i>, but Hyprland
-- owns ALT ($mod = ALT in ~/.config/hypr/binds.conf -- Alt+H resizeactive,
-- Alt+I addmaster), so those keys never reach Neovim. Drop them and rebind.
for _, lhs in ipairs { "<A-h>", "<A-v>", "<A-i>" } do
  for _, mode in ipairs { "n", "t" } do
    pcall(vim.keymap.del, mode, lhs)
  end
end

-- Remember how wide/tall you last dragged each toggleable terminal. NvChad
-- re-applies nvconfig's fixed `sizes` on every display(), so without this a
-- manual <C-w>> resize is thrown away the next time you toggle.
local term_size = {}

local function toggle_term(pos, id, default_size)
  return function()
    local term
    for _, opts in pairs(vim.g.nvchad_terms or {}) do
      if opts.id == id then
        term = opts
      end
    end

    local win = -1
    if term and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
      win = vim.fn.bufwinid(term.buf)
    end

    -- Visible means this keypress hides it, so capture the size on the way out.
    if win ~= -1 and pos ~= "float" then
      term_size[id] = pos == "vsp" and vim.api.nvim_win_get_width(win) / vim.o.columns
        or vim.api.nvim_win_get_height(win) / vim.o.lines
    end

    require("nvchad.term").toggle {
      pos = pos,
      id = id,
      size = pos ~= "float" and (term_size[id] or default_size) or nil,
    }
  end
end

-- <leader> is Space, which cannot prefix anything in terminal mode (it has to
-- type a literal space into the shell), so the always-available toggle needs a
-- Ctrl chord. <C-@> is the same keycode on terminals that don't transmit
-- <C-Space> distinctly; Kitty does, but this costs nothing and covers the rest.
map({ "n", "t" }, "<C-Space>", toggle_term("float", "floatTerm"), { desc = "Terminal: toggle floating" })
map({ "n", "t" }, "<C-@>", toggle_term("float", "floatTerm"), { desc = "Terminal: toggle floating" })

-- Split terminals are normal-mode only -- press <C-x> first if you are inside
-- one. NB: <leader>th is taken by NvChad's theme picker, hence ts/tv.
map("n", "<leader>ts", toggle_term("sp", "htoggleTerm", 0.3), { desc = "Terminal: toggle horizontal" })
map("n", "<leader>tv", toggle_term("vsp", "vtoggleTerm", 0.35), { desc = "Terminal: toggle vertical" })

-- ── LSP symbol search / call hierarchy ──────────────────────────────────
-- Cursor-free counterparts to the glance peeks in plugins/init.lua: find a
-- symbol by typing its name, or walk who-calls-what. Telescope is lazy-loaded,
-- so <cmd>Telescope ...<CR> pulls it in on first use.
--
-- lsp_dynamic_workspace_symbols re-queries clangd on every keystroke, unlike
-- lsp_workspace_symbols which fetches once and then only filters locally.
map("n", "<leader>ls", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "LSP: symbols by name (project)" })
map("n", "<leader>lS", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "LSP: symbols by name (file)" })

-- Call hierarchy: nothing in NvChad or Neovim's defaults binds these, and for
-- embedded C they answer the question references cannot -- which task or ISR
-- actually reaches this function.
map("n", "<leader>lc", "<cmd>Telescope lsp_incoming_calls<CR>", { desc = "LSP: incoming calls (callers)" })
map("n", "<leader>lC", "<cmd>Telescope lsp_outgoing_calls<CR>", { desc = "LSP: outgoing calls (callees)" })
