vim.pack.add({
    {
        src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
        name = "render-markdown.nvim",
    },
})

local render_markdown = require("render-markdown")

render_markdown.setup({
    file_types = { "markdown" },

    -- Keep the plugin itself conservative.
    -- We drive pretty/raw state with autocmds below.
    render_modes = { "n" },
})

local group = vim.api.nvim_create_augroup("geferg_markdown_render", { clear = true })

local timers = {}

local function is_markdown(bufnr)
    return vim.bo[bufnr].filetype == "markdown"
end

local function disable_render(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if not is_markdown(bufnr) then
        return
    end

    pcall(render_markdown.buf_disable, bufnr)
end

local function enable_render(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if not is_markdown(bufnr) then
        return
    end

    if vim.api.nvim_get_current_buf() ~= bufnr then
        return
    end

    if vim.api.nvim_get_mode().mode ~= "n" then
        return
    end

    pcall(render_markdown.buf_enable, bufnr)
end

local function clear_timer(bufnr)
    local timer = timers[bufnr]

    if timer then
        timer:stop()
        timer:close()
        timers[bufnr] = nil
    end
end

local function debounce_enable(bufnr, delay_ms)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    delay_ms = delay_ms or 1000

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if not is_markdown(bufnr) then
        return
    end

    clear_timer(bufnr)

    local timer = vim.uv.new_timer()
    timers[bufnr] = timer

    timer:start(delay_ms, 0, function()
        vim.schedule(function()
            if timers[bufnr] == timer then
                timers[bufnr] = nil
            end

            timer:stop()
            timer:close()

            enable_render(bufnr)
        end)
    end)
end

-- When entering markdown, render shortly after the buffer settles.
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = group,
    pattern = "markdown",
    callback = function()
        debounce_enable(vim.api.nvim_get_current_buf(), 300)
    end,
})

-- Insert mode and command-line mode should always show the faithful buffer.
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
    group = group,
    callback = function()
        disable_render(vim.api.nvim_get_current_buf())
    end,
})

-- Leaving insert/cmdline: wait a bit before returning to pretty mode.
vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = group,
    callback = function()
        debounce_enable(vim.api.nvim_get_current_buf(), 1000)
    end,
})

-- Enter visual mode: show faithful markdown.
--
-- Modes:
--   v       visual character
--   V       visual line
--   Ctrl-V  visual block, represented as \22
vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:[vV\22]",
    callback = function()
        disable_render(vim.api.nvim_get_current_buf())
    end,
})

-- Leave visual mode back to normal: render again after idle delay.
vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "[vV\22]:n",
    callback = function()
        debounce_enable(vim.api.nvim_get_current_buf(), 1000)
    end,
})

-- Normal-mode movement: immediately show faithful markdown, then return
-- to pretty mode after 1000ms without further movement.
vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()

        disable_render(bufnr)
        debounce_enable(bufnr, 1000)
    end,
})

-- If cursor moves in insert mode, keep it raw and do not schedule pretty mode.
vim.api.nvim_create_autocmd("CursorMovedI", {
    group = group,
    callback = function()
        disable_render(vim.api.nvim_get_current_buf())
    end,
})

-- Cleanup timers when buffers go away.
vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
        clear_timer(args.buf)
    end,
})
