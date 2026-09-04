vim.pack.add({
    {
        src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
        version = vim.version.range("3"),
    },
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/nvim-tree/nvim-web-devicons",
})

require("neo-tree").setup({
    filesystem = {
        window = {
            mappings = {
                ["<leader>sd"] = function(state)
                    local node = state.tree:get_node()

                    if not node or not node.path then
                        vim.notify(
                            "No Neo-tree node selected",
                            vim.log.levels.WARN
                        )
                        return
                    end

                    require("geferg.diagnostics").typescript_path(node.path)
                end,
            },
        },
    },
})
