-- Vim options
vim.g.netrw_altfile = 1
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
if (os.getenv("UNDODIR") ~= nil) then 
  vim.opt.undodir = os.getenv("UNDODIR") .. "/.vim/undodir"
else 
  vim.opt.undodir = os.getenv("HOME") .. "/.local/nvim/undodir"
end
vim.opt.undofile = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.colorcolumn = "100"

-- vim.g.NERDTreeQuitOnOpen = 1
vim.g.undotree_SetFocusWhenToggle = 1

-- Colors
vim.cmd("colorscheme kanagawa-wave")

-- Telescope (fuzzy finder)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Grep files" })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find in buffers" })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Find help" })
require("telescope").setup {
  extensions = {
    file_browser = {
      hidden = { file_browser = true, folder_browser = true },
    },
  },
}
require("telescope").load_extension "file_browser"


-- Better quickfix
require('bqf.config').preview.winblend = 0

-- Treesitter (highlighting)
require 'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

local lsp_zero = require('lsp-zero')

-- lsp_attach is where you enable features that only work
-- if there is a language server active in the file
local lsp_attach = function(client, bufnr)
  vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', { buffer = bufnr, desc = "Show documentation" })
  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', { buffer = bufnr, desc = "Go to definition" })
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', { buffer = bufnr, desc = "Go to declaration" })
  vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>',
    { buffer = bufnr, desc = "Go to implementation" })
  vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', { buffer = bufnr, desc = "Type definition" })
  vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>',
    { buffer = bufnr, desc = "Show occurrences of this object" })
  vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { buffer = bufnr, desc = "Signature help" })
  vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', { buffer = bufnr, desc = "Rename in buffer" })
  vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>',
    { buffer = bufnr, desc = "Format buffer" })
  vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', { buffer = bufnr, desc = "Apply suggested fix" })
  vim.keymap.set('n', '<leader>o', '<cmd>lua vim.diagnostic.open_float()<cr>',
    { buffer = bufnr, desc = "Open diagnostic" })
  vim.keymap.set('n', '<leader>gn', '<cmd>lua vim.diagnostic.goto_next()<cr>',
    { buffer = bufnr, desc = "Go to next diagnostic" })
  vim.keymap.set('n', '<leader>gp', '<cmd>lua vim.diagnostic.goto_prev()<cr>',
    { buffer = bufnr, desc = "Go to previous diagnositc" })
  vim.keymap.set('n', '<leader>sqf', '<cmd>lua vim.diagnostic.setqflist()<cr>',
    { buffer = bufnr, desc = "Set quickfix list" })
end

lsp_zero.extend_lspconfig({
  sign_text = true,
  lsp_attach = lsp_attach,
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})


require('mason').setup({})
require('mason-lspconfig').setup({
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({})
    end,
  },
})

require('lspconfig').lua_ls.setup({
  on_init = function(client)
    lsp_zero.nvim_lua_settings(client, {})
  end,
})

require("lspconfig").clangd.setup {
  cmd = {
    "clangd",
    "--enable-config",
    "--fallback-style=llvm"
  }
}

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()
local kind_icons = {
  Text = "",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "",
  Field = "󰇽",
  Variable = "󰂡",
  Class = "󰠱",
  Interface = "",
  Module = "",
  Property = "󰜢",
  Unit = "",
  Value = "󰎠",
  Enum = "",
  Keyword = "󰌋",
  Snippet = "",
  Color = "󰏘",
  File = "󰈙",
  Reference = "",
  Folder = "󰉋",
  EnumMember = "",
  Constant = "󰏿",
  Struct = "",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰅲",
}
cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = "path" },
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  formatting = {
    fields = { "abbr", "kind", "menu" },
    format = function(entry, item)
      item.kind = kind_icons[item.kind]

      -- Set the fixed width of the completion menu to 60 characters.
      local fixed_width = false
      -- Set 'fixed_width' to false if not provided.
      -- fixed_width = fixed_width or false

      -- Get the completion entry text shown in the completion window.
      local content = item.abbr
      local sig = item.menu

      -- Set the fixed completion window width.
      if fixed_width then
        vim.o.pumwidth = fixed_width
      end

      -- Get the width of the current window.
      local win_width = vim.api.nvim_win_get_width(0)

      -- Set the max content width based on either: 'fixed_width'
      -- or a percentage of the window width, in this case 20%.
      -- We subtract 10 from 'fixed_width' to leave room for 'kind' fields.
      local max_content_width = fixed_width and fixed_width - 10 or math.floor(win_width * 0.2)

      -- Truncate the completion entry text if it's longer than the
      -- max content width. We subtract 3 from the max content width
      -- to account for the "..." that will be appended to it.
      if #content > max_content_width then
        item.abbr = vim.fn.strcharpart(content, 0, max_content_width - 3) .. "..."
      else
        item.abbr = content .. (" "):rep(max_content_width - #content)
      end

      if sig ~= nil then
        if #sig > max_content_width then
          item.menu = vim.fn.strcharpart(sig, 0, max_content_width - 3) .. "..."
        else
          item.menu = sig .. (" "):rep(max_content_width - #sig)
        end
      end
      return item
    end,
  },
  view = {
    entries = "custom" -- can be "custom", "wildmenu" or "native"
  },
  mapping = cmp.mapping.preset.insert({
    -- Navigate between completion items
    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = 'select' }),

    -- `Enter` key to confirm completion
    ['<CR>'] = cmp.mapping.confirm({ select = false }),

    ['<Tab>'] = cmp_action.tab_complete({ select = true }),

    -- Ctrl+Space to trigger completion menu
    ['<C-Space>'] = cmp.mapping.complete(),

    -- Navigate between snippet placeholder
    ['<C-f>'] = cmp_action.vim_snippet_jump_forward(),
    ['<C-b>'] = cmp_action.vim_snippet_jump_backward(),

    -- Scroll up and down in the completion documentation
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
  }),
  snippet = {
    expand = function(args)
      vim.snippet.expand(args.body)
    end,
  },
})
-- `/` cmdline setup.
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})
-- `:` cmdline setup.
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    {
      name = 'cmdline',
      option = {
        ignore_cmds = { 'Man', '!' }
      }
    }
  })
})

local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED

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

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<leader>n", function() harpoon:list():prev() end, { desc = "Go to next harpoon list entry" })
vim.keymap.set("n", "<leader>N", function() harpoon:list():next() end, { desc = "Go to previous harpoon list entry" })

pcall(vim.api.nvim_clear_autocmds, { group = "FileExplorer" })
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.isdirectory(vim.fn.expand(vim.fn.argv(0))) ~= 0 then
      require("telescope").extensions.file_browser.file_browser()
    end
  end,
})
