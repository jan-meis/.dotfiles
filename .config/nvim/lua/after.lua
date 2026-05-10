-- Globals
local function generate_session_guid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end
vim.g.session_guid = vim.g.session_guid or generate_session_guid()
vim.g.session_start_time = os.date("%Y-%m-%d_%H:%M:%S", os.time())

if (os.getenv("UNDODIR") ~= nil) then
    vim.opt.undodir = os.getenv("UNDODIR") .. "/.vim/undodir"
else
    vim.opt.undodir = os.getenv("HOME") .. "/.local/nvim/undodir"
end
Mysrcpath = os.getenv("HOME") .. "/src"
Mybuildpath = os.getenv("HOME") .. "/build"
if (os.getenv("mysrcpath") ~= nil) then
    Mysrcpath = os.getenv("mysrcpath")
end
if (os.getenv("mybuildpath") ~= nil) then
    Mybuildpath = os.getenv("mybuildpath")
end
AllowGlobalFormat = false
GithubCopilotEnabled = true
vim.opt.spell = false
vim.g.netrw_altfile = 1
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 8
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.cmdheight = 0
vim.opt.expandtab = true
vim.opt.list = true
vim.opt.listchars = "tab:>-"
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.ignorecase = true
vim.opt.undofile = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.colorcolumn = "160"
vim.opt.signcolumn = 'yes'
vim.filetype.add({ extension = { gmk = "make", icp = "jsp", machine_specific = "bash" } })
--vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
vim.g.undotree_SetFocusWhenToggle = 1
vim.cmd("colorscheme kanagawa-wave")
vim.cmd("ca G tab G")
vim.cmd("autocmd FileType help wincmd T")
vim.cmd("autocmd FileType * setlocal formatoptions-=o")
vim.cmd("set completeopt+=popup")

-- set cursor color and put autocmd to reset blinking cursor when leaving vim
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50"
vim.cmd(':au VimLeave * set guicursor= | call chansend(v:stderr, "\x1b[ q")')

-- set some global marks
vim.api.nvim_buf_set_mark(vim.fn.bufadd(vim.fn.expand("~/.config/nvim/init.lua")), "I", 1, 1, {})
vim.api.nvim_buf_set_mark(vim.fn.bufadd(vim.fn.expand("~/.config/nvim/lua/after.lua")), "A", 1, 1, {})
vim.api.nvim_buf_set_mark(vim.fn.bufadd(vim.fn.expand("~/.config/nvim/lua/remap.lua")), "R", 1, 1, {})

-- Lualine statusbar settings
local statusline = require('arrow.statusline') -- for arrow.nvim in statusline
local function selectionCount()
    local isVisualMode = vim.fn.mode():find("[Vv]")
    if not isVisualMode then return "" end
    local starts = vim.fn.line("v")
    local ends = vim.fn.line(".")
    local lines = starts <= ends and ends - starts + 1 or starts - ends + 1
    return "/ " .. tostring(lines) .. "L " .. tostring(vim.fn.wordcount().visual_chars) .. "C"
end
local function isRecording()
    local reg = vim.fn.reg_recording()
    if reg == "" then return "" end -- not recording
    return "recording to " .. reg
end

local CodeCompanionStatus = require("lualine.component"):extend()

CodeCompanionStatus.processing = false
CodeCompanionStatus.spinner_index = 1

local spinner_symbols = {
  "⠋",
  "⠙",
  "⠹",
  "⠸",
  "⠼",
  "⠴",
  "⠦",
  "⠧",
  "⠇",
  "⠏",
}
local spinner_symbols_len = 10

-- Initializer
function CodeCompanionStatus:init(options)
  CodeCompanionStatus.super.init(self, options)

  local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequest*",
    group = group,
    callback = function(request)
      if request.match == "CodeCompanionRequestStarted" then
        self.processing = true
      elseif request.match == "CodeCompanionRequestFinished" then
        self.processing = false
      end
    end,
  })
end

-- Function that runs every time statusline is updated
function CodeCompanionStatus:update_status()
  if self.processing then
    self.spinner_index = (self.spinner_index % spinner_symbols_len) + 1
    return spinner_symbols[self.spinner_index]
  else
    return nil
  end
end

require('lualine').setup({
    sections = {
        lualine_c = { { 'filename', path = 1 }, { function() return statusline.text_for_statusline_with_icons() end }, { isRecording } },
        lualine_z = { "location", { selectionCount }, { CodeCompanionStatus },
        },
    }
})

-- Function signature context at the top
ContextMaxHeight = 1
require 'treesitter-context'.setup {
    max_lines = ContextMaxHeight, -- How many lines the window should span. Values <= 0 mean no limit.
    trim_scope = 'inner'
}

-- Telescope (fuzzy finder)
local lga_actions = require("telescope-live-grep-args.actions")
local actions = require("telescope.actions")
require("telescope").setup {
    defaults = {
        layout_config = {
            width = { padding = 1 }
        },
        mappings = {
            i = {
                -- map actions.which_key to <C-h> (default: <C-/>)
                -- actions.which_key shows the mappings for your picker,
                -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                ["<C-h>"] = "which_key",
                -- This replaces nvim_buf_delete with vim.cmd("bd ") to avoid global marks being deleted
                ["<c-d>"] = function(prompt_bufnr)
                    local action_state = require "telescope.actions.state"
                    local current_picker = action_state.get_current_picker(prompt_bufnr)

                    current_picker:delete_selection(function(selection)
                        local _ = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
                        local ok = pcall(function() vim.cmd("bd " .. selection.bufnr) end)

                        -- If the current buffer is deleted, switch to the previous buffer
                        -- according to bdelete behavior
                        if ok and selection.bufnr == current_picker.original_bufnr then
                            if vim.api.nvim_win_is_valid(current_picker.original_win_id) then
                                local jumplist = vim.fn.getjumplist(current_picker.original_win_id)[1]
                                for i = #jumplist, 1, -1 do
                                    if jumplist[i].bufnr ~= selection.bufnr and vim.fn.bufloaded(jumplist[i].bufnr) == 1 then
                                        vim.api.nvim_win_set_buf(current_picker.original_win_id, jumplist[i].bufnr)
                                        current_picker.original_bufnr = jumplist[i].bufnr
                                        return ok
                                    end
                                end
                                -- no more valid buffers in jumplist, create an empty buffer
                                local empty_buf = vim.api.nvim_create_buf(true, true)
                                vim.api.nvim_win_set_buf(current_picker.original_win_id, empty_buf)
                                current_picker.original_bufnr = empty_buf
                                vim.api.nvim_buf_delete(selection.bufnr, { force = true })
                                return ok
                            end

                            -- window of the selected buffer got wiped, switch to first valid window
                            local win_id = vim.fn.win_getid(1, current_picker.original_tabpage)
                            current_picker.original_win_id = win_id
                            current_picker.original_bufnr = vim.api.nvim_win_get_buf(win_id)
                        end
                        return ok
                    end)
                end,
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
                    ["<C-k>"] = lga_actions.quote_prompt(),
                    ["<C-g>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                    ["<C-i>"] = lga_actions.quote_prompt({ postfix =
                    " --iglob krn/si/ic/*.{c,cpp,h} \z
            --iglob krn/si/ic/include/*.{h} \z
            --iglob krn/si/include/{ic}*.{h} \z
            --iglob krn/ict/*.{c,cpp,h} \z
            --iglob krn/include/{ic}*.{h} \z
            --iglob base/ni/*.{c,cpp,h} \z
            --iglob include/{ni,si,ic}*.{h}" }),
                    -- freeze the current list and start a fuzzy search in the frozen list
                    ["<C-Space>"] = actions.to_fuzzy_refine,
                },
            },
        },
    },
}
require('telescope').load_extension('fzf')
require('telescope').load_extension('live_grep_args')
require('telescope').load_extension('file_browser')
--require("telescope").load_extension('ui-select')
-- replace telescop ui select with minipick because its buggy
local win_config = function()
    local height = math.floor(0.618 * vim.o.lines)
    local width = math.floor(0.618 * vim.o.columns)
    return {
        anchor = 'NW',
        height = height,
        width = width,
        row = math.floor(0.5 * (vim.o.lines - height)),
        col = math.floor(0.5 * (vim.o.columns - width)),
    }
end
require('mini.pick').setup({
    window = { config = win_config },
})
vim.ui.select = require('mini.pick').ui_select

-- Better quickfix
require('bqf.config').preview.winblend = 0
require('bqf.config').preview.win_height = 999

vim.lsp.config.clangd = {
    root_markers = { '.clangd', 'compile_commands.json' },
    filetypes = { 'c', 'cpp' },
    cmd = {
        "clangd",
        "--enable-config",
        "--fallback-style=llvm",
        "--header-insertion=never",
        "--offset-encoding=utf-16",
        "--compile-commands-dir=" .. "/home/i749707",
    }
}
vim.lsp.config.luals = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } }
        }
    }
}

vim.lsp.config.ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "typescript", "vue", },
    settings = { hostInfo = "neovim" },
}
vim.lsp.config.html_lsp = {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html", "templ" },
    init_options = {
        configurationSection = { "html", "css", "javascript" },
        embeddedLanguages = {
            css = true,
            javascript = true
        },
        provideFormatter = true
    }
}
vim.lsp.config.perlnavigator = {
    cmd = { "perlnavigator" },
    settings = {
        perlnavigator = {
            perlPath = 'perl',
            enableWarnings = true,
            perltidyProfile = '',
            perlcriticProfile = '',
            perlcriticEnabled = true,
            includePaths = { '~/perllib' },
        }
    }
}

vim.lsp.config.gdscript = {
    cmd = { "godot-wsl-lsp", "--useMirroredNetworking" },
    filetypes = { "gd", "gdscript" },
    root_markers = { ".godot" }
}

local function reload_workspace(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'rust_analyzer' }
  for _, client in ipairs(clients) do
    vim.notify 'Reloading Cargo Workspace'
    client.request('rust-analyzer/reloadWorkspace', nil, function(err)
      if err then
        error(tostring(err))
      end
      vim.notify 'Cargo workspace reloaded'
    end, 0)
  end
end
local function is_library(fname)
  local user_home = vim.fs.normalize(vim.env.HOME)
  local cargo_home = os.getenv 'CARGO_HOME' or user_home .. '/.cargo'
  local registry = cargo_home .. '/registry/src'
  local git_registry = cargo_home .. '/git/checkouts'

  local rustup_home = os.getenv 'RUSTUP_HOME' or user_home .. '/.rustup'
  local toolchains = rustup_home .. '/toolchains'

  for _, item in ipairs { toolchains, registry, git_registry } do
    if vim.fs.relpath(item, fname) then
      local clients = vim.lsp.get_clients { name = 'rust_analyzer' }
      return #clients > 0 and clients[#clients].config.root_dir or nil
    end
  end
end

vim.lsp.config.rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local reused_dir = is_library(fname)
        if reused_dir then
            on_dir(reused_dir)
            return
        end

        local cargo_crate_dir = vim.fs.root(fname, { 'Cargo.toml' })
        local cargo_workspace_root

        if cargo_crate_dir == nil then
            on_dir(
                vim.fs.root(fname, { 'rust-project.json' })
                or vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
            )
            return
        end

        local cmd = {
            'cargo',
            'metadata',
            '--no-deps',
            '--format-version',
            '1',
            '--manifest-path',
            cargo_crate_dir .. '/Cargo.toml',
        }

        vim.system(cmd, { text = true }, function(output)
            if output.code == 0 then
                if output.stdout then
                    local result = vim.json.decode(output.stdout)
                    if result['workspace_root'] then
                        cargo_workspace_root = vim.fs.normalize(result['workspace_root'])
                    end
                end

                on_dir(cargo_workspace_root or cargo_crate_dir)
            else
                vim.schedule(function()
                    vim.notify(('[rust_analyzer] cmd failed with code %d: %s\n%s'):format(output.code, cmd, output
                        .stderr))
                end)
            end
        end)
    end,
    capabilities = {
        experimental = {
            serverStatusNotification = true,
        },
    },
    before_init = function(init_params, config)
        -- See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
        if config.settings and config.settings['rust-analyzer'] then
            init_params.initializationOptions = config.settings['rust-analyzer']
        end
    end,
    on_attach = function(_, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'LspCargoReload', function()
            reload_workspace(bufnr)
        end, { desc = 'Reload current cargo workspace' })
    end,
}

vim.lsp.enable({ "luals", "clangd", "ts_ls", "perlnavigator", "pyright", "gdscript", "gopls", "rust_analyzer", "html_lsp" })

Codecompanion_config = {
  display = {
    chat = {
      -- Change the default icons
      icons = {
        buffer_sync_all = "󰪴 ",
        buffer_sync_diff = " ",
        chat_context = " ",
        chat_fold = " ",
        tool_pending = "  ",
        tool_in_progress = "  ",
        tool_failure = "  ",
        tool_success = "  ",
      },
      window = {
        layout = "float", -- float|vertical|horizontal|buffer
        width = 0.85,
        height = 1,
        border = "rounded",
      },
    },
  },
  interactions = {
    chat = {
      keymaps = {
        next_chat  = {
          modes = { n = "Ä" },
          opts = {},
        },
        previous_chat  = {
          modes = { n = "Ö" },
          opts = {},
        },
        next_header   = {
          modes = { n = "ää" },
          opts = {},
        },
        previous_header   = {
          modes = { n = "öö" },
          opts = {},
        },
        fold_code = {
          modes = { n = "gu" },
          opts = {},
        },
      },
    },
  },
}

-- smooth scrolling
require("cinnamon").setup()

-- This has to go here because some plugin overwrites it
vim.cmd("colorscheme kanagawa-wave")
vim.cmd("highlight Cursor gui=NONE guifg=bg guibg=#C8C093")
