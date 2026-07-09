vim.pack.add({
    {
        src = "https://github.com/lewis6991/gitsigns.nvim",
        name = "gitsigns.nvim",
    },
})

require("gitsigns").setup()
