vim.pack.add({
    {
        src = "https://github.com/mason-org/mason.nvim",
        name = "mason.nvim",
    },
    {
        src = "https://github.com/mason-org/mason-lspconfig.nvim",
        name = "mason-lspconfig.nvim",
    },
})

require("mason").setup()

require("mason-lspconfig").setup({
    ensure_installed = {
        "lua_ls",
        "rust_analyzer",
    },
})
