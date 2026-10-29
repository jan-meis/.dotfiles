local helpers = require("remap_helpers")
local scope = require("treesitter_scope")
local selection = require("treesitter_selection")
local bookmarks = require("file_bookmarks")
local history = require("buffer_history")

-- General editing
vim.keymap.set("n", "<F1>", function() local word = vim.fn.expand("<cword>"); vim.cmd("tab Man " .. word) end, { desc = "Get Man page for word under cursor" })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR>")
vim.keymap.set("c", "<C-CR>", "<CR><Cmd>nohlsearch<CR>", { silent = true, desc = "Execute search and clear highlight" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Move next line up to current line" })

-- Navigate native snippet placeholders without changing COQ's completion keys.
for key, direction in pairs({ ["<C-f>"] = 1, ["<C-b>"] = -1 }) do
  vim.keymap.set({ "i", "s" }, key, function()
    if vim.snippet.active({ direction = direction }) then
      return "<Cmd>lua vim.snippet.jump(" .. direction .. ")<CR>"
    end
    return key
  end, { expr = true, silent = true, desc = direction == 1 and "Next snippet placeholder" or "Previous snippet placeholder" })
end
vim.keymap.set("n", "<leader>ht", function() vim.cmd("set list!") end, { desc = "Toggle tab visibility" })
vim.keymap.set("n", "<leader>t", "<C-w>T", { desc = "Maximize current split" })
vim.keymap.set("n", "<C-w>e", ":vnew | q<CR>", { desc = "Equalize  splits" })
vim.keymap.set("n", "<C-w>E", ":new | q<CR>", { desc = "Equalize horizontal splits" })
vim.keymap.set("n", "zj", function() helpers.navigate_fold("j") end, { noremap = true, silent = true })
vim.keymap.set("n", "zk", function() helpers.navigate_fold("k") end, { noremap = true, silent = true })
-- Include legacy terminal encodings (Ctrl-^ / Ctrl-_) and distinct modern keys.
vim.keymap.set("n", "<C-6>", function() history.step(1, vim.v.count1) end, { desc = "Older recent buffer" })
vim.keymap.set("n", "<C-^>", function() history.step(1, vim.v.count1) end, { desc = "Older recent buffer" })
vim.keymap.set("n", "<C-7>", function() history.step(-1, vim.v.count1) end, { desc = "Newer recent buffer" })
vim.keymap.set("n", "<C-_>", function() history.step(-1, vim.v.count1) end, { desc = "Newer recent buffer" })

-- Clipboard / yank / paste
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from clipboard (after)" })
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]], { desc = "Paste from clipboard (before)" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void register" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete to void register" })
--vim.keymap.set({ "n" }, "p", "p=ap", { noremap = true, silent = true })
--vim.keymap.set({ "n" }, "P", "P=ap", { noremap = true, silent = true })
--vim.keymap.set({ "x" }, "p", function() if vim.fn.mode() ~= "V" then return vim.cmd("normal! p") else return vim.cmd("normal! p=ap") end end, { noremap = true, silent = true })
--vim.keymap.set({ "x" }, "P", function() if vim.fn.mode() ~= "V" then return vim.cmd("normal! P") else return vim.cmd("normal! P=ap") end end, { noremap = true, silent = true })

-- LSP (grn/grr/gri/gra/gO and Ctrl-s are Neovim defaults)
vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", { desc = "Show documentation" })
vim.keymap.set("n", "]e", "<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<cr>", { desc = "Go to next diagnostic" })
vim.keymap.set("n", "[e", "<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<cr>", { desc = "Go to next diagnostic" })
vim.keymap.set("n", "grd", "<cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Go to definition" })
vim.keymap.set("n", "grD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { desc = "Go to declaration" })
vim.keymap.set("n", "<leader>o", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Open diagnostic" })
vim.keymap.set("i", "<F9>", function()
  if not vim.lsp.inline_completion.get() then return "<F9>" end
end, { expr = true, desc = "Accept the current inline completion" })
vim.keymap.set({ "n", "x", "v" }, "<F3>", function()
  if vim.api.nvim_get_mode().mode ~= "n" or AllowGlobalFormat then
    vim.lsp.buf.format({ async = true })
  end
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>sqf", "<cmd>lua vim.diagnostic.setqflist()<cr>", { desc = "Set quickfix list" })

-- Quickfix and location lists
vim.keymap.set("n", "<leader>q", helpers.toggle_quickfix, { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>w", helpers.toggle_location, { desc = "Toggle location list" })

-- File explorer (nvim-tree's lazy-loading keymap remains in init.lua)
vim.keymap.set("n", "<space>fe", function()
  require("telescope").extensions.file_browser.file_browser()
end, { desc = "Open file browser" })
vim.keymap.set("n", "<space>fE", function()
  local directory = vim.fn.expand("%:p:h")
  if directory == "" then directory = vim.loop.cwd() end
  require("telescope").extensions.file_browser.file_browser({ path = directory, cwd = directory })
end, { desc = "Open file browser at current file directory" })

-- Copy context / tmux
vim.keymap.set("n", "<leader>sb", helpers.set_breakpoint, { desc = "Set line number and file path" })
vim.keymap.set("n", "<leader>st", helpers.set_current_test, { desc = "Set test name" })
vim.keymap.set("n", "<leader>cb", helpers.copy_file_path_and_line, { desc = "Copy line number and file path" })
vim.keymap.set("n", "<leader>cf", helpers.copy_file_path, { desc = "Copy file path" })
vim.keymap.set("n", "<leader>ct", helpers.copy_current_test, { desc = "Copy test name" })
vim.keymap.set("n", "<leader>cn", helpers.copy_line_number, { desc = "Copy line number" })
vim.keymap.set("n", "<leader>cv", helpers.copy_nvim_command, { desc = "Copy command to open nvim here" })

-- Copilot
vim.keymap.set({ "n", "i" }, "<C-F7>", function()
  if not GithubCopilotEnabled then
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
vim.keymap.set("i", "<F8>", "<Plug>(copilot-suggest)", { desc = "Suggest copilot completion" })
--vim.keymap.set('i', '<F9>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false, desc = "Accept copilot completion" })
vim.keymap.set("i", "<C-F8>", "<Plug>(copilot-previous)", { desc = "Previous copilot suggestion" })
vim.keymap.set("i", "<M-F8>", "<Plug>(copilot-dismiss)", { desc = "Dismiss copilot suggestion" })
vim.keymap.set("i", "<C-F9>", "<Plug>(copilot-next)", { desc = "Next copilot suggestion" })
vim.keymap.set("i", "<M-F9>", "<Plug>(copilot-accept-word)", { desc = "Accept copilot word" })
vim.keymap.set("i", "<M-C-F9>", "<Plug>(copilot-accept-line)", { desc = "Accept copilot line" })

-- Tree-sitter context display
vim.keymap.set("n", "<leader>c+", function()
  ContextMaxHeight = ContextMaxHeight + 1
  require("treesitter-context").setup({ max_lines = ContextMaxHeight, trim_scope = "inner" })
end, { desc = "Increase context line height" })
vim.keymap.set("n", "<leader>c/", function()
  ContextMaxHeight = ContextMaxHeight - 1
  require("treesitter-context").setup({ max_lines = ContextMaxHeight, trim_scope = "inner" })
end, { desc = "Increase context line height" })

-- Telescope
vim.keymap.set("n", "<leader>ff", function() require("telescope.builtin").find_files({ no_ignore = NoIgnore, layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Find files" })
vim.keymap.set("v", "<leader>ff", function() require("telescope.builtin").find_files({ no_ignore = NoIgnore, default_text = helpers.visual_selection(), layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Find files (visual selection)" })
vim.keymap.set("n", "<leader>fF", function() require("telescope.builtin").find_files({ no_ignore = NoIgnore, layout_config = { preview_width = helpers.preview_width }, fuzzy = false }) end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fr", function() require("telescope.builtin").resume() end, { desc = "Resume telescope search" })
vim.keymap.set("n", "<leader>fw", function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({ layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Find word under cursor" })
vim.keymap.set("n", "<leader>fW", function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor_current_buffer({ layout_strategy = "vertical", layout_config = { preview_height = helpers.preview_height } }) end, { desc = "Find word under cursor in current buffer" })
vim.keymap.set({ "n", "v" }, "<leader>fi", function() require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({ postfix = "", quote = false, layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Find word in visual selection" })
vim.keymap.set("n", "<leader>fg", function() require("telescope").extensions.live_grep_args.live_grep_args({ layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Grep files" })
vim.keymap.set("v", "<leader>fg", function() require("telescope-live-grep-args.shortcuts").grep_visual_selection({ layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Find word in visual selection" })
vim.keymap.set("v", "<leader>fG", function() require("telescope-live-grep-args.shortcuts").grep_word_visual_selection_current_buffer({ layout_strategy = "vertical", layout_config = { preview_height = helpers.preview_height } }) end, { desc = "Find word in visual selection in current buffer" })
vim.keymap.set("n", "<leader>fG", function()
  require("telescope").extensions.live_grep_args.live_grep_args({ path_display = "hidden", search_dirs = { "%:p" }, layout_strategy = "vertical", layout_config = { preview_height = helpers.preview_height } })
end, { desc = "Grep in current buffer" })
vim.keymap.set("n", "<leader>l", helpers.buffers, { desc = "Find in buffers" })
vim.keymap.set("n", "<leader>fl", function() require("telescope.builtin").oldfiles({ layout_config = { preview_width = helpers.preview_width } }) end, { desc = "Previously opened files" })
vim.keymap.set("n", "<leader>fh", function() require("telescope.builtin").help_tags() end, { desc = "Find help" })
vim.keymap.set("n", "<leader>f?", function() require("telescope.builtin").keymaps() end, { desc = "Find keymaps" })
vim.keymap.set("n", "<leader>fc", function()
  require("telescope.builtin").current_buffer_fuzzy_find({ fuzzy = true, case_mode = "ignore_case", layout_strategy = "vertical", layout_config = { preview_height = helpers.preview_height } })
end, { desc = "Find in current buffer" })
vim.keymap.set("n", "<leader>fv", helpers.changed_since_fork, { desc = "Find files changed since fork from master/main" })

-- File bookmarks
vim.keymap.set("n", "mm", bookmarks.toggle, { desc = "Toggle file bookmark" })
vim.keymap.set("n", "mo", function() bookmarks.pick(false) end, { desc = "Open file bookmarks" })
vim.keymap.set("n", "mn", function() bookmarks.pick(true) end, { desc = "Assign bookmark numbers" })
vim.keymap.set("n", "mf", function() bookmarks.cycle(1) end, { desc = "Next bookmarked file" })
vim.keymap.set("n", "mb", function() bookmarks.cycle(-1) end, { desc = "Previous bookmarked file" })
for number = 0, 9 do
  vim.keymap.set("n", "m" .. number, function() bookmarks.jump(number) end, { desc = "Jump to bookmark " .. number })
end

-- Git / Fugitive
vim.keymap.set("n", "<leader>gd", function() helpers.fork_diff({ "*generated*", "*test*" }) end, { desc = "Git diff against fork point (excludes generated + test)" })
vim.keymap.set("n", "<leader>gD", function() helpers.fork_diff({ "*generated*" }) end, { desc = "Git diff against fork point (excludes generated only)" })
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("fugitive_keymaps", { clear = true }),
  pattern = "FugitivePager",
  callback = function(args)
    vim.keymap.set("n", "<leader>go", helpers.diff_open_split, {
      buffer = args.buf, silent = true,
      desc = "Open file under cursor as Gvdiffsplit vs the diff's base in a new tab",
    })
  end,
})
vim.api.nvim_create_autocmd("User", {
  group = "fugitive_keymaps",
  pattern = "FugitiveIndex",
  callback = function(args)
    vim.keymap.set("n", "dt", ":Gtabedit <Plug><cfile><Bar>Gvdiffsplit!<CR>", {
      buffer = args.buf, remap = true, silent = true,
    })
  end,
})
vim.keymap.set("n", "<leader>gv", ":tab Gvdiffsplit<CR>", { desc = "Git open three-way split in new tab" })
vim.keymap.set("n", "<leader>gh", ":tab Gvdiffsplit origin/HEAD<CR>", { desc = "Git open three-way split against origin/HEAD in new tab" })
vim.keymap.set("n", "<leader>gx", ":GitBlameOpenCommitURL<CR>", { desc = "Git open commit URL" })
vim.keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>", { desc = "Git blame toggle" })
vim.keymap.set({ "n", "x" }, "<leader>gl", helpers.open_github_link, { desc = "Open GitHub link for current line(s)" })
--vim.keymap.set("n", "<leader>gs", ":! git add . && git commit --amend --no-edit --allow-empty && git push $BUILDMACHINE -f<CR>", { desc = "Git sync ammended commit with build machine" })
--vim.keymap.set("n", "<leader>gm", function() RunAsyncCommand("git add . && git commit --amend --no-edit --allow-empty && git push $BUILDMACHINE -f && tmux send-keys -t 1 ENTER \"cdsrc && git switch $(git rev-parse --abbrev-ref HEAD) && cdgen && $(cat ~/build)\" ENTER") end, { desc = "Git sync and make on build machine" })
--vim.keymap.set("n", "<leader>gm", function() vim.system({ "sh", "-c", "tmux send-keys -t 1 \"cdsrc && git switch $(git rev-parse --abbrev-ref HEAD) && cdgen && $(cat ~/build)\" ENTER" } ) end, { desc = "git sync and make on buildmachine " })
--vim.keymap.set("n", "<leader>gM", ":!tmux send-keys -t 1 \"$(cat ~/build)\" ENTER<CR>", { desc = "Git make on buildmachine" })
--vim.keymap.set("n", "<leader>ga", ":silent Git commit -a --amend --allow-empty<CR>", { desc = "Git ammend commit message" })
--vim.keymap.set("n", "<leader>gc", ":silent Git commit -a --allow-empty<CR><CR>", { desc = "Git create new commit" })
--vim.keymap.set("n", "<leader>gb", ":0,3Git blame<CR>", { desc = "Git blame current line" })
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

-- Undo / remote work / configuration files
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })
vim.keymap.set("n", "<leader>rs", function()
  local path = vim.api.nvim_buf_get_name(0)
  helpers.run_async_command("rsync -vP " .. path .. " $USER@$BUILDMACHINE:" .. path)
end, { desc = "rsync to build machine" })
vim.keymap.set("n", "<leader>eb", ":tabnew ~/build<CR>", { desc = "edit build command" })
vim.keymap.set("n", "<leader>ec", ":tabnew ~/copy<CR>", { desc = "edit copy command" })
vim.keymap.set("n", "<leader>`r", ":e ~/.config/nvim/lua/remap.lua<CR>")
vim.keymap.set("n", "<leader>`a", ":e ~/.config/nvim/lua/after.lua<CR>")
vim.keymap.set("n", "<leader>`i", ":e ~/.config/nvim/init.lua<CR>")

-- Tree-sitter scope search / selection / navigation
vim.keymap.set({ "n", "x", "o" }, "<leader>t/", function() scope.search("scope", true) end, { desc = "Search within innermost treesitter scope (forward)" })
vim.keymap.set({ "n", "x", "o" }, "<leader>t?", function() scope.search("scope", false) end, { desc = "Search within innermost treesitter scope (backward)" })
vim.keymap.set({ "n", "x", "o" }, "<leader>/", function() scope.search("function", true) end, { desc = "Search within enclosing function (forward)" })
vim.keymap.set({ "n", "x", "o" }, "<leader>?", function() scope.search("function", false) end, { desc = "Search within enclosing function (backward)" })
vim.keymap.set("n", "<leader>*", function() scope.search_word(true) end, { desc = "Search word within enclosing function (forward)" })
vim.keymap.set("n", "<leader>#", function() scope.search_word(false) end, { desc = "Search word within enclosing function (backward)" })
vim.keymap.set({ "n", "x" }, "<leader>v", scope.select, { desc = "Select innermost treesitter scope" })
vim.keymap.set("n", "grs", scope.goto_signature, { desc = "Go to enclosing function signature" })
vim.keymap.set("x", "<leader>i", selection.select_inner, { desc = "Select inside current treesitter selection" })
vim.keymap.set("n", "<leader>fb", function()
  scope.fuzzy({ layout_strategy = "vertical", layout_config = { preview_height = helpers.preview_height } })
end, { desc = "Telescope fuzzy within innermost treesitter scope" })
