local group = vim.api.nvim_create_augroup("geferg_core", { clear = true })

-- Prevent automatic comment continuation on new lines.
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Disable automatic comment continuation",
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

-- Highlight yanked text briefly.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    desc = "Highlight yanked text",
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

-- Trim trailing whitespace on save, but only for normal modifiable file buffers.
vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    desc = "Trim trailing whitespace",
    callback = function(args)
        local bufnr = args.buf

        if not vim.bo[bufnr].modifiable then
            return
        end

        if vim.bo[bufnr].buftype ~= "" then
            return
        end

        local view = vim.fn.winsaveview()

        vim.cmd([[%s/\s\+$//e]])

        vim.fn.winrestview(view)
    end,
})

-- Reload file if changed externally.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    group = group,
    desc = "Check for external file changes",
    callback = function()
        if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
        end
    end,
})

-- Create parent directories before saving a new file.
vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    desc = "Create parent directories on save",
    callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then
            return
        end

        local file = vim.fn.expand("<afile>:p")

        if file == "" then
            return
        end

        local dir = vim.fn.fnamemodify(file, ":h")

        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end
    end,
})

-- Proper filetypes for uncommon extensions.
vim.filetype.add({
    extension = {
        cconf = "conf",
    },
})

-- Restore last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    desc = "Restore last cursor position",
    callback = function(args)
        local bufnr = args.buf

        if vim.bo[bufnr].buftype ~= "" then
            return
        end

        local mark = vim.api.nvim_buf_get_mark(bufnr, '"')
        local line = mark[1]
        local last_line = vim.api.nvim_buf_line_count(bufnr)

        if line > 1 and line <= last_line then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
