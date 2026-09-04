local M = {}

local severity_to_qf_type = {
    [vim.diagnostic.severity.ERROR] = "E",
    [vim.diagnostic.severity.WARN] = "W",
    [vim.diagnostic.severity.INFO] = "I",
    [vim.diagnostic.severity.HINT] = "N",
}

local function normalize_path(path, cwd)
    return vim.fs.normalize(vim.fs.abspath(path, { cwd = cwd }))
end

local function compact_message(message)
    local lines = vim.split(message, "\n", {
        plain = true,
        trimempty = true,
    })

    if #lines <= 1 then
        return vim.trim(message)
    end

    local property

    for _, line in ipairs(lines) do
        local text = vim.trim(line)

        property = text:match("^Types of property '([^']+)' are incompatible%.$")
            or property
    end

    local cause = vim.trim(lines[#lines])

    if property then
        return ("%s: %s"):format(property, cause)
    end

    return cause
end

local function set_quickfix(title, items, empty_message)
    vim.fn.setqflist({}, "r", {
        title = title,
        items = items,
    })

    if #items == 0 then
        vim.cmd("cclose")
        vim.notify(empty_message)
        return
    end

    vim.cmd("copen")
end

local function diagnostic_code(diagnostic)
    if diagnostic.code then
        return tonumber(diagnostic.code) or 0
    end

    local lsp = diagnostic.user_data and diagnostic.user_data.lsp

    if lsp and lsp.code then
        return tonumber(lsp.code) or 0
    end

    return 0
end

local function parse_tsc_output(output, cwd)
    local items = {}
    local current

    local function finish()
        if not current then
            return
        end

        local message = current.message

        if #current.details > 0 then
            message = message .. "\n" .. table.concat(current.details, "\n")
        end

        items[#items + 1] = {
            filename = normalize_path(current.filename, cwd),
            lnum = current.lnum,
            col = current.col,
            type = current.severity == "warning" and "W" or "E",
            nr = current.code,
            text = compact_message(message),
        }

        current = nil
    end

    for line in output:gmatch("[^\r\n]+") do
        local filename, lnum, col, severity, code, message =
            line:match("^(.*)%((%d+),(%d+)%)%: (%a+) TS(%d+)%: (.*)$")

        if filename then
            finish()

            current = {
                filename = filename,
                lnum = tonumber(lnum),
                col = tonumber(col),
                severity = severity,
                code = tonumber(code),
                message = message,
                details = {},
            }
        elseif current and line:match("^%s+") then
            current.details[#current.details + 1] = vim.trim(line)
        end
    end

    finish()

    return items
end

local function find_typescript_config(path, is_file)
    local start = is_file and vim.fs.dirname(path) or path

    return vim.fs.find(
        { "tsconfig.json", "jsconfig.json" },
        {
            path = start,
            upward = true,
            type = "file",
        }
    )[1]
end

local function filter_to_path(items, path, is_file)
    if is_file then
        return vim.tbl_filter(function(item)
            return item.filename == path
        end, items)
    end

    local prefix = path .. "/"

    return vim.tbl_filter(function(item)
        return item.filename == path
            or vim.startswith(item.filename, prefix)
    end, items)
end

function M.current_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if filename == "" then
        vim.notify("Current buffer has no file", vim.log.levels.WARN)
        return
    end

    local items = {}

    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
        items[#items + 1] = {
            bufnr = bufnr,
            lnum = diagnostic.lnum + 1,
            col = diagnostic.col + 1,
            type = severity_to_qf_type[diagnostic.severity],
            nr = diagnostic_code(diagnostic),
            text = compact_message(diagnostic.message),
        }
    end

    table.sort(items, function(a, b)
        if a.lnum == b.lnum then
            return a.col < b.col
        end

        return a.lnum < b.lnum
    end)

    set_quickfix(
        "Diagnostics: " .. vim.fs.basename(filename),
        items,
        "No diagnostics in " .. vim.fs.basename(filename)
    )
end

function M.typescript_path(path)
    path = normalize_path(path)

    local stat = vim.uv.fs_stat(path)

    if not stat or (stat.type ~= "file" and stat.type ~= "directory") then
        vim.notify("Invalid diagnostic path: " .. path, vim.log.levels.ERROR)
        return
    end

    local is_file = stat.type == "file"
    local config = find_typescript_config(path, is_file)

    if not config then
        vim.notify(
            "No tsconfig.json or jsconfig.json found for " .. path,
            vim.log.levels.ERROR
        )
        return
    end

    local project_root = vim.fs.dirname(config)

    vim.system(
        {
            "npx",
            "tsc",
            "--noEmit",
            "--pretty",
            "false",
            "--project",
            config,
        },
        {
            cwd = project_root,
            text = true,
        },
        function(result)
            vim.schedule(function()
                local items = parse_tsc_output(result.stdout or "", project_root)

                if result.code ~= 0 and #items == 0 then
                    local message = vim.trim(
                        (result.stdout or "") .. "\n" .. (result.stderr or "")
                    )

                    vim.notify(
                        message ~= "" and message or "TypeScript check failed",
                        vim.log.levels.ERROR
                    )
                    return
                end

                items = filter_to_path(items, path, is_file)

                set_quickfix(
                    "TypeScript: " .. path,
                    items,
                    "No TypeScript errors under " .. path
                )
            end)
        end
    )
end

return M
