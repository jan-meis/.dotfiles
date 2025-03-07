-- Github Copilot settings
vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})
vim.g.copilot_no_tab_map = true
vim.keymap.set({ 'n', 'i' }, '<F12>',
  function()
    vim.cmd("Copilot enable")
    print("Copilot enabled")
  end, { desc = "Enable Copilot" })
vim.keymap.set({ 'n', 'i' }, '<C-F12>',
  function()
    vim.cmd("Copilot disable")
    print("Copilot disabled")
  end, { desc = "Disable Copilot" })
vim.keymap.set('i', '<F8>', '<Plug>(copilot-suggest)', { desc = "Suggest copilot completion" })
vim.keymap.set('i', '<F9>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
  desc = "Accept copilot completion"
})
vim.keymap.set('i', '<C-F9>', '<Plug>(copilot-next)', { desc = "Next copilot suggestion" })
vim.keymap.set('i', '<C-F8>', '<Plug>(copilot-previous)', { desc = "Previous copilot suggestion" })
vim.keymap.set('i', '<F10>', '<Plug>(copilot-dismiss)', { desc = "Dismiss copilot suggestion" })
vim.keymap.set('i', '<M-F9>', '<Plug>(copilot-accept-word)', { desc = "Accept copilot word" })
vim.keymap.set('i', '<M-C-F9>', '<Plug>(copilot-accept-line)', { desc = "Accept copilot line" })

local function toggleQuickfix()
  local qfopen = false
  for id, w in pairs(vim.api.nvim_list_wins()) do
    if (vim.fn.win_gettype(w) == "quickfix") then
      qfopen = true
    end
  end
  if (not qfopen) then
    vim.cmd("copen 4")
  else
    vim.cmd.cclose()
  end
end

local function getCurrentTest()
  vim.fn.feedkeys('mx?TEST_\rf(l"cywf,w"vyw`x', "x")
  vim.cmd("noh")
  local ret = (vim.fn.getreg("c") .. "." .. vim.fn.getreg("v"))
  vim.cmd('silent !tmux setenv -g CURRENT_TEST ' .. ret)
  vim.cmd('silent !tmux send-keys -t 1 "export CURRENT_TEST=' .. ret .. '" C-m')
  print(string.format("Set $CURRENT_TEST to %s.", ret))
end

local function getFilePathAndLineNumber()
  return vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
end

local function copyFilePathAndLineNumber()
  local ret = getFilePathAndLineNumber()
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard", ret))
end

local function setFilePathAndLineNumber()
  local ret = getFilePathAndLineNumber()
  vim.fn.setreg("+", ret)
  vim.cmd('silent !tmux setenv -g CURRENT_BREAKPOINT ' .. ret)
  vim.cmd('silent !tmux send-keys -t 1 "export CURRENT_BREAKPOINT=' .. ret .. '" C-m')
  print(string.format("Set $CURRENT_BREAKPOINT to %s.", ret))
end

local function copyLineNumber()
  local ret = vim.fn.getcurpos()[2]
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard", ret))
end

local function openGDB()
  local ret = vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
  vim.cmd('silent !tmux new-window -dn gdb')
  vim.cmd(
    'silent !tmux send-keys -t gdb "gdb -ex \\"break \\$CURRENT_BREAKPOINT\\" -ex run --args \\$CURRENT_TESTPROG --gtest_filter=\\$CURRENT_TEST"')
  vim.cmd('silent !tmux select-window -t gdb')
end

local function get_visual()
  local _, ls, cs = unpack(vim.fn.getpos('v'))
  local _, le, ce = unpack(vim.fn.getpos('.'))
  return vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
end

local function count_visual()
  local vs = get_visual()
  local len = 0
  for _, line in ipairs(vs) do
    len = len + string.len(line)
  end
  vim.fn.setreg("l", len)
end

vim.keymap.set("i", "<Tab>","<C-v><Tab>" , { desc = "Tab" })
vim.keymap.set("n", "<leader>ht", function() vim.cmd("set list!") end, { desc = "Toggle tab visibility" })
vim.keymap.set("n", "<leader>sc", function()
	vim.cmd("! mv ~/compile_commands.json.old ~/compile_commands.json.old.tmp &&" ..
		"mv /priv/i749707/bas/CGK/src/compile_commands.json ~/compile_commands.json.old &&" ..
		"mv ~/compile_commands.json.old.tmp /priv/i749707/bas/CGK/src/compile_commands.json")
end, { desc = "Toggle tab visibility" })
vim.keymap.set("n", "<leader>c+", function()
        ContextMaxHeight = ContextMaxHeight + 1
        require 'treesitter-context'.setup { max_lines = ContextMaxHeight, trim_scope = 'inner' }
end, { desc = "Increase context line height" })
vim.keymap.set("n", "<leader>c-", function()
        ContextMaxHeight = ContextMaxHeight - 1
        require 'treesitter-context'.setup { max_lines = ContextMaxHeight, trim_scope = 'inner' }
end, { desc = "Increase context line height" })

-- Telescope
local tb = require('telescope.builtin')
local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
vim.keymap.set("n", "<leader>gc", live_grep_args_shortcuts.grep_word_under_cursor)

vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = "Find files" })
vim.keymap.set('n', '<leader>fr', tb.resume, { desc = "Resume telescope search" })

vim.keymap.set('n', '<leader>fw', live_grep_args_shortcuts.grep_word_under_cursor, { desc = "Find word under cursor" })
vim.keymap.set('v', '<leader>fg', live_grep_args_shortcuts.grep_visual_selection, { desc = "Find word in visual selection" })
vim.keymap.set('n', '<leader>fW', live_grep_args_shortcuts.grep_word_under_cursor_current_buffer, { desc = "Find word under cursor in current buffer" })
vim.keymap.set('v', '<leader>fG', live_grep_args_shortcuts.grep_word_visual_selection_current_buffer, { desc = "Find word in visual selection in current buffer" })

vim.keymap.set('n', '<leader>fg', require('telescope').extensions.live_grep_args.live_grep_args, { desc = "Grep files" })
vim.keymap.set('n', '<leader>l', function() tb.buffers({ sort_mru = true }) end, { desc = "Find in buffers" })
vim.keymap.set('n', '<leader>fl', tb.oldfiles, { desc = "Previously opened files" })
vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = "Find help" })
vim.keymap.set('n', '<leader>fc',
  function()
    require("telescope.builtin").current_buffer_fuzzy_find({ fuzzy = false, case_mode = "ignore_case" })
    vim.cmd("TSEnable highlight")
  end,
  { desc = "Find in current buffer" })


vim.keymap.set("n", "<leader>sb", setFilePathAndLineNumber, { desc = "Set line number and file path" })
vim.keymap.set("n", "<leader>cb", copyFilePathAndLineNumber, { desc = "Copy line number and file path" })
vim.keymap.set("n", "<leader>cn", copyLineNumber, { desc = "Copy line number" })
vim.keymap.set("n", "<leader>st", getCurrentTest, { desc = "Copy test name" })
vim.keymap.set("n", "<leader>db", openGDB, { desc = "open GDB in new tmux pane" })

vim.keymap.set("n", "<leader>qf", toggleQuickfix, { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>qn", vim.cmd.cnext, { desc = "Next quickfix item" })
vim.keymap.set("n", "<leader>qp", vim.cmd.cprev, { desc = "Previous quickfix item" })
vim.keymap.set("n", "<leader>ft", require("nvim-tree.api").tree.toggle, { desc = "Open file explorer" })
vim.keymap.set("n", "<space>fe", function()
  require("telescope").extensions.file_browser.file_browser()
end)
vim.keymap.set('n', '<leader><F5>', vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })


vim.keymap.set({ "n" }, "<leader>+", "<C-w>T", { desc = "Maximize current split" })

vim.keymap.set({ "n", "v" }, "<leader>zz", count_visual, { desc = "tmp" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("n", "<leader>gs", ":! git add . && git commit -m 'sync' && git push ccde<CR>",
  { desc = "sync git with ccde" })
vim.keymap.set("n", "<leader>gb", ":0,3Git blame<CR><C-w>k:q", { desc = "sync git with ld5587" })

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from clipboard (after)" })
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]], { desc = "Paste from clipboard (before)" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR>")
vim.keymap.set("n", "<leader>ö", "o{<CR>}<Esc>O")
vim.keymap.set({ "i" }, "ö", "{")
vim.keymap.set({ "i" }, "ä", "}")
vim.keymap.set({ "i" }, "Ö", "[")
vim.keymap.set({ "i" }, "Ä", "]")
vim.keymap.set({ "i" }, "ß", "\\")

-- Centered scrolling:
vim.keymap.set({ "n", "v" }, "<C-U>", function() require("cinnamon").scroll("<C-U>zz") end)
vim.keymap.set({ "n", "v" }, "<C-D>", function() require("cinnamon").scroll("<C-D>zz") end)
vim.keymap.set({ "n", "v" }, "<C-F>", function() require("cinnamon").scroll("<C-F>zz") end)
vim.keymap.set({ "n", "v" }, "<C-B>", function() require("cinnamon").scroll("<C-B>zz") end)
vim.keymap.set({ "n", "v" }, "zz", function() require("cinnamon").scroll("zz") end)
vim.keymap.set({ "n", "v" }, "<C-e>", function() require("cinnamon").scroll("<C-e>") end)
vim.keymap.set({ "n", "v" }, "<C-y>", function() require("cinnamon").scroll("<C-y>") end)

-- Harpoon
local harpoon = require("harpoon")
vim.keymap.set("n", "<leader>m", function() harpoon:list():add() end, { desc = "Add to harpoon list" })
vim.keymap.set("n", "<leader>`", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "Show harpoon list" })
vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Go to 1. harpoon list entry" })
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Go to 2. harpoon list entry" })
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Go to 3. harpoon list entry" })
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Go to 4. harpoon list entry" })
vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end, { desc = "Go to 5. harpoon list entry" })
vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end, { desc = "Go to 1. harpoon list entry" })
vim.keymap.set("n", "<leader>7", function() harpoon:list():select(7) end, { desc = "Go to 2. harpoon list entry" })
vim.keymap.set("n", "<leader>8", function() harpoon:list():select(8) end, { desc = "Go to 3. harpoon list entry" })
vim.keymap.set("n", "<leader>9", function() harpoon:list():select(9) end, { desc = "Go to 4. harpoon list entry" })
vim.keymap.set("n", "<leader>0", function() harpoon:list():select(10) end, { desc = "Go to 5. harpoon list entry" })
vim.keymap.set("n", "<leader>n", function() harpoon:list():prev() end, { desc = "Go to next harpoon list entry" })
vim.keymap.set("n", "<leader>N", function() harpoon:list():next() end, { desc = "Go to previous harpoon list entry" })

-- vim.opt.langmap = "-/_?#*'#"
vim.opt.langmap = "-/_?ö{Ö[ä}Ä]<-"
