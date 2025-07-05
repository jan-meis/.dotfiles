-- Bootstrap lazy.nvim
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
  { "nvim-treesitter/nvim-treesitter",  build = ":TSUpdate" },
  {
      'fei6409/log-highlight.nvim',
      config = function()
          require('log-highlight').setup {
                pattern = {
                    '/var/log/.*',
                    'messages%..*',
                    'dev_.*'
                },
          }
      end,
  },
  -- show what function you are in 
  { "nvim-treesitter/nvim-treesitter-context" },
  -- undo forever
  { "mbbill/undotree" },
  -- git
  { "tpope/vim-fugitive" },
  -- LSP auto setup
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'neovim/nvim-lspconfig' },
  { 'lucasecdb/godot-wsl-lsp' },
  -- DAP (debug adapter protocol)
  { "rcarriga/nvim-dap-ui", dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"} },
  -- autocomplete
  { 'hrsh7th/cmp-nvim-lsp'},
  { 'hrsh7th/nvim-cmp'},
  { 'hrsh7th/cmp-cmdline' },
  { 'hrsh7th/cmp-path'},
  -- live grep
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-live-grep-args.nvim'
    }
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  },
  { 'junegunn/fzf' },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {
        hijack_directories = {
          enable = false,
          auto_open = false,
        },
      }
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
  -- { "davvid/harpoon",        branch = "save-cursor-position", dependencies = { "nvim-lua/plenary.nvim" } },
    {
        "otavioschwanck/arrow.nvim",
        dependencies = {
            { "nvim-tree/nvim-web-devicons" },
            -- or if using `mini.icons`
            -- { "echasnovski/mini.icons" },
        },
        opts = {
            show_icons = true,
            leader_key = ',', -- Recommended to be a single key
            buffer_leader_key = 'm', -- Per Buffer Mappings
            separate_by_branch = true,
            mappings = {
                next_item = "ä",
                prev_item = "ö"
            }
        }
    },
  -- write with sudo
  { "lambdalisue/vim-suda" },
  -- prettier movement animation
  { "declancm/cinnamon.nvim" },
  -- prttier status line
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
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
        }
    },
    { "github/copilot.vim" },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            { "github/copilot.vim" },               -- or zbirenbaum/copilot.lua
            { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
        },
        build = "make tiktoken",                    -- Only on MacOS or Linux
        opts = {
        }
    },
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

require("tmp")
