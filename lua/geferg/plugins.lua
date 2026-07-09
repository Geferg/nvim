local plugin_files = vim.api.nvim_get_runtime_file("lua/geferg/plugins/*.lua", true)

table.sort(plugin_files)

for _, file in ipairs(plugin_files) do
    local module = file
        :gsub("^.*/lua/", "")
        :gsub("%.lua$", "")
        :gsub("/", ".")

    local ok, err = pcall(require, module)

    if not ok then
        vim.notify(
            ("Failed to load plugin config '%s':\n%s"):format(module, err),
            vim.log.levels.ERROR
        )
    end
end
