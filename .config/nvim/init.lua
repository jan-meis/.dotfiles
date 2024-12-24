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
  -- add your plugins here
  { 'rebelot/kanagawa.nvim' },
  { "nvim-treesitter/nvim-treesitter",  build = ":TSUpdate" },
  { "mbbill/undotree" },
  { "tpope/vim-fugitive" },
  { 'VonHeikemen/lsp-zero.nvim',        branch = 'v4.x' },
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-cmdline' },
  { 'hrsh7th/cmp-path' },
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
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' },
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
  { 'kevinhwang91/nvim-bqf', ft = 'qf' },
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
  { "davvid/harpoon",        branch = "save-cursor-position", dependencies = { "nvim-lua/plenary.nvim" } },
  { "lambdalisue/vim-suda" },
  { "declancm/cinnamon.nvim" },
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
  require("machine_specific_includes")
end

if (file_exists(vim.fn.stdpath("config") .. "/lua/machine_specific_remap.lua")) then
  require("machine_specific_includes")
end

require("tmp")
