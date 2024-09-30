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

vim.keymap.set("n", "<leader>qf", toggleQuickfix, { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>qn", vim.cmd.cnext, { desc = "Next quickfix item" })
vim.keymap.set("n", "<leader>qp", vim.cmd.cprev, { desc = "Previous quickfix item" })
vim.keymap.set("n", "<leader>fe", vim.cmd.NERDTreeToggle, { desc = "Open file explorer" })
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
--vim.keymap.set({"n", "v", "x", "i"}, "´",  "`")
--vim.keymap.set({"n", "v", "x", "i"}, "`",  "´")
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR>")
vim.keymap.set("n", "<leader>{", "A{<CR>}<Esc>O")
--vim.keymap.set({"n", "i"}, "<C-{>", "{<CR>}<Esc>O")

vim.opt.langmap = "-/_?#*'#"
