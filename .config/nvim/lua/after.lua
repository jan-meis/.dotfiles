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
vim.opt.colorcolumn = "140"
vim.filetype.add({ extension = { gmk = "make", icp = "jsp", machine_specific = "bash" } })

vim.g.undotree_SetFocusWhenToggle = 1
vim.cmd("colorscheme kanagawa-wave")

-- Telescope (fuzzy finder)
require("telescope").setup {
  defaults = {
    layout_config = {
      width = { padding = 1 }
    } ,
    mappings = {
      i = {
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
        ["<C-h>"] = "which_key",
        ["<c-d>"] = "delete_buffer",
      }
    }
  },
  extensions = {
    file_browser = {
      hidden = { file_browser = true, folder_browser = true },
    },
    live_grep_args = {
      auto_quoting = true, -- enable/disable auto-quoting
      -- define mappings, e.g.
      mappings = {         -- extend mappings
        i = {
          ["<C-k>"] = require("telescope-live-grep-args.actions").quote_prompt(),
          ["<C-g>"] = require("telescope-live-grep-args.actions").quote_prompt({ postfix = " --iglob " }),
          ["<C-i>"] = require("telescope-live-grep-args.actions").quote_prompt({ postfix =
          " --iglob krn/si/ic/*.{c,cpp,h} \z
            --iglob krn/si/ic/include/*.{h} \z
            --iglob krn/si/include/{ic}*.{h} \z
            --iglob krn/ict/*.{c,cpp,h} \z
            --iglob krn/include/{ic}*.{h} \z
            --iglob base/ni/*.{c,cpp,h} \z
            --iglob include/{ni,si,ic}*.{h}" }),
          -- freeze the current list and start a fuzzy search in the frozen list
          ["<C-Space>"] = require("telescope-live-grep-args.actions").to_fuzzy_refine,
        },
      },
    }
  },
}

require('telescope').load_extension('fzf')
require('telescope').load_extension('live_grep_args')
require('telescope').load_extension('file_browser')

-- Better quickfix
require('bqf.config').preview.winblend = 0

-- Treesitter (highlighting)
require 'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "make", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  highlight = {
    enable = true,
    disable = function(_, buf)
      local max_filesize = 1024 * 1024 -- 1MiB
      local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = false,
  },
}

vim.api.nvim_create_autocmd({ "InsertEnter" },
  {
    pattern = "*",
    callback = function()
      if vim.api.nvim_buf_line_count(0) > 4000 then
        vim.cmd("TSDisable highlight")
      end
    end
  })

vim.api.nvim_create_autocmd({ "InsertLeave" },
  {
    pattern = "*",
    callback = function()
      if vim.api.nvim_buf_line_count(0) > 4000 then
        vim.cmd("TSEnable highlight")
      end
    end
  })

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  callback = function()
    vim.cmd("TSEnable highlight")
  end
})

pcall(vim.api.nvim_clear_autocmds, { group = "FileExplorer" })
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if #arg == 1 and vim.fn.isdirectory(vim.fn.expand(arg)) ~= 0 then
      require("telescope").extensions.file_browser.file_browser()
    end
  end,
})

AllowGlobalFormat = false

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
  vim.keymap.set({ 'n', 'x', 'v' }, '<F3>',
    function()
      if vim.api.nvim_get_mode().mode == 'n' then
        if AllowGlobalFormat then
          vim.lsp.buf.format({ async = true })
        end
      else
        vim.lsp.buf.format({ async = true })
      end
    end,
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

require('lsp-zero').extend_lspconfig({
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
    require('lsp-zero').nvim_lua_settings(client, {})
  end,
})

require("lspconfig").clangd.setup {
  cmd = {
    "clangd",
    "--enable-config",
    "--fallback-style=llvm",
    "--header-insertion=never"
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
      -- or a percentage of the window width, in this case 25%.
      -- We subtract 10 from 'fixed_width' to leave room for 'kind' fields.
      local max_content_width = fixed_width and fixed_width - 10 or math.floor(win_width * 0.25)

      -- Truncate the completion entry text if it's longer than the
      -- max content width. We subtract 3 from the max content width
      -- to account for the "..." that will be appended to it.
      if #content > max_content_width then
        item.abbr = vim.fn.strcharpart(content, 0, max_content_width - 3) .. "..."
      else
        item.abbr = content .. (" "):rep(max_content_width - #content)
      end

      local sig_mult = .8
      if sig ~= nil then
        if #sig > math.floor(max_content_width * sig_mult) then
          item.menu = vim.fn.strcharpart(sig, 0, math.floor(max_content_width * sig_mult) - 3) .. "..."
        else
          item.menu = sig .. (" "):rep(math.floor(max_content_width * sig_mult) - #sig)
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


-- project navigation
require("harpoon"):setup()
-- smooth scrolling
require("cinnamon").setup()
