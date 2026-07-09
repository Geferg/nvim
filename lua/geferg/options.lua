vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
vim.opt.colorcolumn = "80"

-- Indentation
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Files
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- Completion behavior
opt.completeopt = { "menu", "menuone", "noselect" }

-- System clipboard
opt.clipboard = "unnamedplus"

-- Better command-line completion
opt.wildmode = "longest:full,full"

-- Keep diagnostics/signs stable in the gutter
opt.signcolumn = "yes"
