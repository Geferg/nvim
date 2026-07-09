vim.pack.add({
    { src = "https://github.com/navarasu/onedark.nvim", name = "onedark" },
})

require('onedark').setup({
    style = 'dark'
})

require('onedark').load()
vim.cmd.colorscheme("onedark")
