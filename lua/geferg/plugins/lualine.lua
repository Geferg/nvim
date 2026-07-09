vim.pack.add({
    {
        src = "https://github.com/nvim-lualine/lualine.nvim",
        name = "lualine.nvim",
    },
    {
        src = "https://github.com/nvim-tree/nvim-web-devicons",
        name = "nvim-web-devicons",
    },
})

local palette = require("onedark.palette").dark

-- Keep the original example's color names so the rest of the example
-- can stay structurally close to the source.
local colors = {
    red = palette.red,
    grey = palette.bg2 or palette.bg1,
    black = palette.bg0,
    white = palette.fg,
    light_green = palette.cyan,
    orange = palette.orange,
    green = palette.green,

    -- Explicit statusline background/gap color.
    bg = palette.bg0,
}

local theme = {
    normal = {
        a = { fg = colors.white, bg = colors.black },
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = colors.bg },
        z = { fg = colors.white, bg = colors.black },
    },
    insert = {
        a = { fg = colors.black, bg = colors.light_green },
    },
    visual = {
        a = { fg = colors.black, bg = colors.orange },
    },
    replace = {
        a = { fg = colors.black, bg = colors.green },
    },
    command = {
        a = { fg = colors.black, bg = colors.orange },
    },
    inactive = {
        a = { fg = colors.grey, bg = colors.bg },
        b = { fg = colors.grey, bg = colors.bg },
        c = { fg = colors.grey, bg = colors.bg },
    },
}

local empty = require("lualine.component"):extend()

function empty:draw(default_highlight)
    self.status = ""
    self.applied_separator = ""
    self:apply_highlights(default_highlight)
    self:apply_section_separators()
    return self.status
end

-- This is intentionally very close to the original example.
local function process_sections(sections)
    for name, section in pairs(sections) do
        local left = name:sub(9, 10) < "x"

        for pos = 1, name ~= "lualine_z" and #section or #section - 1 do
            table.insert(section, pos * 2, {
                empty,
                color = { fg = colors.bg, bg = colors.bg },
            })
        end

        for id, comp in ipairs(section) do
            if type(comp) ~= "table" then
                comp = { comp }
                section[id] = comp
            end

            comp.separator = left and { right = "" } or { left = "" }
        end
    end

    return sections
end

local function search_result()
    if vim.v.hlsearch == 0 then
        return ""
    end

    local last_search = vim.fn.getreg("/")

    if not last_search or last_search == "" then
        return ""
    end

    local searchcount = vim.fn.searchcount({ maxcount = 9999 })

    if searchcount.total == 0 then
        return ""
    end

    return last_search .. " (" .. searchcount.current .. "/" .. searchcount.total .. ")"
end

local function modified()
    if vim.bo.modified then
        return "+"
    elseif vim.bo.modifiable == false or vim.bo.readonly == true then
        return "-"
    end

    return ""
end

require("lualine").setup({
    options = {
        theme = theme,
        component_separators = "",
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = {
            statusline = { "neo-tree" },
            winbar = {},
        },
    },

    sections = process_sections({
        lualine_a = {
            "mode",
        },

        lualine_b = {
            "branch",
            "diff",

            {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                sections = { "error" },
                diagnostics_color = {
                    error = { bg = colors.red, fg = colors.white },
                },
            },

            {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                sections = { "warn" },
                diagnostics_color = {
                    warn = { bg = colors.orange, fg = colors.black },
                },
            },

            {
                "filename",
                file_status = false,
                path = 1,
            },

            {
                modified,
                color = { bg = colors.red, fg = colors.white },
            },

            {
                "%w",
                cond = function()
                    return vim.wo.previewwindow
                end,
            },

            {
                "%r",
                cond = function()
                    return vim.bo.readonly
                end,
            },

            {
                "%q",
                cond = function()
                    return vim.bo.buftype == "quickfix"
                end,
            },
        },

        lualine_c = {},

        lualine_x = {},

        lualine_y = {
            search_result,
            "filetype",
        },

        lualine_z = {
            "%l:%c",
            "%p%%/%L",
        },
    }),

    inactive_sections = {
        lualine_c = {
            "%f %y %m",
        },
        lualine_x = {},
    },

    extensions = {
        "neo-tree",
    },
})
