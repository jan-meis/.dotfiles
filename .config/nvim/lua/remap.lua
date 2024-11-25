
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
  local ret = vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
  vim.fn.setreg("+", ret)
  vim.cmd('silent !tmux setenv -g CURRENT_BREAKPOINT ' .. ret)
  vim.cmd('silent !tmux send-keys -t 1 "export CURRENT_BREAKPOINT=' .. ret .. '" C-m')
  vim.cmd.print(string.format("Set %CURRENT_BREAKPOINT to %s.", ret))
end

local function openGDB()
  local ret = vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
  vim.cmd('silent !tmux new-window -dn gdb')
  vim.cmd('silent !tmux send-keys -t gdb "gdb -ex \\"break \\$CURRENT_BREAKPOINT\\" -ex run --args \\$CURRENT_TESTPROG --gtest_filter=\\$CURRENT_TEST"')
  vim.cmd('silent !tmux select-window -t gdb')
end


vim.keymap.set("n", "<leader>sb", getFilePathAndLineNumber, { desc = "Copy line number and file path" })
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

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection down" })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
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
vim.keymap.set({"n", "v", "x", "i"}, "ö",  "{")
vim.keymap.set({"n", "v", "x", "i"}, "ä",  "}")
vim.keymap.set({"n", "v", "x", "i"}, "Ö",  "[")
vim.keymap.set({"n", "v", "x", "i"}, "Ä",  "]")

-- vim.opt.langmap = "-/_?#*'#"
vim.opt.langmap = "-/_?"
