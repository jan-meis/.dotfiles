vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

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
AllowGlobalFormat = true
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
vim.opt.smartindent = true

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.breakindentopt ='shift:-2'  -- or 'sbr'
vim.opt.showbreak = '↳↳'

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.ignorecase = true
vim.opt.undofile = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.colorcolumn = "160"
vim.opt.signcolumn = 'yes'
vim.filetype.add({ extension = { gmk = "make", icp = "jsp", machine_specific = "bash" } })
vim.g.undotree_SetFocusWhenToggle = 1
require('kanagawa').setup({
  overrides = function(colors)
    return {
      NonText = { fg = '#b0b0b0' },
      CopilotSuggestion = { fg = '#7f848e', italic = true },
      ComplHint = { fg = '#7f848e', italic = true },
    }
  end,
})
vim.cmd("colorscheme kanagawa-wave")

vim.cmd("autocmd FileType help wincmd T")
vim.cmd("autocmd FileType * setlocal formatoptions-=o")
vim.cmd("set completeopt+=popup")
vim.cmd("set diffopt+=vertical")
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        local dir = vim.fn.expand("<afile>:p:h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end
    end,
})

function ClearRegisters()
    local regs = {
        '"', "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
        "x", "y", "z",
    }
    for _, r in ipairs(regs) do
        vim.fn.setreg(r, "")
    end
end

-- set cursor color and put autocmd to reset blinking cursor when leaving vim
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50"
vim.cmd(':au VimLeave * set guicursor= | call chansend(v:stderr, "\x1b[ q")')

-- set some global marks
vim.api.nvim_buf_set_mark(vim.fn.bufadd(vim.fn.expand("~/.config/nvim/init.lua")), "I", 1, 1, {})
vim.api.nvim_buf_set_mark(vim.fn.bufadd(vim.fn.expand("~/.config/nvim/lua/after.lua")), "A", 1, 1, {})
vim.api.nvim_buf_set_mark(vim.fn.bufadd(vim.fn.expand("~/.config/nvim/lua/remap.lua")), "R", 1, 1, {})

-- Defer heavy plugin setup until after the UI is visible
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
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
            if reg == "" then return "" end
            return "recording to " .. reg
        end
        -- Hard-cap the branch name so a long branch never steals room from the
        -- file path. lualine trims low-priority sections first when space runs
        -- out; capping the branch here keeps the path (section c) readable.
        local BRANCH_MAX = 20
        local function truncate_branch(name)
            if name == nil or name == "" then return name end
            if vim.fn.strchars(name) > BRANCH_MAX then
                return vim.fn.strcharpart(name, 0, BRANCH_MAX - 1) .. "…"
            end
            return name
        end

        require('lualine').setup({
            sections = {
                lualine_b = {
                    { 'branch', fmt = truncate_branch },
                    'diff',
                    'diagnostics',
                },
                -- Give the file path priority: high shorting_target keeps lualine
                -- from truncating it early, and path = 1 shows the relative path.
                lualine_c = {
                    { 'filename', path = 1, shorting_target = 0 },
                    { isRecording },
                },
                lualine_z = { "location", { selectionCount } },
            }
        })

        -- Function signature context at the top
        ContextMaxHeight = 1
        require 'treesitter-context'.setup {
            max_lines = ContextMaxHeight,
            trim_scope = 'inner'
        }
    end
})

-- Telescope configuration. Defined as a global (like Codecompanion_config) and
-- called from telescope.nvim's lazy `config` in init.lua, so telescope loads on
-- first use (a keymap require) rather than eagerly at startup. Also wires
-- mini.pick as vim.ui.select and bqf preview options, both wanted on first pick.
function Telescope_setup()
    local lga_actions = require("telescope-live-grep-args.actions")
    local actions = require("telescope.actions")
    require("telescope").setup {
        defaults = {
            layout_config = {
                width = { padding = 1 },
                height = { padding = 1 },
            },
            mappings = {
                i = {
                    ["<C-h>"] = "which_key",
                    -- replaces nvim_buf_delete with vim.cmd("bd") to avoid global marks being deleted
                    ["<c-d>"] = function(prompt_bufnr)
                        local action_state = require "telescope.actions.state"
                        local current_picker = action_state.get_current_picker(prompt_bufnr)

                        current_picker:delete_selection(function(selection)
                            local _ = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
                            local ok = pcall(function() vim.cmd("bd " .. selection.bufnr) end)

                            if ok and selection.bufnr == current_picker.original_bufnr then
                                if vim.api.nvim_win_is_valid(current_picker.original_win_id) then
                                    local jumplist = vim.fn.getjumplist(current_picker.original_win_id)[1]
                                    for i = #jumplist, 1, -1 do
                                        if jumplist[i].bufnr ~= selection.bufnr and vim.fn.bufloaded(jumplist[i].bufnr) == 1 then
                                            vim.api.nvim_win_set_buf(current_picker.original_win_id,
                                                jumplist[i].bufnr)
                                            current_picker.original_bufnr = jumplist[i].bufnr
                                            return ok
                                        end
                                    end
                                    local empty_buf = vim.api.nvim_create_buf(true, true)
                                    vim.api.nvim_win_set_buf(current_picker.original_win_id, empty_buf)
                                    current_picker.original_bufnr = empty_buf
                                    vim.api.nvim_buf_delete(selection.bufnr, { force = true })
                                    return ok
                                end

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
                auto_quoting = true,
                mappings = {
                    i = {
                        ["<C-k>"] = lga_actions.quote_prompt(),
                        ["<C-g>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                        ["<C-i>"] = lga_actions.quote_prompt({ postfix =
                        " --iglob a \z
                    --iglob b.{h}" }),
                        ["<C-Space>"] = actions.to_fuzzy_refine,
                    },
                },
            },
        },
    }
    require('telescope').load_extension('fzf')
    require('telescope').load_extension('live_grep_args')
    require('telescope').load_extension('file_browser')

    -- replace telescope ui-select with mini.pick
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
end

pcall(vim.api.nvim_clear_autocmds, { group = "FileExplorer" })
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local arg = vim.fn.argv(0)
        if #arg == 1 and vim.fn.isdirectory(vim.fn.expand(arg)) ~= 0 then
            -- telescope is lazy-loaded; force it (and its config/extensions) to
            -- load before using the file_browser extension.
            require('lazy').load({ plugins = { 'telescope.nvim' } })
            require("telescope").extensions.file_browser.file_browser()
        end
    end,
})

vim.lsp.config.make_ls = {
    cmd = {  os.getenv("GOPATH") .. "/bin/make-ls" },
    root_markers = { "Makefile", "makefile", "GNUmakefile" },
    filetypes = { 'make' },
}

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
vim.lsp.config.lua_ls = {
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
vim.lsp.config.html = {
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

vim.lsp.config.bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "bash", "sh" },
    root_markers = { ".git" },
    settings = { bashIde = { globPattern = "*@(.sh|.inc|.bash|.command)" } }
}

vim.lsp.config.yamlls= {
  cmd = { 'yaml-language-server', '--stdio' },
  before_init = function(_, config)
    local local_cmd = vim.fs.joinpath(config.root_dir or '', 'node_modules/.bin', 'yaml-language-server')
    if vim.fn.executable(local_cmd) == 1 then
      config.cmd = { local_cmd, '--stdio' }
    end
  end,
  filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab', 'yaml.helm-values' },
  root_markers = { '.git' },
  ---@type lspconfig.settings.yamlls
  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },
    -- formatting disabled by default in yaml-language-server; enable it
    yaml = {
      schemas = {
        kubernetes = "k8s-*.yaml",
        ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
        ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
        ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/**/*.{yml,yaml}",
        ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
        ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
        ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
        ["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}",
        ["https://raw.githubusercontent.com/GoogleContainerTools/skaffold/main/docs-v2/content/en/schemas/v3.json"] = "skaffold*.{yml,yaml}",
      },
      format = { enable = true }
    },
  },
}

vim.lsp.config.helm_ls= {
    cmd = { "helm_ls", "serve" },
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true
        }
      }
    },
    filetypes = { "helm", "yaml.helm-values" },
    root_markers = { "Chart.yaml" },
    settings = {
      ['helm-ls'] = {
        logLevel = "info",
        valuesFiles = {
          mainValuesFile = "values.yaml",
          lintOverlayValuesFile = "values.lint.yaml",
          additionalValuesFilesGlobPattern = "values*.yaml"
        },
        helmLint = {
          enabled = true,
          ignoredMessages = {},
        },
        yamlls = {
          enabled = true,
          enabledForFilesGlob = "*.{yaml,yml}",
          diagnosticsLimit = 50,
          showDiagnosticsDirectly = false,
          path = "yaml-language-server", -- or something like { "node", "yaml-language-server.js" }
          initTimeoutSeconds = 3,
          config = {
            schemas = {
              kubernetes = "templates/**",
            },
            completion = true,
            hover = true,
            -- any other config from https://github.com/redhat-developer/yaml-language-server#language-server-settings
          }
        }
      }
    }
}

vim.lsp.config.gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
    settings = {
        gopls = {
            semanticTokens = true,
            -- persist analysis cache across sessions
            ["build.directoryFilters"] = { "-.git", "-node_modules" },
        }
    },
}

vim.lsp.enable({ "lua_ls", "clangd", "ts_ls", "perlnavigator", "pyright", "gdscript", "gopls", "rust_analyzer",
    "html_lsp", "bashls", "make_ls", "yamlls", "helm_ls" })

-- Autocomplete (via cmp) — deferred until first insert/cmdline entry so nvim-cmp
-- does not load synchronously during startup.
local function setup_cmp()
local cmp = require('cmp')
local kind_icons = {
    Text = "",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰇽",
    Variable = "󰂡",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "󰅲",
}
cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'render-markdown' },
    },
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },
    formatting = {
        fields = { "abbr", "kind", "menu" },
        format = function(_, item)
            item.kind = kind_icons[item.kind]

            local fixed_width = false
            local content = item.abbr
            local sig = item.menu

            if fixed_width then
                vim.o.pumwidth = fixed_width
            end

            local win_width = vim.api.nvim_win_get_width(0)
            local max_content_width = fixed_width and fixed_width - 10 or math.floor(win_width * 0.25)

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
        entries = "custom"
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
        ['<C-n>'] = cmp.mapping.select_next_item({ behavior = 'select' }),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            local col = vim.fn.col('.') - 1

            if cmp.visible() then
                cmp.select_next_item(false)
            elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                fallback()
            else
                cmp.complete()
            end
        end, { 'i', 's' }),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-f>'] = cmp.mapping(function(fallback)
            if vim.snippet.active({ direction = 1 }) then
                vim.snippet.jump(1)
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<C-b>'] = cmp.mapping(function(fallback)
            if vim.snippet.active({ direction = -1 }) then
                vim.snippet.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
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
end -- setup_cmp

-- Load cmp on first insert/cmdline entry, then run the queued autocmd so cmp's
-- own InsertEnter/CmdlineEnter handlers fire for this first event too.
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
    once = true,
    callback = function()
        setup_cmp()
    end,
})

-- Copilot settings. copilot.vim is lazy-loaded on InsertEnter (see init.lua), so
-- enable/disable it — and turn on inline completion — on first insert rather than
-- at startup. This avoids spawning the copilot-language-server (a node process
-- that authenticates + connects to GitHub) before you actually type.
vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
        if GithubCopilotEnabled then
            vim.cmd("Copilot enable")
        else
            vim.cmd("Copilot disable")
        end
        vim.lsp.inline_completion.enable(true)
    end,
})


-- CodeCompanion settings
Codecompanion_config = {
    display = {
        chat = {
            icons = {
                buffer_sync_all = "󰪴 ",
                buffer_sync_diff = " ",
                chat_context = " ",
                chat_fold = " ",
                tool_pending = "  ",
                tool_in_progress = "  ",
                tool_failure = "  ",
                tool_success = "  ",
            },
            window = {
                layout = "float",
                width = 0.85,
                height = .99,
                border = "rounded",
            },
        },
    },
    interactions = {
        chat = {},
    },
    extensions = {
        spinner = {},
        history = {
            enabled = true,
            opts = {
                dir_to_save = vim.fn.stdpath("data") .. "/codecompanion_chats.json",
            }
        }
    }
}


vim.cmd("highlight Cursor gui=NONE guifg=bg guibg=#C8C093")

