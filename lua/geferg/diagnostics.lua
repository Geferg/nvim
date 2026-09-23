local M = {}

local function normalize_path(path)
    path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))

    local real = vim.uv.fs_realpath(path)

    if real then
        return vim.fs.normalize(real)
    end

    return path
end

local function open_quickfix(title, items)
    vim.fn.setqflist({}, "r", {
        title = title,
        items = items,
    })

    if #items == 0 then
        vim.cmd("cclose")
        return
    end

    vim.cmd("copen")
end

local function selected_scope(path)
    path = normalize_path(path)

    if vim.fn.filereadable(path) == 1 then
        return {
            path = path,
            kind = "file",
        }
    end

    return {
        path = path,
        kind = "directory",
    }
end

local function find_typescript_config(path)
    local start = path

    if vim.fn.filereadable(start) == 1 then
        start = vim.fs.dirname(start)
    end

    local configs = vim.fs.find(
        { "tsconfig.json", "jsconfig.json" },
        {
            path = start,
            upward = true,
            type = "file",
        }
    )

    if not configs[1] then
        return nil
    end

    return normalize_path(configs[1])
end

local function find_repo_root(path)
    local start = path

    if vim.fn.filereadable(start) == 1 then
        start = vim.fs.dirname(start)
    end

    local root = vim.fs.root(start, { ".git" })

    if root then
        return normalize_path(root)
    end

    return normalize_path(vim.fn.getcwd())
end

local function is_absolute_path(path)
    return path:sub(1, 1) == "/"
        or path:match("^%a:[/\\]") ~= nil
        or path:match("^[/\\][/\\]") ~= nil
end

local function resolve_diagnostic_path(filename, cwd)
    if is_absolute_path(filename) then
        return normalize_path(filename)
    end

    return normalize_path(
        vim.fs.joinpath(cwd, filename)
    )
end

local function compact_message(lines)
    local parts = {}

    for _, line in ipairs(lines) do
        local text = vim.trim(line)

        if text ~= "" then
            table.insert(parts, text)
        end
    end

    return table.concat(parts, " ")
end

local function parse_tsc_output(output, cwd)
    local items = {}
    local current = nil

    local function finish_current()
        if not current then
            return
        end

        current.text = compact_message(
            current.message_lines
        )
        current.message_lines = nil

        table.insert(items, current)
        current = nil
    end

    for line in vim.gsplit(output, "\n", {
        plain = true,
    }) do
        local filename,
            lnum,
            col,
            severity,
            code,
            message =
            line:match(
                "^(.-)%((%d+),(%d+)%)%: (%a+) TS(%d+): (.*)$"
            )

        if filename then
            finish_current()

            local type_map = {
                error = "E",
                warning = "W",
                info = "I",
            }

            current = {
                filename = resolve_diagnostic_path(
                    filename,
                    cwd
                ),
                lnum = tonumber(lnum),
                col = tonumber(col),
                nr = tonumber(code),
                type = type_map[severity] or "E",
                message_lines = { message },
            }
        elseif current then
            local trimmed = vim.trim(line)

            if
                trimmed ~= ""
                and not trimmed:match("^Found %d+ error")
                and not trimmed:match("^Errors%s+Files")
            then
                table.insert(
                    current.message_lines,
                    trimmed
                )
            end
        end
    end

    finish_current()

    return items
end

local function is_inside_directory(filename, directory)
    filename = normalize_path(filename)
    directory = normalize_path(directory)

    local relative = vim.fs.relpath(
        directory,
        filename
    )

    if relative == nil then
        return false
    end

    return relative ~= ".."
        and not vim.startswith(relative, "../")
end

local function filter_to_scope(items, scope)
    return vim.tbl_filter(function(item)
        if not item.filename or item.filename == "" then
            return false
        end

        local filename = normalize_path(
            item.filename
        )

        if scope.kind == "file" then
            return filename == scope.path
        end

        return is_inside_directory(
            filename,
            scope.path
        )
    end, items)
end

local function process_failure_message(result)
    local stderr = vim.trim(result.stderr or "")
    local stdout = vim.trim(result.stdout or "")

    if stderr ~= "" then
        return stderr
    end

    if stdout ~= "" then
        return stdout
    end

    return "TypeScript diagnostics failed"
end

function M.current_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if filename == "" then
        vim.notify(
            "Current buffer has no file",
            vim.log.levels.WARN
        )
        return
    end

    local diagnostics = vim.diagnostic.get(bufnr)
    local items = vim.diagnostic.toqflist(
        diagnostics
    )

    open_quickfix(
        "Diagnostics: "
            .. vim.fn.fnamemodify(filename, ":t"),
        items
    )

    if #items == 0 then
        vim.notify(
            "No diagnostics for current file",
            vim.log.levels.INFO
        )
    end
end

function M.typescript_path(path)
    if not path or path == "" then
        vim.notify(
            "No path selected",
            vim.log.levels.WARN
        )
        return
    end

    local scope = selected_scope(path)
    local config = find_typescript_config(
        scope.path
    )

    if not config then
        vim.notify(
            "No tsconfig.json or jsconfig.json found",
            vim.log.levels.WARN
        )
        return
    end

    local repo_root = find_repo_root(config)

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
            cwd = repo_root,
            text = true,
        },
        function(result)
            vim.schedule(function()
                local output = table.concat({
                    result.stdout or "",
                    result.stderr or "",
                }, "\n")

                local items = parse_tsc_output(
                    output,
                    repo_root
                )

                if result.code ~= 0 and #items == 0 then
                    vim.notify(
                        process_failure_message(result),
                        vim.log.levels.ERROR
                    )
                    return
                end

                items = filter_to_scope(
                    items,
                    scope
                )

                open_quickfix(
                    "TypeScript: "
                        .. vim.fn.fnamemodify(
                            scope.path,
                            ":~:."
                        ),
                    items
                )

                if #items == 0 then
                    vim.notify(
                        "No TypeScript diagnostics in selected scope",
                        vim.log.levels.INFO
                    )
                end
            end)
        end
    )
end

return M
