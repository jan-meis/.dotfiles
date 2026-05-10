-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
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
  { "nvim-treesitter/nvim-treesitter-context" },
  -- undo forever
  { "mbbill/undotree" },
  -- git
  { "tpope/vim-fugitive" },
  -- live grep
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-live-grep-args.nvim'
    }
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  },
  { 'nvim-telescope/telescope-ui-select.nvim' },
  { 'echasnovski/mini.nvim', version = '*' },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
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
    {
      "olimorris/codecompanion.nvim",
      version = "^18.0.0",
      opts = {
          extensions = {
              spinner = {},
          },
      },
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "franco-ruggeri/codecompanion-spinner.nvim",
      },
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
