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


-- coping with a german keyboard
vim.opt.langmap = "-/_?ö[Ö{ä]Ä}"
local german_mappings = {
  ['ö'] = '[',
  ['ä'] = ']',
  ['Ö'] = '{',
  ['Ä'] = '}',
  -- Add more as needed
}
for german_char, target_char in pairs(german_mappings) do
  vim.keymap.set('n', 'f' .. german_char, 'f' .. target_char, { desc = "Find next " .. target_char })
  vim.keymap.set('n', 'F' .. german_char, 'F' .. target_char, { desc = "Find previous " .. target_char })
  vim.keymap.set('n', 't' .. german_char, 't' .. target_char, { desc = "Go before next " .. target_char })
  vim.keymap.set('n', 'T' .. german_char, 'T' .. target_char, { desc = "Go after previous " .. target_char })
end

vim.keymap.set({ "i" }, "ö", "[")
vim.keymap.set({ "i" }, "ä", "]")
vim.keymap.set({ "i" }, "Ö", "{")
vim.keymap.set({ "i" }, "Ä", "}")
vim.keymap.set({ "i" }, "ß", "\\")
vim.keymap.set({ "n" }, "<leader>ö", "o{<CR>}<Esc>O")
vim.keymap.set("n", "<C-a>", "<C-]>")
vim.keymap.set("n", "öa", ":previous<CR>")
vim.keymap.set("n", "öA", ":rewind<CR>")
vim.keymap.set("n", "öb", ":bprevious<CR>")
vim.keymap.set("n", "öB", ":brewind<CR>")
vim.keymap.set("n", "öd", "<cmd>lua vim.diagnostic.jump({count=-1})<cr>", {desc = "Jump to the previous diagnostic in the current buffer"})
vim.keymap.set("n", "öD", "<cmd>lua vim.diagnostic.jump({count=-1000})<cr>", {desc = "Jump to the first diagnostic in the current buffer"})
vim.keymap.set("n", "öe", "<cmd>lua vim.diagnostic.jump({count=-1, severity=vim.diagnostic.severity.ERROR})<cr>", {desc = "Jump to the previous error in the current buffer"})
vim.keymap.set("n", "öE", "<cmd>lua vim.diagnostic.jump({count=-1000, severity=vim.diagnostic.severity.ERROR})<cr>", {desc = "Jump to the first error in the current buffer"})
vim.keymap.set("n", "öl", ":lprevious<CR>")
vim.keymap.set("n", "öL", ":lrewind<CR>")
vim.keymap.set("n", "öm", "[m", { desc = "Previous method start"})
vim.keymap.set("n", "öM", "[M", { desc = "Previous method end"})
vim.keymap.set("n", "öq", ":cprevious<CR>")
vim.keymap.set("n", "öQ", ":crewind<CR>")
vim.keymap.set("n", "ös", "[s", { desc = "Previous misspelled word"} )
vim.keymap.set("n", "öt", ":tprevious<CR>")
vim.keymap.set("n", "öT", ":trewind<CR>")
vim.keymap.set("n", "ö%", "<Plug>(MatchitNormalMultiBackward)", {desc = "Previous unmatched group"})
vim.keymap.set("x", "ö%", "<Plug>(MatchitVisualMultiBackward)")
vim.keymap.set("o", "ö%", "<Plug>(MatchitOperationMultiBackward)")
vim.keymap.set("n", "ö(", "[(")
vim.keymap.set("n", "ö<", "[<")
vim.keymap.set("n", "öÖ", "[{")
vim.keymap.set("n", "öö", "[[")
vim.keymap.set("n", "ö<C-L>", ":lpfile<CR>")
vim.keymap.set("n", "ö<C-Q>", ":cpfile<CR>")
vim.keymap.set("n", "ö<C-T>", ":ctprevious<CR>")
vim.keymap.set("n", "ö<Space>", "mzO<esc>`z", { desc = "Add empty line above cursor"})
vim.keymap.set("n", "äa", ":next<CR>")
vim.keymap.set("n", "äA", ":last<CR>")
vim.keymap.set("n", "äb", ":bnext<CR>")
vim.keymap.set("n", "äB", ":blast<CR>")
vim.keymap.set("n", "äd", "<cmd>lua vim.diagnostic.jump({count=1})<cr>", {desc = "Jump to the next diagnostic in the current buffer"})
vim.keymap.set("n", "äD", "<cmd>lua vim.diagnostic.jump({count=1000})<cr>", {desc = "Jump to the last diagnostic in the current buffer"})
vim.keymap.set("n", "äe", "<cmd>lua vim.diagnostic.jump({count=1, severity=vim.diagnostic.severity.ERROR})<cr>", {desc = "Jump to the next error in the current buffer"})
vim.keymap.set("n", "äE", "<cmd>lua vim.diagnostic.jump({count=1000, severity=vim.diagnostic.severity.ERROR})<cr>", {desc = "Jump to the last error in the current buffer"})
vim.keymap.set("n", "äl", ":lnext<CR>")
vim.keymap.set("n", "äL", ":llast<CR>")
vim.keymap.set("n", "äm", "]m", { desc = "Next method start"})
vim.keymap.set("n", "äM", "]M", { desc = "Next method end"})
vim.keymap.set("n", "äq", ":cnext<CR>")
vim.keymap.set("n", "äQ", ":clast<CR>")
vim.keymap.set("n", "äs", "]s", { desc = "Next misspelled word"} )
vim.keymap.set("n", "ät", ":tnext<CR>")
vim.keymap.set("n", "äT", ":tlast<CR>")
vim.keymap.set("n", "ä%", "<Plug>(MatchitNormalMultiForward)", {desc = "Next unmatched group"})
vim.keymap.set("x", "ä%", "<Plug>(MatchitVisualMultiForward)")
vim.keymap.set("o", "ä%", "<Plug>(MatchitOperationMultiForward)")
vim.keymap.set("n", "ä)", "])")
vim.keymap.set("n", "ä>", "]>")
vim.keymap.set("n", "äÄ", "]}")
vim.keymap.set("n", "ää", "]]")
vim.keymap.set("n", "ä<C-L>", ":lnfile<CR>")
vim.keymap.set("n", "ä<C-Q>", ":cnfile<CR>")
vim.keymap.set("n", "ä<C-T>", ":ctnext<CR>")
vim.keymap.set("n", "ä<Space>", "mzo<esc>`z", { desc = "Add empty line below cursor"})

-- general vim QoL improvments
vim.keymap.set("n", "<F1>", function() local wordUnderCursor = vim.fn.expand("<cword>"); vim.cmd("tab Man " .. wordUnderCursor) end, { desc = "Get Man page for word under cursor" })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR>")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Move next line up to current line" } )
vim.keymap.set("i", "<Tab>","<C-v><Tab>" , { desc = "Tab" })
vim.keymap.set("n", "<leader>ht", function() vim.cmd("set list!") end, { desc = "Toggle tab visibility" })
vim.keymap.set({ "n" }, "<leader>+", "<C-w>T", { desc = "Maximize current split" })
vim.keymap.set({ "n" }, "<C-w>e", ":vnew | q<CR>", { desc = "Equalize vertical splits" })
vim.keymap.set({ "n" }, "<C-w>E", ":new | q<CR>", { desc = "Equalize horizontal splits" })

-- clipboard / yank / paste
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set({"n" },       "<leader>Y", [["+Y]], { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from clipboard (after)" })
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]], { desc = "Paste from clipboard (before)" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })

-- LSP bindings
-- Default mappings since 0.11
-- grn in Normal mode maps to vim.lsp.buf.rename()
-- grr in Normal mode maps to vim.lsp.buf.references()
-- gri in Normal mode maps to vim.lsp.buf.implementation()
-- gO in Normal mode maps to vim.lsp.buf.document_symbol()
-- gra in Normal and Visual mode maps to vim.lsp.buf.code_action()
-- CTRL-S in Insert and Select mode maps to vim.lsp.buf.signature_help()
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', {  desc = "Show documentation" })
vim.keymap.set('n', '<leader>gn', '<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<cr>', { desc = "Go to next diagnostic" })
vim.keymap.set('n', '<leader>gp', '<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<cr>', { desc = "Go to next diagnostic" })
vim.keymap.set('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<cr>', {  desc = "Go to definition" })
vim.keymap.set('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', {  desc = "Go to declaration" })
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', {  desc = "Go to definition" })
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', {  desc = "Go to declaration" })
vim.keymap.set('n', '<leader>go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', { desc = "Type definition" })
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
vim.keymap.set('n', '<leader>o', '<cmd>lua vim.diagnostic.open_float()<cr>', { desc = "Open diagnostic" })
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
vim.keymap.set("n", "<leader>ft", require("nvim-tree.api").tree.toggle, { desc = "Open file explorer" })
vim.keymap.set("n", "<space>fe", function()
  require("telescope").extensions.file_browser.file_browser()
end, { desc = "Open file browser" })

-- My own QoL functions for copying context
local function getFilePathAndLineNumber()
  return vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
end

local function copyLineNumber()
  local ret = vim.fn.getcurpos()[2]
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
vim.keymap.set('i', '<F9>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false, desc = "Accept copilot completion" })
-- vim.keymap.set({'n'}, '<F7>', ':CopilotChatToggle<CR>', { desc = "Toggle Copilot Chat" })
vim.keymap.set({'n'}, '<F7>', ':CodeCompanionChat toggle<CR>', { desc = "Toggle Copilot Chat" })
vim.keymap.set('i', '<C-F8>', '<Plug>(copilot-previous)', { desc = "Previous copilot suggestion" })
vim.keymap.set('i', '<M-F8>', '<Plug>(copilot-dismiss)', { desc = "Dismiss copilot suggestion" })
vim.keymap.set('i', '<C-F9>', '<Plug>(copilot-next)', { desc = "Next copilot suggestion" })
vim.keymap.set('i', '<M-F9>', '<Plug>(copilot-accept-word)', { desc = "Accept copilot word" })
vim.keymap.set('i', '<M-C-F9>', '<Plug>(copilot-accept-line)', { desc = "Accept copilot line" })
vim.keymap.set({'n', 'v'}, 'ai', ':CodeCompanion ', { desc = "Toggle Inline AI command" })

-- Quick chat keybinding
vim.keymap.set('n', '<leader>ccq', function()
  local input = vim.fn.input("Quick Chat: ")
  if input ~= "" then
    require("CopilotChat").ask(input, {
      selection = require("CopilotChat.select").buffer
    })
  end
end, { desc = "CopilotChat - Quick chat" })

-- Dap settings
vim.keymap.set({ "n" }, "<leader>b", require'dap'.toggle_breakpoint, { desc = "Toggle breakpoint" })
vim.keymap.set({ "n" }, "<leader><F5>", require("dapui").toggle, { desc = "Open DAP UI" })
vim.keymap.set({ 'n', 'i' }, '<F5>', function() require('dap').continue() end, { desc = "DAP continue" })
vim.keymap.set({ 'n', 'i' }, '<F10>', function() require('dap').step_over() end, { desc = "DAP step over" })
vim.keymap.set({ 'n', 'i' }, '<C-F11>', function() require('dap').step_into() end, { desc = "DAP step into" })
vim.keymap.set({ 'n', 'i' }, '<F12>', function() require('dap').step_out() end, { desc = "DAP step out" })

-- treesitter-context (show function signature in top row)
vim.keymap.set("n", "<leader>gu", function() require("treesitter-context").go_to_context(vim.v.count1) end, { silent = true, desc = "Go to function signature" })
vim.keymap.set("n", "<leader>c+", function()
        ContextMaxHeight = ContextMaxHeight + 1
        require 'treesitter-context'.setup { max_lines = ContextMaxHeight, trim_scope = 'inner' }
end, { desc = "Increase context line height" })
vim.keymap.set("n", "<leader>c/", function()
        ContextMaxHeight = ContextMaxHeight - 1
        require 'treesitter-context'.setup { max_lines = ContextMaxHeight, trim_scope = 'inner' }
end, { desc = "Increase context line height" })

-- Telescope
local tb = require('telescope.builtin')
local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = "Find files" })
vim.keymap.set('n', '<leader>fr', tb.resume, { desc = "Resume telescope search" })
vim.keymap.set('n', '<leader>fw', live_grep_args_shortcuts.grep_word_under_cursor, { desc = "Find word under cursor" })
vim.keymap.set({'n', 'v'}, '<leader>fi', function() live_grep_args_shortcuts.grep_word_under_cursor({ postfix = "", quote = false }) end, { desc = "Find word in visual selection" })
vim.keymap.set('v', '<leader>fg', live_grep_args_shortcuts.grep_visual_selection, { desc = "Find word in visual selection" })
vim.keymap.set('n', '<leader>fW', live_grep_args_shortcuts.grep_word_under_cursor_current_buffer, { desc = "Find word under cursor in current buffer" })
vim.keymap.set('v', '<leader>fG', live_grep_args_shortcuts.grep_word_visual_selection_current_buffer, { desc = "Find word in visual selection in current buffer" })
vim.keymap.set('n', '<leader>fg', require("telescope").extensions.live_grep_args.live_grep_args, { desc = "Grep files" })
vim.keymap.set('n', '<leader>l', function() tb.buffers({ sort_mru = true }) end, { desc = "Find in buffers" })
vim.keymap.set('n', '<leader>fl', tb.oldfiles, { desc = "Previously opened files" })
vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = "Find help" })
vim.keymap.set('n', '<leader>fc',
  function()
    require("telescope.builtin").current_buffer_fuzzy_find({  fuzzy = true, case_mode = "ignore_case" })
    vim.cmd("TSEnable highlight")
  end,
  { desc = "Find in current buffer" })
vim.keymap.set('n', '<leader>fC',
  function()
    require("telescope").extensions.live_grep_args.live_grep_args({path_display="hidden", search_dirs={"%:p"}})
  end,
  { desc = "Grep in current buffer" })

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
-- vim.keymap.set("n", "<leader>gs", ":! git add . && (git diff HEAD | git commit -F -) && git push ccde<CR>", { desc = "git sync with ccde && windows" })
vim.keymap.set("n", "<leader>gs", ":! git add . && git commit --amend --no-edit --allow-empty && git push ccde -f<CR>", { desc = "git sync ammended commit with ccde" })
vim.keymap.set("n", "<leader>gm", function() RunAsyncCommand("git add . && git commit --amend --no-edit --allow-empty && git push ccde -f && tmux send-keys -t 1 ENTER \"cdsrc && git switch $(git rev-parse --abbrev-ref HEAD) && cdgen && $(cat ~/build)\" ENTER") end, { desc = "git sync and make on ccde" })
vim.keymap.set("n", "<leader>rs",
function()
    local absPath = vim.api.nvim_buf_get_name(0)
    RunAsyncCommand("rsync -vP " .. absPath .. " $USER@$BUILDMACHINE:" .. absPath)
end, { desc = "rsync to build machine" })

--vim.keymap.set("n", "<leader>gm", function() vim.system({ "sh", "-c", "tmux send-keys -t 1 \"cdsrc && git switch $(git rev-parse --abbrev-ref HEAD) && cdgen && $(cat ~/build)\" ENTER" } ) end, { desc = "git sync and make on ccde" })
vim.keymap.set("n", "<leader>gM", ":!tmux send-keys -t 1 \"$(cat ~/build)\" ENTER<CR>", { desc = "make on ccde" })
vim.keymap.set("n", "<leader>ga", ":silent Git commit -a --amend --allow-empty<CR>", { desc = "git ammend commit message" })
vim.keymap.set("n", "<leader>gc", ":silent Git commit -a --allow-empty<CR><CR>", { desc = "git create new commit" })
vim.keymap.set("n", "<leader>gb", ":0,3Git blame<CR>", { desc = "Git blame current line" })
vim.keymap.set("n", "<leader>gt", function()
    local handle = io.popen("git diff --name-only @{u}...HEAD 2>/dev/null")
    if not handle then
        print("Error: Could not execute git command")
        return
    end
    local result = handle:read("*a")
    handle:close()
    -- Split the result into lines and filter out empty ones
    local filenames = {}
    for filename in result:gmatch("[^\r\n]+") do
        if filename ~= "" and vim.fn.filereadable(filename) == 1 then
            table.insert(filenames, filename)
        end
    end
    -- Open each file in a new tab
    for _, filename in ipairs(filenames) do
        vim.cmd("tabnew " .. vim.fn.fnameescape(filename))
        vim.cmd("Gvdiffsplit @{u}...HEAD")
    end
    if #filenames == 0 then
        print("No modified files found or files are not readable")
    else
        print("Opened " .. #filenames .. " files in new tabs")
    end
end, { desc = "Open Git diff split on all changed files" })


-- QoL for remote work

-- building, copying
vim.keymap.set("n", "<leader>eb", ":tabnew ~/build<CR>", { desc = "edit build command" })
vim.keymap.set("n", "<leader>ec", ":tabnew ~/copy<CR>", { desc = "edit copy command" })

-- cinnamon (centered scrolling)
vim.keymap.set({ "n", "v" }, "<C-u>", function() require("cinnamon").scroll("<C-u>zz") end)
vim.keymap.set({ "n", "v" }, "<C-d>", function() require("cinnamon").scroll("<C-d>zz") end)
vim.keymap.set({ "n", "v" }, "<C-f>", function() require("cinnamon").scroll("<C-f>zz") end)
vim.keymap.set({ "n", "v" }, "<C-b>", function() require("cinnamon").scroll("zz<C-b>") end)
vim.keymap.set({ "n", "v" }, "zz", function() require("cinnamon").scroll("zz") end)
vim.keymap.set({ "n", "v" }, "<C-e>", function() require("cinnamon").scroll("<C-e>") end)
vim.keymap.set({ "n", "v" }, "<C-y>", function() require("cinnamon").scroll("<C-y>") end)

-- arrow (quick navigation)
vim.keymap.set({ "n" }, "<leader>m", "m" ) -- this will activate non-arrow marks
vim.keymap.set({ "n" }, "M", "," ) -- undo last jump (normally mapped to ,)
vim.keymap.set({ "n" }, "Z", "M" ) -- Go to middle of screen

-- easy navigation to often used files
vim.keymap.set({ "n" }, "<leader>`r", ":e ~/.config/nvim/lua/remap.lua<CR>")
vim.keymap.set({ "n" }, "<leader>`a", ":e ~/.config/nvim/lua/after.lua<CR>")
vim.keymap.set({ "n" }, "<leader>`i", ":e ~/.config/nvim/init.lua<CR>")
