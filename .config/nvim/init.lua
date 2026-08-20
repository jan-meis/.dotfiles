-- Bootstrap lazy.nvim
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Setup lazy.nvim
Spec = {
  -- pretty colors
  { 'rebelot/kanagawa.nvim' },
  -- fast highlighting
{
  "romus204/tree-sitter-manager.nvim",
  event = "BufReadPost",
  dependencies = {}, -- tree-sitter CLI must be installed system-wide
  config = function()
    require("tree-sitter-manager").setup({
      -- Default Options
      ensure_installed = { "c", "cpp", "go" }, -- list of parsers to install at the start of a neovim session. If set to "all", install all parsers.
      -- border = nil, -- border style for the window (e.g. "rounded", "single"), if nil, use the default border style defined by 'vim.o.winborder'. See :h 'winborder' for more info.
      auto_install = true, -- if enabled, install missing parsers when editing a new file
      highlight = true, -- treesitter highlighting is enabled by default
      -- languages = {}, -- override or add new parser sources
    })
  end
},
  {
      'fei6409/log-highlight.nvim',
      event = "BufReadPost",
      config = function()
          require('log-highlight').setup {
                extension = {
                    'log',
                    'error',
                    'trc',
                    'trace',
                    'txt',
                },
                pattern = {
                    '/var/log/.*',
                    'messages%..*',
                    'dev_.*',
                },
          }
      end,
  },
  -- show what function you are in
  { "nvim-treesitter/nvim-treesitter-context", event = "BufReadPost" },
  -- undo forever
  { "mbbill/undotree", cmd = "UndotreeToggle" },
  -- git
  { "tpope/vim-fugitive", cmd = { "G", "Git", "Gvdiffsplit", "Gtabedit" } },
  { "tpope/vim-rhubarb", event = { "VeryLazy" }  },
  -- LSP auto setup. mason-lspconfig's setup() enables installed servers via
  -- vim.lsp.enable() (automatic_enable = true by default), so it must run for
  -- LSP to start automatically. Deferred to VeryLazy: this fires right after the
  -- UI becomes interactive — off the critical startup path, but with no user
  -- interaction required (unlike a cmd trigger, which needed a manual :Mason).
  {
    'williamboman/mason.nvim',
    event = "VeryLazy",
    config = function() require('mason').setup({}) end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    event = "VeryLazy",
    dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig' },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "clangd", "html", "perlnavigator", "rust_analyzer", "bashls", "gopls" },
      })
    end,
  },
  { 'neovim/nvim-lspconfig', event = { "BufReadPre", "BufNewFile" } },
  { 'lucasecdb/godot-wsl-lsp', ft = { "gd", "gdscript" } },
  -- autocomplete — all deferred to first insert/cmdline entry
  { 'hrsh7th/cmp-nvim-lsp', event = { 'InsertEnter', 'CmdlineEnter' } },
  { 'hrsh7th/nvim-cmp',     event = { 'InsertEnter', 'CmdlineEnter' } },
  { 'hrsh7th/cmp-cmdline',  event = { 'CmdlineEnter' } },
  { 'hrsh7th/cmp-path',     event = { 'InsertEnter', 'CmdlineEnter' } },
  -- live grep / fuzzy finder — lazy-loaded on first `require('telescope...')`
  -- from a keymap (lazy.nvim hooks package loaders, so requiring any telescope
  -- module loads the plugin and runs `config` below first). Extensions ride in
  -- as dependencies and are configured in `config`.
  --
  -- Note: intentionally NO `cmd = "Telescope"` here. auto-session's picker probes
  -- `vim.fn.exists(":Telescope")` and then require()s telescope; a cmd stub would
  -- make that probe succeed and force telescope to load at startup, defeating the
  -- laziness. Without the stub, the probe fails cheaply and telescope stays lazy.
  {
    'nvim-telescope/telescope.nvim',
    lazy = true,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-live-grep-args.nvim',
      'nvim-telescope/telescope-file-browser.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
      Telescope_setup()
    end,
  },
  { 'nvim-telescope/telescope-ui-select.nvim', lazy = true },
  { 'echasnovski/mini.nvim', version = '*', lazy = true },
  { 'junegunn/fzf', lazy = true },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    cmd = {
      "NvimTreeToggle",
      "NvimTreeOpen",
      "NvimTreeFocus",
      "NvimTreeFindFile",
      "NvimTreeFindFileToggle",
    },
    keys = {
      {
        "<leader>ft",
        function()
          vim.schedule(function()
            require("nvim-tree.api").tree.toggle({
              find_file = true,
              focus = true,
            })
          end)
        end,
        desc = "Open file explorer",
      },
    },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
        hijack_directories = {
          enable = false,
          auto_open = false,
        },
        update_focused_file = {
          enable = true,
          update_root = {
            enable = false,
          },
        },
        view = { adaptive_size = true },
      })
    end,
  },
  -- prettiier quickfix list
  { 'kevinhwang91/nvim-bqf', ft = 'qf' },
  -- key help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  -- better global marks
  {
      "otavioschwanck/arrow.nvim",
      event = "VeryLazy",
      dependencies = {
          { "nvim-tree/nvim-web-devicons" },
      },
      opts = {
          show_icons = true,
          leader_key = 'q', -- Recommended to be a single key
          buffer_leader_key = 'Q', -- Per Buffer Mappings
          separate_by_branch = true,
      }
  },
  {
      "heilgar/bookmarks.nvim",
      dependencies = {
          "kkharji/sqlite.lua",
          "nvim-telescope/telescope.nvim",
          "nvim-lua/plenary.nvim",
      },
      config = function()
          require("bookmarks").setup({
              -- your configuration comes here
              -- or leave empty to use defaults
              default_mappings = true,
              db_path = vim.fn.stdpath('data') .. '/bookmarks.db'
          })
          require("telescope").load_extension("bookmarks")
      end,
      cmd = {
          "BookmarkAdd",
          "BookmarkRemove",
          "Bookmarks"
      },
      keys = {
          { "<leader>ba", "<cmd>BookmarkAdd<cr>", desc = "Add Bookmark" },
          { "<leader>br", "<cmd>BookmarkRemove<cr>", desc = "Remove Bookmark" },
          { "<leader>bj", desc = "Jump to Next Bookmark" },
          { "<leader>bk", desc = "Jump to Previous Bookmark" },
          { "<leader>bl", "<cmd>Bookmarks<cr>", desc = "List Bookmarks" },
          { "<leader>bs", desc = "Switch Bookmark List" },
      },
  },

-- run :BookmarksInfo to see the running status of the plugin

  -- write with sudo
  { "lambdalisue/vim-suda", cmd = { "SudaWrite", "SudaRead" } },
  -- prettier movement animation
  -- { "declancm/cinnamon.nvim" },
  -- prttier status line
  { 'nvim-lualine/lualine.nvim', event = "VeryLazy", dependencies = { 'nvim-tree/nvim-web-devicons' } },
  {
      "qvalentin/helm-ls.nvim",
      event = "VeryLazy",
      ft = "helm",
      opts = {
          -- leave empty or see below
      },
  },
  -- save last opened file
  {
      'rmagatti/auto-session',
      lazy = false,
      ---enables autocomplete for opts
      ---@module "auto-session"
      ---@type AutoSession.Config
      opts = {
          suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
          use_git_branch = true,
          -- log_level = 'debug',
          auto_restore_enabled = vim.fn.argv(0) ~= "-",
      }
  },
  -- copilot.vim starts the copilot-language-server (a node process that
  -- authenticates + talks to GitHub). No point before you type, so defer to
  -- first InsertEnter; the enable/disable call lives in after.lua's InsertEnter
  -- handler.
  { "github/copilot.vim", event = "InsertEnter" },
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "franco-ruggeri/codecompanion-spinner.nvim",
      "ravitemer/codecompanion-history.nvim", -- history extension
      "agentclientprotocol/claude-agent-acp"
    },
    -- Loaded lazily on first :CodeCompanion* command. Config is the global
    -- Codecompanion_config, fully built by lua/after.lua +
    -- lua/machine_specific_after.lua during startup (both run long before any
    -- command can fire), so reading it here at load time is safe.
    config = function()
      require('codecompanion').setup(Codecompanion_config)
    end,
  },
  -- {
  --     'MeanderingProgrammer/render-markdown.nvim',
  --     dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  --     -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  --     -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  --     ---@module 'render-markdown'
  --     ---@type render.md.UserConfig
  --     opts = {},
  -- },
}

if (file_exists(vim.fn.stdpath("config") .. "/lua/machine_specific_includes.lua")) then
  require("machine_specific_includes")
end

require("lazy").setup({
  spec = Spec,
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = false },
})

require("after")
require("remap")

if (file_exists(vim.fn.stdpath("config") .. "/lua/machine_specific_after.lua")) then
  require("machine_specific_after")
end

if (file_exists(vim.fn.stdpath("config") .. "/lua/machine_specific_remap.lua")) then
  require("machine_specific_remap")
end
