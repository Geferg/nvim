local map = vim.keymap.set

-- Temp
map("n", "<leader>e", ":Neotree<CR>", { desc = "Explore files" })
map("n", "<leader>w", ":w<CR>:so<CR>", { desc = "Write and shoutout" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move selected lines
map("n", "<A-h>", "<<", { desc = "Move line left" })
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("n", "<A-l>", ">>", { desc = "Move line right" })

map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered for common jumps
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
