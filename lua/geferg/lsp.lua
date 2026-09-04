local group = vim.api.nvim_create_augroup("geferg_lsp", { clear = true })

vim.diagnostic.config({
    virtual_text = {
        spacing = 2,
        prefix = "●",
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
        local bufnr = args.buf

        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
                buffer = bufnr,
                desc = desc,
            })
        end

        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gr", vim.lsp.buf.references, "Go to references")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "K", vim.lsp.buf.hover, "Hover documentation")

        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = false })
        end, "Format buffer")

        map("n", "<leader>df", vim.diagnostic.open_float, "Diagnostic float")
        map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
        map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics to location list")
    end,
})

vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = {
        ".luarc.json",
        ".luarc.jsonc",
        ".git",
    },
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = {
                    "vim",
                },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                },
            },
            telemetry = {
                enable = false,
            },
        },
    },
})

vim.lsp.config("rust_analyzer", {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = {
        "Cargo.toml",
        "rust-project.json",
        ".git",
    },
    settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
            },
            check = {
                command = "clippy",
            },
        },
    },
})

vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },

    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },

    root_markers = {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
    },

    init_options = {
        hostInfo = "neovim",
    },

    settings = {
        typescript = {
            preferences = {
                importModuleSpecifier = "non-relative",
            },
        },
        javascript = {
            preferences = {
                importModuleSpecifier = "non-relative",
            },
        },
    },
})

vim.lsp.enable({
    "lua_ls",
    "rust_analyzer",
    "ts_ls",
})
