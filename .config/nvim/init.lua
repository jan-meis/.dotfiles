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
                ensure_installed = {
                    "bash",
                    "c",
                    "cpp",
                    "diff",
                    "dockerfile",
                    "git_config",
                    "git_rebase",
                    "gitcommit",
                    "go",
                    "gotmpl",
                    "helm",
                    "javascript",
                    "json",
                    "lua",
                    "make",
                    "markdown",
                    "markdown_inline",
                    "query",
                    "tmux",
                    "typescript",
                    "vim",
                    "vimdoc",
                    "yaml",
                    "zsh",
                },
                -- border = nil, -- border style for the window (e.g. "rounded", "single"), if nil, use the default border style defined by 'vim.o.winborder'. See :h 'winborder' for more info.
                auto_install = true,                     -- if enabled, install missing parsers when editing a new file
                highlight = true,                        -- treesitter highlighting is enabled by default
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
    { "mbbill/undotree",                         cmd = "UndotreeToggle" },
    -- git
    { "tpope/vim-fugitive",                      cmd = { "G", "Git", "Gvdiffsplit", "Gtabedit", "GBrowse" } },
    { "tpope/vim-rhubarb",                       event = { "VeryLazy" } },
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
    { 'neovim/nvim-lspconfig',   event = { "BufReadPre", "BufNewFile" } },
    { 'lucasecdb/godot-wsl-lsp', ft = { "gd", "gdscript" } },
    -- COQ v2 uses Neovim 0.12's native LSP capabilities and snippet engine.
    {
        'ms-jpq/coq_nvim',
        branch = 'coq',
        event = 'InsertEnter',
        dependencies = {
            { 'ms-jpq/coq.artifacts', branch = 'artifacts' },
        },
        opts = {
            keymap = { pre_select = true },
            display = {
                icons = { mode = 'short' },
                ghost_text = { enabled = false }, -- leave inline suggestions to Copilot
                preview = {
                    positions = { east = 1, north = false, south = false, west = false },
                },
            },
        },
        config = function(_, opts)
            -- COQ's CompleteChanged handler ignores ghost_text.enabled.
            if opts.display.ghost_text.enabled == false then
                local ghost = require('coq.completions.ghost')
                ghost.show = function(ctx) ghost.clear(ctx.buf) end
            end
            require('coq').setup(opts)
            require('coq_commit').setup()
        end,
    },
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
    { 'echasnovski/mini.nvim',                   version = '*', lazy = true },
    { 'junegunn/fzf',                            lazy = true },
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
    {
        'kevinhwang91/nvim-bqf',
        ft = 'qf',
        opts = { preview = { winblend = 0, win_height = 999 } },
    },
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
                "<leader>h?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    },
    -- write with sudo
    { "lambdalisue/vim-suda",      cmd = { "SudaWrite", "SudaRead" } },
    -- prettier movement animation
    -- { "declancm/cinnamon.nvim" },
    -- prttier status line
    { 'nvim-lualine/lualine.nvim', event = "VeryLazy",               dependencies = { 'nvim-tree/nvim-web-devicons' } },
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
    { "github/copilot.vim",        event = "InsertEnter" },
    {
        "dk949/file_line.nvim",
        main = "file_line",
        opts = {},
        lazy = false,
    },
    {
        "philippdrebes/jsonpath.nvim",
        event = "VeryLazy",
        config = function()
            local jsonpath = require("jsonpath")
            jsonpath.setup()
            vim.keymap.set("n", "<leader>jp", function() jsonpath.show_json_path() end, { desc = "Show JSON Path" })
            vim.keymap.set("n", "<leader>jk", function() jsonpath.yank_json_path() end, { desc = "Yank JSON Path" })
        end,
    },
    {
        "mosheavni/yaml-companion.nvim",
        event = "VeryLazy",
        config = function()
            local cfg = require("yaml-companion").setup({
                -- Add any options here, or leave empty to use the default settings
                -- lspconfig = {
                --   settings = { ... }
                -- },
            })
            vim.keymap.set("n", "<leader>yk", function()
                local info = require("yaml-companion").get_key_at_cursor()
                if info then
                    vim.fn.setreg("+", info.key)
                    print(string.format("Copied %s to clipboard.", info.key))
                end
            end, { desc = "Copy YAML key path" })
        end,
    },
    { "olrtg/nvim-copy-deep-path", config = true,        event = "VeryLazy" },
    { 'rhysd/git-messenger.vim',   event = "VeryLazy" },
    {
        "f-person/git-blame.nvim",
        -- load the plugin at startup
        event = "VeryLazy",
        -- Because of the keys part, you will be lazy loading this plugin.
        -- The plugin will only load once one of the keys is used.
        -- If you want to load the plugin at startup, add something like event = "VeryLazy",
        -- or lazy = false. One of both options will work.
        opts = {
            -- your configuration comes here
            -- for example
            enabled = true,                                           -- if you want to enable the plugin
            highlight_group = "GitBlame",
            message_template = "    » <author>, <date>: <summary> «", -- template for the blame message, check the Message template section for more options
            date_format = "%b. %Y",                                   -- template for the date, check Date format section for more options
            virtual_text_column = 1,                                  -- virtual text start column, check Start virtual text at column section for more options
        },
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {
            highlight = {
                -- don't dim the rest of the buffer when flashing
                backdrop = false,
            },
            modes = {
                char = {
                    config = function(opts)
                        -- Flash defaults to hiding after yanks only. Hide after
                        -- any operator (dt, ct; etc.), but keep normal f/t repeats.
                        opts.autohide = opts.autohide or vim.fn.mode(true):sub(1, 2) == "no"
                        -- Keep Flash's default count/macro guard when replacing
                        -- its char-mode config callback.
                        opts.jump_labels = opts.jump_labels
                            and vim.v.count == 0
                            and vim.fn.reg_executing() == ""
                            and vim.fn.reg_recording() == ""
                    end,
                },
            },
        },
        keys = {
            { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
            { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
            { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
        },
    }
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

-- Use native bracket matching in Go; matchit's syntax filtering can skip code braces.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("GoNativeBracketMatching", { clear = true }),
    pattern = "go",
    callback = function()
        vim.keymap.set("n", "%", "%", { buffer = true, remap = false })
    end,
})

if (file_exists(vim.fn.stdpath("config") .. "/lua/machine_specific_after.lua")) then
    require("machine_specific_after")
end

if (file_exists(vim.fn.stdpath("config") .. "/lua/machine_specific_remap.lua")) then
    require("machine_specific_remap")
end
