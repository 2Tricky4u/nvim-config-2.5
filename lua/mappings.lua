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

local function toggle_term(pos, id)
  return function()
    require("nvchad.term").toggle { pos = pos, id = id }
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
map("n", "<leader>ts", toggle_term("sp", "htoggleTerm"), { desc = "Terminal: toggle horizontal" })
map("n", "<leader>tv", toggle_term("vsp", "vtoggleTerm"), { desc = "Terminal: toggle vertical" })
