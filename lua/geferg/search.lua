local function neotree_rg_from_node()
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if not ok then
        vim.notify("neo-tree is not available", vim.log.levels.ERROR)
        return
    end

    local state = manager.get_state("filesystem")
    if not state or not state.tree then
        vim.notify("neo-tree filesystem state is not available", vim.log.levels.WARN)
        return
    end

    local node = state.tree:get_node()
    local path = node and node.path or vim.fn.getcwd()

    if vim.fn.filereadable(path) == 1 then
        path = vim.fs.dirname(path)
    end

    vim.ui.input({ prompt = "Ripgrep in " .. path .. ": " }, function(query)
        if not query or query == "" then
            return
        end

        vim.fn.setqflist({}, " ", {
            title = "rg: " .. query,
            lines = vim.fn.systemlist({
                "rg",
                "--vimgrep",
                "--smart-case",
                query,
                path,
            }),
        })

        vim.cmd("copen")
    end)
end

vim.keymap.set("n", "<leader>sg", neotree_rg_from_node, {
    desc = "Ripgrep from Neo-tree node",
})
