require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "jj", "<ESC>", { desc = "Escape insert mode" })

map("n", "<leader>dd", "<cmd>w<CR><cmd>term python3 %<CR>", { desc = "Run Python file" })
map("n", "<leader>k", "<cmd>bd!<CR>", { desc = "Force close buffer" })

-- Copilot (disable Tab so cmp can use it)
vim.g.copilot_no_tab_map = true
map("n", "<leader>ce", "<cmd>Copilot enable<CR>", { desc = "Enable Copilot" })
map("n", "<leader>cd", "<cmd>Copilot disable<CR>", { desc = "Disable Copilot" })
map("i", "<S-Tab>", 'copilot#Accept("")', { expr = true, replace_keycodes = false, desc = "Accept Copilot suggestion" })
map("i", "<C-n>", "copilot#Next()", { expr = true, desc = "Next Copilot suggestion" })
