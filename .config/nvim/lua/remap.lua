-- global functions
function InsertFilename()
    local current_file_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, pos) .. current_file_name .. line:sub(pos + 1)
    vim.api.nvim_set_current_line(nline)
end

function TmuxSend(command, pane)
  vim.cmd('!tmux send-keys -t ' .. pane .. ' \"' ..  command .. '" ENTER')
end

function NavigateFold(direction)
  local cmd = "normal! " .. direction
  local view = vim.fn.winsaveview()
  local lnum = view.lnum
  local new_lnum = lnum
  local open = true

  while lnum == new_lnum or open do
    vim.cmd(cmd)
    new_lnum = vim.fn.line "."
    open = vim.fn.foldclosed(new_lnum) < 0
  end

  if open then
    vim.fn.winrestview(view)
  end
end

-- general vim QoL improvments
vim.keymap.set("n", "<F1>", function() local wordUnderCursor = vim.fn.expand("<cword>"); vim.cmd("tab Man " .. wordUnderCursor) end, { desc = "Get Man page for word under cursor" })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR>")
vim.keymap.set("c", "<C-CR>", "<CR><Cmd>nohlsearch<CR>", { silent = true, desc = "Execute search and clear highlight" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Move next line up to current line" } )
vim.keymap.set("i", "<Tab>","<C-v><Tab>" , { desc = "Tab" })
vim.keymap.set("n", "<leader>ht", function() vim.cmd("set list!") end, { desc = "Toggle tab visibility" })
vim.keymap.set({ "n" }, "<leader>t", "<C-w>T", { desc = "Maximize current split" })
vim.keymap.set({ "n" }, "<C-w>e", ":vnew | q<CR>", { desc = "Equalize  splits" })
vim.keymap.set({ "n" }, "<C-w>E", ":new | q<CR>", { desc = "Equalize horizontal splits" })
vim.keymap.set("n", "zj", ':lua NavigateFold("j")<CR>', { noremap = true, silent = true })
vim.keymap.set("n", "zk", ':lua NavigateFold("k")<CR>', { noremap = true, silent = true })

-- clipboard / yank / paste
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set({"n" },       "<leader>Y", [["+Y]], { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from clipboard (after)" })
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]], { desc = "Paste from clipboard (before)" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
--vim.keymap.set({ "n" }, "p", "p=ap", { noremap = true, silent = true })
--vim.keymap.set({ "n" }, "P", "P=ap", { noremap = true, silent = true })
--vim.keymap.set({ "x" }, "p", function() if vim.fn.mode() ~= "V" then return vim.cmd("normal! p") else return vim.cmd("normal! p=ap") end end, { noremap = true, silent = true })
--vim.keymap.set({ "x" }, "P", function() if vim.fn.mode() ~= "V" then return vim.cmd("normal! P") else return vim.cmd("normal! P=ap") end end, { noremap = true, silent = true })


-- LSP bindings
-- Default mappings since 0.11
-- grn in Normal mode maps to vim.lsp.buf.rename()
-- grr in Normal mode maps to vim.lsp.buf.references()
-- gri in Normal mode maps to vim.lsp.buf.implementation()
-- gO in Normal mode maps to vim.lsp.buf.document_symbol()
-- gra in Normal and Visual mode maps to vim.lsp.buf.code_action()
-- CTRL-S in Insert and Select mode maps to vim.lsp.buf.signature_help()
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', {  desc = "Show documentation" })
vim.keymap.set('n', ']e', '<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<cr>', { desc = "Go to next diagnostic" })
vim.keymap.set('n', '[e', '<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<cr>', { desc = "Go to next diagnostic" })
vim.keymap.set('n', 'grd', '<cmd>lua vim.lsp.buf.definition()<cr>', {  desc = "Go to definition" })
vim.keymap.set('n', 'grD', '<cmd>lua vim.lsp.buf.declaration()<cr>', {  desc = "Go to declaration" })
vim.keymap.set('n', '<leader>o', '<cmd>lua vim.diagnostic.open_float()<cr>', { desc = "Open diagnostic" })
 vim.keymap.set('i', '<F9>', function()
  if not vim.lsp.inline_completion.get() then
    return '<F9>'
  end
end, { expr = true, desc = 'Accept the current inline completion' })
vim.keymap.set({ 'n', 'x', 'v' }, '<F3>',
    function()
        if vim.api.nvim_get_mode().mode == 'n' then
            if (AllowGlobalFormat) then
                vim.lsp.buf.format({ async = true })
            end
        else
            vim.lsp.buf.format({ async = true })
        end
    end, { desc = "Format buffer" })
vim.keymap.set('n', '<leader>sqf', '<cmd>lua vim.diagnostic.setqflist()<cr>', { desc = "Set quickfix list" })

-- nvim-bqf (better quickfix list)
local function toggleQuickfix()
  local qfopen = false
  for _, w in pairs(vim.api.nvim_list_wins()) do
    if (vim.fn.win_gettype(w) == "quickfix") then
      qfopen = true
    end
  end
  if (not qfopen) then
    vim.cmd("copen 6")
  else
    vim.cmd.cclose()
  end
end

local function toggleLocation()
  local qfopen = false
  for _, w in pairs(vim.api.nvim_list_wins()) do
    print (vim.fn.win_gettype(w))
    if (vim.fn.win_gettype(w) == "loclist") then
      qfopen = true
    end
  end
  if (not qfopen) then
    vim.cmd("lopen 6")
  else
    vim.cmd.lclose()
  end
end

vim.keymap.set("n", "<leader>q", toggleQuickfix, { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>w", toggleLocation, { desc = "Toggle quickfix list" })

-- File explorer (directory tree)
-- nvim-tree keymap is defined in init.lua via lazy keys so the plugin loads on demand
vim.keymap.set("n", "<space>fe", function()
  require("telescope").extensions.file_browser.file_browser()
end, { desc = "Open file browser" })

vim.keymap.set("n", "<space>fE", function()
  local current_file_dir = vim.fn.expand("%:p:h")

  if current_file_dir == "" then
    current_file_dir = vim.loop.cwd()
  end

  require("telescope").extensions.file_browser.file_browser({
    path = current_file_dir,
    cwd = current_file_dir,
  })
end, { desc = "Open file browser at current file directory" })

-- My own QoL functions for copying context

local function getFilePath()
  return vim.fn.expand('%:.')
end

local function getFilePathAndLineNumber()
  return vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
end


local function copyLineNumber()
  local ret = vim.fn.getcurpos()[2]
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function copyFilePath()
  local ret = getFilePath()
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function copyFilePathAndLineNumber()
  local ret = getFilePathAndLineNumber()
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function copyFilePathAndLineNumberForNvimOpen()
  local ret = "nvim +" .. vim.fn.getcurpos()[2] .. " " .. vim.fn.expand('%:.')
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function setFilePathAndLineNumber()
  local ret = getFilePathAndLineNumber()
  vim.fn.setreg("+", ret)
  vim.cmd('silent !tmux setenv -g CURRENT_BREAKPOINT ' .. ret)
  print(string.format("Set $CURRENT_BREAKPOINT to %s.", ret))
end
local function getCurrentTest()
  vim.fn.feedkeys(':mark x\r?TEST_\rf(l"cywf,w"vyw`x', "x")
  vim.cmd("noh")
  return (vim.fn.getreg("c") .. "." .. vim.fn.getreg("v"))
end

local function setCurrentTest()
  local ret = getCurrentTest()
  vim.cmd('silent !tmux setenv CURRENT_TEST ' .. ret)
  print(string.format("Set $CURRENT_TEST to %s.", ret))
end

local function copyCurrentTest()
  local ret = getCurrentTest()
  vim.fn.setreg("+", ret)
  vim.cmd('normal! zz')
  print(string.format("Copied %s to clipboard.", ret))
end

vim.keymap.set("n", "<leader>sb", setFilePathAndLineNumber, { desc = "Set line number and file path" })
vim.keymap.set("n", "<leader>st", setCurrentTest, { desc = "Set test name" })
vim.keymap.set("n", "<leader>cb", copyFilePathAndLineNumber, { desc = "Copy line number and file path" })
vim.keymap.set("n", "<leader>cf", copyFilePath, { desc = "Copy file path" })
vim.keymap.set("n", "<leader>ct", copyCurrentTest, { desc = "Copy test name" })
vim.keymap.set("n", "<leader>cn", copyLineNumber, { desc = "Copy line number" })
vim.keymap.set("n", "<leader>cv", copyFilePathAndLineNumberForNvimOpen, { desc = "Copy command to open nvim here" })

-- Github Copilot settings
vim.g.copilot_no_tab_map = true
vim.keymap.set({ 'n', 'i' }, '<C-F7>',
  function()
      if (not GithubCopilotEnabled) then
          vim.cmd("Copilot enable")
          print("Copilot enabled")
          GithubCopilotEnabled = true
      else
          vim.cmd("Copilot disable")
          print("Copilot disabled")
          GithubCopilotEnabled = false
      end
    vim.cmd("Copilot disable")
  end, { desc = "Copilot toggle" })
vim.keymap.set('i', '<F8>', '<Plug>(copilot-suggest)', { desc = "Suggest copilot completion" })
--vim.keymap.set('i', '<F9>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false, desc = "Accept copilot completion" })
-- vim.keymap.set({'n'}, '<F7>', ':CopilotChatToggle<CR>', { desc = "Toggle Copilot Chat" })
vim.keymap.set({'n'}, '<F7>', ':CodeCompanionChat Toggle<CR>', { desc = "Toggle Copilot Chat" })
vim.keymap.set('i', '<C-F8>', '<Plug>(copilot-previous)', { desc = "Previous copilot suggestion" })
vim.keymap.set('i', '<M-F8>', '<Plug>(copilot-dismiss)', { desc = "Dismiss copilot suggestion" })
vim.keymap.set('i', '<C-F9>', '<Plug>(copilot-next)', { desc = "Next copilot suggestion" })
vim.keymap.set('i', '<M-F9>', '<Plug>(copilot-accept-word)', { desc = "Accept copilot word" })
vim.keymap.set('i', '<M-C-F9>', '<Plug>(copilot-accept-line)', { desc = "Accept copilot line" })
vim.keymap.set({'n', 'v'}, '<leader>ai', '<cmd>CodeCompanionActions <cr>', { noremap = true, silent = true, desc = "Toggle AI actions" })
vim.keymap.set({'n', 'v'}, '<leader>aa', '<cmd>CodeCompanionChat Add <cr>', { desc = "Add to AI chat" })
vim.keymap.set({'n', 'v'}, '<leader>ap', '<cmd>CodeCompanion<cr>', { desc = "Open inline AI prompt" })

-- treesitter-context (show function signature in top row)
vim.keymap.set("n", "<leader>gu", function() require("treesitter-context").go_to_context(vim.v.count1) end, { silent = true, desc = "Go to treesitter-context" })
vim.keymap.set("n", "<leader>c+", function()
        ContextMaxHeight = ContextMaxHeight + 1
        require 'treesitter-context'.setup { max_lines = ContextMaxHeight, trim_scope = 'inner' }
end, { desc = "Increase context line height" })
vim.keymap.set("n", "<leader>c/", function()
        ContextMaxHeight = ContextMaxHeight - 1
        require 'treesitter-context'.setup { max_lines = ContextMaxHeight, trim_scope = 'inner' }
end, { desc = "Increase context line height" })

-- Telescope
local pwd = .55
local phd = .8
NoIgnore = false
vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files({no_ignore = NoIgnore, layout_config={preview_width = pwd} }) end, { desc = "Find files" })
vim.keymap.set('n', '<leader>fF', function() require('telescope.builtin').find_files({no_ignore = NoIgnore, layout_config={preview_width = pwd}, fuzzy=false }) end, { desc = "Find files" })
vim.keymap.set('n', '<leader>fr', function() require('telescope.builtin').resume() end, { desc = "Resume telescope search" })
vim.keymap.set('n', '<leader>fw', function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({layout_config={preview_width = pwd}}) end, { desc = "Find word under cursor" })
vim.keymap.set('n', '<leader>fW', function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor_current_buffer({layout_strategy='vertical', layout_config={ preview_height=phd } }) end, { desc = "Find word under cursor in current buffer" })
vim.keymap.set({'n', 'v'}, '<leader>fi', function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({ postfix = "", quote = false, layout_config={preview_width = pwd} }) end, { desc = "Find word in visual selection" })
vim.keymap.set('n', '<leader>fg', function() require("telescope").extensions.live_grep_args.live_grep_args({layout_config={preview_width = pwd}}) end, { desc = "Grep files" })
vim.keymap.set('v', '<leader>fg', function() require("telescope-live-grep-args.shortcuts").grep_visual_selection({layout_config={preview_width = pwd}}) end, { desc = "Find word in visual selection" })
vim.keymap.set('v', '<leader>fG', function() require("telescope-live-grep-args.shortcuts").grep_word_visual_selection_current_buffer({layout_strategy='vertical', layout_config={preview_height= phd}}) end, { desc = "Find word in visual selection in current buffer" })
vim.keymap.set('n', '<leader>fG',
  function()
    require("telescope").extensions.live_grep_args.live_grep_args({path_display="hidden", search_dirs={"%:p"}, layout_strategy='vertical', layout_config={preview_height= phd}})
  end,
  { desc = "Grep in current buffer" })
vim.keymap.set('n', '<leader>l', function()
  -- Buffers picker without the leading buffer-number and flag (a/#a/…) columns.
  -- gen_from_buffer hardcodes a width-4 flag column, so blanking the indicator
  -- would still leave 4 blank spaces. Instead we build our own entry_maker with
  -- a displayer that has only icon + filename columns.
  local entry_display = require('telescope.pickers.entry_display')
  local utils = require('telescope.utils')
  local Path = require('plenary.path')

  local cwd = utils.path_expand(vim.uv.cwd())
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 2 },        -- devicon
      { remaining = true }, -- filename
    },
  })

  local function make_display(entry)
    -- Reserve room for everything that isn't the path so "truncate" accounts for
    -- the trailing ":lnum" (otherwise the line number gets appended after
    -- truncation and overflows the column). __prefix mirrors gen_from_buffer:
    -- icon (2) + separator (1) + ":" (1) + the lnum's digit count.
    local opts = { path_display = { 'truncate' } }
    opts.__prefix = 2 + 1 + 1 + #tostring(entry.lnum)
    local display_bufname = utils.transform_path(opts, entry.filename)
    display_bufname = display_bufname .. ':' .. entry.lnum
    local icon, hl_group = utils.get_devicons(entry.filename)
    return displayer({
      { icon, hl_group },
      { display_bufname, function() return {} end },
    })
  end

  local function entry_maker(buf)
    local filename = buf.info.name ~= '' and buf.info.name or nil
    local bufname = filename and Path:new(filename):normalize(cwd) or '[No Name]'
    local lnum = 0
    if buf.info.lnum ~= 0 then
      if vim.api.nvim_buf_is_loaded(buf.bufnr) then
        local line_count = vim.api.nvim_buf_line_count(buf.bufnr)
        lnum = math.max(math.min(buf.info.lnum, line_count), 1)
      else
        lnum = buf.info.lnum
      end
    end
    return require('telescope.make_entry').set_default_entry_mt({
      value = bufname,
      ordinal = buf.bufnr .. ' : ' .. bufname,
      display = make_display,
      bufnr = buf.bufnr,
      path = filename,
      filename = bufname,
      lnum = lnum,
    }, {})
  end

  require('telescope.builtin').buffers({ sort_mru = true, entry_maker = entry_maker })
end, { desc = "Find in buffers" })
vim.keymap.set('n', '<leader>fl', function() require('telescope.builtin').oldfiles({layout_config={preview_width = pwd}}) end, { desc = "Previously opened files" })
vim.keymap.set('n', '<leader>fh', function() require('telescope.builtin').help_tags() end, { desc = "Find help" })
vim.keymap.set('n', '<leader>fc',
  function()
    require("telescope.builtin").current_buffer_fuzzy_find({ fuzzy = true, case_mode = "ignore_case", layout_strategy='vertical', layout_config={preview_height= phd}})
  end,
  { desc = "Find in current buffer" })

-- Persistent most-recently-used store: maps absolute path -> { time, lnum }
-- (last-open epoch and the cursor line we left the file on). Backs the ordering
-- of <leader>fv (by time) and its preview scroll position (lnum), surviving
-- nvim restarts. Older versions stored a bare epoch number per path; ts()/lnum
-- lookups below tolerate that shape so existing data keeps working.
local fv_mru_path = vim.fn.stdpath("data") .. "/fv_mru.json"
local fv_mru = {}
do
  local ok, data = pcall(function()
    local f = io.open(fv_mru_path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    if content == "" then return {} end
    return vim.json.decode(content)
  end)
  if ok and type(data) == "table" then
    fv_mru = data
  end
end

local fv_mru_write_pending = false
local function fv_mru_flush()
  fv_mru_write_pending = false
  local ok, encoded = pcall(vim.json.encode, fv_mru)
  if not ok then return end
  local f = io.open(fv_mru_path, "w")
  if not f then return end
  f:write(encoded)
  f:close()
end

local function fv_mru_schedule_flush()
  if not fv_mru_write_pending then
    fv_mru_write_pending = true
    vim.defer_fn(fv_mru_flush, 2000)
  end
end

-- Stamp a file's open time on enter, and its cursor line on leave (BufLeave
-- captures where we actually stopped, not where we landed). Debounce the disk
-- write so rapid buffer hopping doesn't thrash the file.
local function fv_mru_trackable(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" then
    return nil
  end
  if vim.fn.filereadable(name) ~= 1 then
    return nil
  end
  return vim.fn.fnamemodify(name, ":p")
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("fv_mru", { clear = true }),
  callback = function(args)
    local path = fv_mru_trackable(args.buf)
    if not path then return end
    local entry = fv_mru[path]
    if type(entry) ~= "table" then
      -- migrate old bare-epoch entries (or absent) to the { time, lnum } shape
      entry = {}
      fv_mru[path] = entry
    end
    entry.time = os.time()
    fv_mru_schedule_flush()
  end,
})
vim.api.nvim_create_autocmd("BufLeave", {
  group = "fv_mru",
  callback = function(args)
    local path = fv_mru_trackable(args.buf)
    if not path then return end
    local entry = fv_mru[path]
    if type(entry) ~= "table" then
      entry = {}
      fv_mru[path] = entry
    end
    entry.lnum = vim.api.nvim_win_get_cursor(0)[1]
    fv_mru_schedule_flush()
  end,
})
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = "fv_mru",
  callback = fv_mru_flush,
})

-- Files changed since the fork point from master/main (committed + uncommitted)
local function telescopeChangedSinceFork()
  local base_branch = nil
  for _, branch in ipairs({ "main", "master" }) do
    if vim.fn.system("git rev-parse --verify --quiet " .. branch) ~= "" then
      base_branch = branch
      break
    end
  end
  if not base_branch then
    print("No master or main branch found")
    return
  end

  -- Fork point: where the current branch diverged from master/main
  local fork_point = vim.trim(vim.fn.system("git merge-base " .. base_branch .. " HEAD"))
  if vim.v.shell_error ~= 0 or fork_point == "" then
    print("Could not determine fork point from " .. base_branch)
    return
  end

  local seen = {}
  local files = {}
  local function collect(cmd)
    for _, line in ipairs(vim.fn.systemlist(cmd)) do
      if line ~= "" and not seen[line] then
        seen[line] = true
        table.insert(files, line)
      end
    end
  end

  -- Committed changes since the fork point, plus anything currently modified
  -- (staged or not) and untracked files. --diff-filter=d drops deletions so we
  -- never list a path that no longer exists on disk (was previously a per-file
  -- filereadable() stat loop; git filters it for free).
  collect("git diff --name-only --diff-filter=d " .. fork_point .. " HEAD")
  collect("git diff --name-only --diff-filter=d HEAD")
  collect("git ls-files --others --exclude-standard")

  if #files == 0 then
    print("No files changed since fork from " .. base_branch)
    return
  end

  -- Order by most-recently-used using the persistent fv_mru store (epoch of
  -- last open, survives restarts): larger timestamp = more recent. Files never
  -- opened have no timestamp and fall back to git's original order, after all
  -- files that do have one.
  local orig = {}
  for i, f in ipairs(files) do
    orig[f] = i
  end
  -- fv_mru entries are { time, lnum }; tolerate the old bare-epoch shape too.
  local function mru(f)
    return fv_mru[vim.fn.fnamemodify(f, ":p")]
  end
  local function ts(f)
    local e = mru(f)
    if type(e) == "table" then return e.time end
    return e -- old bare-number entry, or nil
  end
  table.sort(files, function(a, b)
    local ta, tb = ts(a), ts(b)
    if ta and tb then
      if ta ~= tb then
        return ta > tb
      end
      return orig[a] < orig[b]
    elseif ta then
      return true
    elseif tb then
      return false
    end
    return orig[a] < orig[b]
  end)

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local previewers = require("telescope.previewers")
  local from_entry = require("telescope.from_entry")
  local conf = require("telescope.config").values

  -- Previewer that scrolls to the last cursor line we left the file on (from the
  -- fv_mru store) instead of the top of the file, so the preview matches where
  -- the buffer will open. We can't read the shada `"` mark here: it's only
  -- restored on a real :edit, and the preview maker reads raw lines into a
  -- scratch buffer — so fv_mru's own recorded lnum is the source of truth.
  local last_pos_previewer = previewers.new_buffer_previewer({
    title = "Preview",
    get_buffer_by_name = function(_, entry)
      return from_entry.path(entry, false)
    end,
    define_preview = function(self, entry)
      local path = from_entry.path(entry, false)
      local e = fv_mru[vim.fn.fnamemodify(path, ":p")]
      local lnum = type(e) == "table" and e.lnum or nil
      conf.buffer_previewer_maker(path, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          if lnum and lnum > 0 and lnum <= vim.api.nvim_buf_line_count(bufnr) then
            pcall(vim.api.nvim_win_set_cursor, self.state.winid, { lnum, 0 })
            -- center the last-position line in the preview window
            vim.api.nvim_win_call(self.state.winid, function()
              vim.cmd("normal! zz")
            end)
          end
        end,
      })
    end,
  })

  pickers.new({}, {
    prompt_title = "Changed since fork from " .. base_branch,
    -- gen_from_file gives the same devicon + filetype highlight entries that
    -- builtin.find_files / buffers use, so <leader>fv matches <leader>l's look.
    -- path_display = "truncate" matches <leader>ff: long paths get elided with
    -- a leading "..." rather than overflowing.
    finder = finders.new_table({
      results = files,
      entry_maker = make_entry.gen_from_file({ cwd = vim.loop.cwd(), path_display = { "truncate" } }),
    }),
    sorter = conf.generic_sorter({}),
    previewer = last_pos_previewer,
    layout_config = { preview_width = pwd },
  }):find()
end
vim.keymap.set('n', '<leader>fv', telescopeChangedSinceFork, { desc = "Find files changed since fork from master/main" })

-- Restore the last cursor position when opening a file (shada `"` mark), so
-- fv/fl/gf/:e all land where you left off — like switching to a live buffer.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_last_position", { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "gitcommit" or ft == "gitrebase" then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- undoTree
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })

function RunAsyncCommand(command)
    vim.system(
        { "sh", "-c",
            command },
        nil,
        function(obj)
            print("\n\n" ..
            "<Return code: " .. obj.code .. ">\n" ..
            "<Signal: " .. obj.signal .. ">\n"    ..
            "<Stderr>\n" .. obj.stderr .. "\n"    ..
            "<Stdout>\n" .. obj.stdout .. "\n"      )
        end)
    print("\n\n" .. "Running: " .. command)
end

-- fugitive (git)
local function gitForkDiff(excludes)
  local base = vim.trim(vim.fn.system("git merge-base HEAD origin/HEAD"))
  if vim.v.shell_error ~= 0 or base == "" then
    vim.notify(
      "Could not determine fork point (is origin/HEAD set? try: git remote set-head origin --auto)",
      vim.log.levels.ERROR)
    return
  end
  local cmd = "tab Git diff " .. base .. " -- ."
  for _, pat in ipairs(excludes) do
    cmd = cmd .. " ':(exclude)" .. pat .. "'"
  end
  vim.cmd(cmd)
end
vim.keymap.set("n", "<leader>gd", function() gitForkDiff({ "*generated*", "*test*" }) end, { desc = "Git diff against fork point (excludes generated + test)" })
vim.keymap.set("n", "<leader>gD", function() gitForkDiff({ "*generated*" }) end, { desc = "Git diff against fork point (excludes generated only)" })

-- From inside a `:Git diff <base> ...` buffer (e.g. the one <leader>gd opens),
-- open the file under the cursor in a NEW TAB as a Gvdiffsplit against the SAME
-- base the current diff is against, landing the cursor on the line the diff
-- cursor is on. Unlike fugitive's `O` (which just opens the working-tree file),
-- this reproduces the two-pane diff view for that one file.
--
-- base      <- FugitiveResult().args, i.e. the revision this diff buffer was
--              produced against (not recomputed), so it tracks whatever the
--              diff is actually comparing to.
-- file/line <- parsed from the unified-diff text around the cursor: the nearest
--              `+++ b/<path>` header above, and the new-file line number from
--              the nearest `@@ ... +start,count @@` hunk header counted down to
--              the cursor (skipping removed `-` lines, which don't exist in the
--              new file).
local function gitDiffOpenSplitInTab()
  local result = vim.fn.FugitiveResult(vim.fn.bufnr(""))
  local base
  if type(result) == "table" and type(result.args) == "table" then
    for i, a in ipairs(result.args) do
      -- first non-flag token after `diff` is the base revision
      if a == "diff" and result.args[i + 1] and result.args[i + 1]:sub(1, 1) ~= "-" then
        base = result.args[i + 1]
        break
      end
    end
  end
  if not base or base == "" then
    -- fall back to the fork point if we couldn't read the diff's own base
    base = vim.trim(vim.fn.system("git merge-base HEAD origin/HEAD"))
    if vim.v.shell_error ~= 0 or base == "" then
      vim.notify("Could not determine the diff's base revision", vim.log.levels.ERROR)
      return
    end
  end

  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, cur, false)

  -- Pass 1: find the new-file line number. Walk up to the nearest `@@` hunk
  -- header, counting new-file content lines (everything except removed `-`
  -- lines and the structural header lines) between it and the cursor.
  local target_line
  local hunk_idx
  local offset = 0
  for i = #lines, 1, -1 do
    local l = lines[i]
    local start = l:match("^@@ %-%d+,?%d* %+(%d+)")
    if start then
      target_line = tonumber(start) + offset
      hunk_idx = i
      break
    end
    local c = l:sub(1, 1)
    if c ~= "-" and not l:match("^%+%+%+") and not l:match("^%-%-%-") and not l:match("^diff ") then
      offset = offset + 1
    end
  end
  -- offset counts the cursor line itself as one step past the hunk start, so the
  -- new-file line is one less than start+offset.
  if target_line then target_line = math.max(target_line - 1, 1) end

  -- Pass 2: find the new-side path from the `+++ b/<path>` header above the hunk
  -- (fall back to `diff --git a/… b/<path>` if +++ is absent, e.g. new files).
  local file
  for i = (hunk_idx or #lines), 1, -1 do
    local l = lines[i]
    local p = l:match('^%+%+%+ "b/(.*)"$') or l:match("^%+%+%+ b/(.*)")
    if p then file = p break end
    p = l:match("^diff %-%-git a/.* b/(.*)$")
    if p then file = p break end
  end

  if not file then
    vim.notify("Not on a diff hunk (no file header above cursor)", vim.log.levels.WARN)
    return
  end

  vim.cmd("tabedit " .. vim.fn.fnameescape(file))
  vim.cmd("Gvdiffsplit " .. base)
  -- Gvdiffsplit opens the base (old) revision in a left vertical split and
  -- leaves the cursor there; move focus to the right pane (the working-tree
  -- file) before positioning the cursor.
  vim.cmd("wincmd l")
  if target_line then
    pcall(vim.api.nvim_win_set_cursor, 0, { target_line, 0 })
    vim.cmd("normal! zz")
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "FugitivePager",
  callback = function(args)
    vim.keymap.set("n", "<leader>go", gitDiffOpenSplitInTab, {
      buffer = args.buf,
      silent = true,
      desc = "Open file under cursor as Gvdiffsplit vs the diff's base in a new tab",
    })
  end,
})

vim.keymap.set("n", "<leader>gv", ":tab Gvdiffsplit<CR>", { desc = "Git open three-way split in new tab" })
vim.keymap.set("n", "<leader>gh", ":tab Gvdiffsplit origin/HEAD<CR>", { desc = "Git open three-way split against origin/HEAD in new tab" })
vim.keymap.set("n", "<leader>gs", ":! git add . && git commit --amend --no-edit --allow-empty && git push $BUILDMACHINE -f<CR>", { desc = "Git sync ammended commit with build machine" })
vim.keymap.set("n", "<leader>gm", function() RunAsyncCommand("git add . && git commit --amend --no-edit --allow-empty && git push $BUILDMACHINE -f && tmux send-keys -t 1 ENTER \"cdsrc && git switch $(git rev-parse --abbrev-ref HEAD) && cdgen && $(cat ~/build)\" ENTER") end, { desc = "Git sync and make on build machine" })

--vim.keymap.set("n", "<leader>gm", function() vim.system({ "sh", "-c", "tmux send-keys -t 1 \"cdsrc && git switch $(git rev-parse --abbrev-ref HEAD) && cdgen && $(cat ~/build)\" ENTER" } ) end, { desc = "git sync and make on buildmachine " })
vim.keymap.set("n", "<leader>gM", ":!tmux send-keys -t 1 \"$(cat ~/build)\" ENTER<CR>", { desc = "Git make on buildmachine" })
vim.keymap.set("n", "<leader>ga", ":silent Git commit -a --amend --allow-empty<CR>", { desc = "Git ammend commit message" })
vim.keymap.set("n", "<leader>gc", ":silent Git commit -a --allow-empty<CR><CR>", { desc = "Git create new commit" })
vim.keymap.set("n", "<leader>gb", ":0,3Git blame<CR>", { desc = "Git blame current line" })
vim.api.nvim_create_autocmd("User", {
    pattern = "FugitiveIndex",
    callback = function(args)
        vim.keymap.set("n", "dt", ":Gtabedit <Plug><cfile><Bar>Gvdiffsplit!<CR>", {
            buffer = args.buf,
            remap = true, -- needed so <Plug> mappings can expand
            silent = true,
        })
    end,
})

vim.keymap.set("n", "<leader>rs",
function()
    local absPath = vim.api.nvim_buf_get_name(0)
    RunAsyncCommand("rsync -vP " .. absPath .. " $USER@$BUILDMACHINE:" .. absPath)
end, { desc = "rsync to build machine" })
--vim.keymap.set("n", "<leader>gT", function()
    --    local handle = io.popen("git diff --name-only @{u}...HEAD 2>/dev/null")
    --    if not handle then
    --        print("Error: Could not execute git command")
    --        return
    --    end
    --    local result = handle:read("*a")
    --    handle:close()
    --    -- Split the result into lines and filter out empty ones
    --    local filenames = {}
    --    for filename in result:gmatch("[^\r\n]+") do
    --        if filename ~= "" and vim.fn.filereadable(filename) == 1 then
    --            table.insert(filenames, filename)
    --        end
    --    end
    --    -- Open each file in a new tab
    --    for _, filename in ipairs(filenames) do
    --        vim.cmd("tabnew " .. vim.fn.fnameescape(filename))
    --        vim.cmd("Gvdiffsplit @{u}...HEAD")
    --    end
    --    if #filenames == 0 then
    --        print("No modified files found or files are not readable")
    --    else
    --        print("Opened " .. #filenames .. " files in new tabs")
    --    end
    --end, { desc = "Open Git diff split on all changed files" })


-- QoL for remote work

-- building, copying
vim.keymap.set("n", "<leader>eb", ":tabnew ~/build<CR>", { desc = "edit build command" })
vim.keymap.set("n", "<leader>ec", ":tabnew ~/copy<CR>", { desc = "edit copy command" })

-- cinnamon (centered scrolling)
-- vim.keymap.set({ "n", "v" }, "<C-u>", function() require("cinnamon").scroll("<C-u>zz") end)
-- vim.keymap.set({ "n", "v" }, "<C-d>", function() require("cinnamon").scroll("<C-d>zz") end)
-- vim.keymap.set({ "n", "v" }, "<C-f>", function() require("cinnamon").scroll("<C-f>zz") end)
-- vim.keymap.set({ "n", "v" }, "<C-b>", function() require("cinnamon").scroll("zz<C-b>") end)
-- vim.keymap.set({ "n", "v" }, "zz", function() require("cinnamon").scroll("zz") end)
-- vim.keymap.set({ "n", "v" }, "<C-e>", function() require("cinnamon").scroll("<C-e>") end)
-- vim.keymap.set({ "n", "v" }, "<C-y>", function() require("cinnamon").scroll("<C-y>") end)

-- arrow (quick navigation)
-- mm is defined in init
vim.keymap.set({ "n", "v" }, "mn", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
vim.keymap.set({ "n", "v" }, "mN", "<cmd>BookmarksDesc<cr>", { desc = "Add description to bookmark under cursor." })
vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGotoVertical<cr>", { desc = "Go to bookmark at current active BookmarkList" })
vim.keymap.set({ "n", "v" }, "mi", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })


-- easy navigation to often used files
vim.keymap.set({ "n" }, "<leader>`r", ":e ~/.config/nvim/lua/remap.lua<CR>")
vim.keymap.set({ "n" }, "<leader>`a", ":e ~/.config/nvim/lua/after.lua<CR>")
vim.keymap.set({ "n" }, "<leader>`i", ":e ~/.config/nvim/init.lua<CR>")
