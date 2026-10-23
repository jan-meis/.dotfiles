-- File bookmarks, independent of line marks and third-party bookmark plugins.
local M = {}
local files = {}
local store_path
local store_base
local scope_key
local scope_label
local get_mru
local cycle_order
local jumping = false
local group

local function current_path(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" or vim.bo[buf].buftype ~= "" then return nil end
    return vim.fn.fnamemodify(name, ":p")
end

local function context(directory)
    local function git(...)
        local result = vim.system({ "git", "-C", directory, ... }, { text = true }):wait()
        if result.code == 0 then return vim.trim(result.stdout) end
    end
    local root = git("rev-parse", "--show-toplevel")
    if root then
        local branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
            or ("detached:" .. (git("rev-parse", "HEAD") or "unknown"))
        return root .. "\n" .. branch, vim.fn.fnamemodify(root, ":t") .. " / " .. branch
    end
    local path = vim.uv.fs_realpath(directory) or directory
    return "directory\n" .. path, vim.fn.fnamemodify(path, ":~")
end

local function scoped_path(key)
    return store_base .. ".d/" .. vim.fn.sha256(key) .. ".json"
end

local function load(path)
    if vim.fn.filereadable(path) == 0 then return {} end
    local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), "\n")) end)
    if not ok or type(data) ~= "table" then
        error("Cannot read file bookmarks; leaving the store untouched: " .. path)
    end
    return data
end

local function refresh_scope()
    local directory = vim.fn.getcwd()
    -- An explicit project cwd wins; otherwise use the current file's repository.
    if not vim.fs.root(directory, { ".git" }) then
        local path = current_path()
        if path then
            local root = vim.fs.root(vim.fn.fnamemodify(path, ":h"), { ".git" })
            if root then directory = root end
        end
    end
    local key, label = context(directory)
    if key == scope_key then return end
    local path = scoped_path(key)
    local data = load(path)
    scope_key, scope_label, store_path = key, label, path
    files = data
    cycle_order = nil
end

local function save()
    local ok, err = pcall(function()
        vim.fn.mkdir(vim.fn.fnamemodify(store_path, ":h"), "p")
        local temporary = store_path .. "." .. vim.fn.getpid() .. ".tmp"
        assert(vim.fn.writefile({ vim.json.encode(files) }, temporary) == 0)
        assert(vim.uv.fs_rename(temporary, store_path))
    end)
    if not ok then vim.notify("Could not save bookmarks: " .. tostring(err), vim.log.levels.ERROR) end
end

local function migrate_legacy()
    local marker = store_base .. ".d/legacy-imported"
    if vim.fn.filereadable(marker) == 1 or vim.fn.filereadable(store_base) == 0 then return end
    local scopes = {}
    for path, entry in pairs(load(store_base)) do
        local key = context(vim.fn.fnamemodify(path, ":h"))
        local destination = scoped_path(key)
        scopes[destination] = scopes[destination] or load(destination)
        if not scopes[destination][path] then scopes[destination][path] = entry end
    end
    vim.fn.mkdir(store_base .. ".d", "p")
    for destination, data in pairs(scopes) do
        assert(vim.fn.writefile({ vim.json.encode(data) }, destination) == 0)
    end
    assert(vim.fn.writefile({ "Legacy bookmarks imported; original file preserved." }, marker) == 0)
end

local function capture()
    local path = current_path()
    if path and files[path] then
        local cursor = vim.api.nvim_win_get_cursor(0)
        files[path].lnum, files[path].col = cursor[1], cursor[2]
        save()
    end
end

local function position(path)
    local buf = vim.fn.bufnr(path)
    if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
        local windows = vim.fn.win_findbuf(buf)
        if #windows > 0 then
            local cursor = vim.api.nvim_win_get_cursor(windows[1])
            return cursor[1], cursor[2]
        end
        return files[path].lnum or 1, files[path].col or 0
    end
    local recent = get_mru(path)
    return (type(recent) == "table" and recent.lnum) or files[path].lnum or 1,
        files[path].col or 0
end

function M.ordered()
    refresh_scope()
    local paths = {}
    for path in pairs(files) do
        if vim.fn.filereadable(path) == 1 then paths[#paths + 1] = path end
    end
    local function visited(path)
        local recent = get_mru(path)
        local time = type(recent) == "table" and recent.time or recent
        return math.max(tonumber(time) or 0, files[path].time or 0)
    end
    table.sort(paths, function(a, b)
        if visited(a) ~= visited(b) then return visited(a) > visited(b) end
        return a < b
    end)
    return paths
end

function M.open(path)
    refresh_scope()
    if not path or not files[path] then return end
    if vim.fn.filereadable(path) ~= 1 then
        vim.notify("Bookmarked file is missing: " .. path, vim.log.levels.WARN)
        return
    end
    capture()
    local lnum, col = position(path)
    jumping = true
    local ok, err = pcall(function()
        vim.cmd.edit(vim.fn.fnameescape(path))
        lnum = math.max(1, math.min(lnum, vim.api.nvim_buf_line_count(0)))
        col = math.min(col, #vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1])
        vim.api.nvim_win_set_cursor(0, { lnum, col })
        vim.cmd("normal! zz")
    end)
    jumping = false
    if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
end

function M.toggle()
    refresh_scope()
    local path = current_path()
    if not path or vim.fn.filereadable(path) ~= 1 then
        vim.notify("Open a saved file to bookmark it", vim.log.levels.WARN)
        return
    end
    if files[path] then
        files[path] = nil
        vim.notify("File bookmark removed")
    else
        local cursor = vim.api.nvim_win_get_cursor(0)
        files[path] = { lnum = cursor[1], col = cursor[2], time = os.time() }
        vim.notify("File bookmarked")
    end
    cycle_order = nil
    save()
end

function M.cycle(direction)
    refresh_scope()
    capture()
    cycle_order = cycle_order or M.ordered()
    -- Keep the snapshot order while cycling; skip files deleted since it was made.
    local paths = vim.tbl_filter(function(path)
        return files[path] and vim.fn.filereadable(path) == 1
    end, cycle_order)
    cycle_order = paths
    if #paths == 0 then vim.notify("No file bookmarks"); return end
    local index
    for i, path in ipairs(paths) do
        if path == current_path() then index = i; break end
    end
    index = index or (direction > 0 and 0 or 1)
    M.open(paths[(index - 1 + direction) % #paths + 1])
end

function M.assign(path, number)
    refresh_scope()
    if not files[path] then return end
    if number ~= nil and (number < 0 or number > 9 or number % 1 ~= 0) then return end
    if number then
        for _, entry in pairs(files) do
            if entry.number == number then entry.number = nil end
        end
    end
    files[path].number = number
    save()
end

function M.jump(number)
    refresh_scope()
    for path, entry in pairs(files) do
        if entry.number == number then
            cycle_order = nil
            M.open(path)
            return
        end
    end
    vim.notify("No bookmark assigned to m" .. number)
end

function M.pick(assign_number)
    refresh_scope()
    capture()
    local paths = M.ordered()
    if #paths == 0 then vim.notify("No file bookmarks"); return end
    cycle_order = paths
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values
    local make_entry = require("telescope.make_entry").gen_from_file({ path_display = { "truncate" } })
    pickers.new({ layout_strategy = "vertical", layout_config = { preview_height = 0.7 } }, {
        prompt_title = (assign_number and "Assign bookmark number: " or "File bookmarks: ") .. scope_label,
        finder = finders.new_table({
            results = paths,
            entry_maker = function(path)
                local entry = make_entry(path)
                local display = entry.display
                entry.display = function(e)
                    local text, highlights = display(e)
                    -- Append the number so path sorting and devicon highlights stay intact.
                    return text .. (files[path].number and ("  [m" .. files[path].number .. "]") or ""), highlights
                end
                return entry
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            title = "Last position",
            get_buffer_by_name = function(_, entry) return entry.path end,
            define_preview = function(self, entry)
                local lnum = position(entry.path)
                conf.buffer_previewer_maker(entry.path, self.state.bufnr, {
                    bufname = self.state.bufname,
                    winid = self.state.winid,
                    callback = function(buf)
                        if not vim.api.nvim_win_is_valid(self.state.winid) then return end
                        local line = math.max(1, math.min(lnum, vim.api.nvim_buf_line_count(buf)))
                        pcall(vim.api.nvim_win_set_cursor, self.state.winid, { line, 0 })
                        vim.api.nvim_win_call(self.state.winid, function() vim.cmd("normal! zz") end)
                    end,
                })
            end,
        }),
        attach_mappings = function(prompt_buf)
            actions.select_default:replace(function()
                local entry = action_state.get_selected_entry()
                if not entry then return end
                actions.close(prompt_buf)
                if not assign_number then
                    cycle_order = paths
                    M.open(entry.path)
                    return
                end
                vim.schedule(function()
                    vim.ui.input({ prompt = "Shortcut (0–9; x clears): ", default = tostring(files[entry.path].number or "") }, function(input)
                        if input == nil then return end
                        local number = tonumber(input)
                        if input == "x" then M.assign(entry.path, nil)
                        elseif number and number >= 0 and number <= 9 and number % 1 == 0 then M.assign(entry.path, number)
                        else vim.notify("Enter a number from 0 to 9, or x to clear", vim.log.levels.WARN) end
                    end)
                end)
            end)
            return true
        end,
    }):find()
end

function M.setup(opts)
    opts = opts or {}
    store_base = opts.path or (vim.fn.stdpath("data") .. "/file-bookmarks.json")
    get_mru = opts.get_mru or function() return nil end
    scope_key, cycle_order = nil, nil
    migrate_legacy()
    refresh_scope()
    group = vim.api.nvim_create_augroup("file_bookmarks", { clear = true })
    vim.api.nvim_create_autocmd({ "BufLeave", "VimLeavePre" }, { group = group, callback = capture })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].buftype ~= "" then return end
            refresh_scope()
            if not jumping then cycle_order = nil end
            local path = current_path(args.buf)
            if path and files[path] then
                local seconds, microseconds = vim.uv.gettimeofday()
                files[path].time = seconds + microseconds / 1000000
                save()
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "DirChanged", "FocusGained" }, {
        group = group,
        callback = refresh_scope,
    })
end

return M
