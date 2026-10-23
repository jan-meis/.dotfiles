-- Actions used by remap.lua. Importing this module never registers keymaps.
local M = {}

-- Keep these globals available for existing commands and machine-local config.
function InsertFilename()
    local current_file_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, pos) .. current_file_name .. line:sub(pos + 1)
    vim.api.nvim_set_current_line(nline)
end

function TmuxSend(command, pane)
  vim.cmd('!tmux send-keys -t ' .. pane .. ' \"' ..  command .. '" ENTER')
end

function NavigateFold(direction)
  local cmd = "normal! " .. direction
  local view = vim.fn.winsaveview()
  local lnum = view.lnum
  local new_lnum = lnum
  local open = true

  while lnum == new_lnum or open do
    vim.cmd(cmd)
    new_lnum = vim.fn.line "."
    open = vim.fn.foldclosed(new_lnum) < 0
  end

  if open then
    vim.fn.winrestview(view)
  end
end

-- nvim-bqf (better quickfix list)
local function toggleQuickfix()
  local qfopen = false
  for _, w in pairs(vim.api.nvim_list_wins()) do
    if (vim.fn.win_gettype(w) == "quickfix") then
      qfopen = true
    end
  end
  if (not qfopen) then
    vim.cmd("copen 6")
  else
    vim.cmd.cclose()
  end
end

local function toggleLocation()
  local qfopen = false
  for _, w in pairs(vim.api.nvim_list_wins()) do
    print (vim.fn.win_gettype(w))
    if (vim.fn.win_gettype(w) == "loclist") then
      qfopen = true
    end
  end
  if (not qfopen) then
    vim.cmd("lopen 6")
  else
    vim.cmd.lclose()
  end
end

-- My own QoL functions for copying context

local function getFilePath()
  return vim.fn.expand('%:.')
end

local function getFilePathAndLineNumber()
  return vim.fn.expand('%:.') .. ":" .. vim.fn.getcurpos()[2]
end


local function copyLineNumber()
  local ret = vim.fn.getcurpos()[2]
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function copyFilePath()
  local ret = getFilePath()
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function copyFilePathAndLineNumber()
  local ret = getFilePathAndLineNumber()
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function copyFilePathAndLineNumberForNvimOpen()
  local ret = "nvim +" .. vim.fn.getcurpos()[2] .. " " .. vim.fn.expand('%:.')
  vim.fn.setreg("+", ret)
  print(string.format("Copied %s to clipboard.", ret))
end

local function setFilePathAndLineNumber()
  local ret = getFilePathAndLineNumber()
  vim.fn.setreg("+", ret)
  vim.cmd('silent !tmux setenv -g CURRENT_BREAKPOINT ' .. ret)
  print(string.format("Set $CURRENT_BREAKPOINT to %s.", ret))
end
local function getCurrentTest()
  vim.fn.feedkeys(':mark x\r?TEST_\rf(l"cywf,w"vyw`x', "x")
  vim.cmd("noh")
  return (vim.fn.getreg("c") .. "." .. vim.fn.getreg("v"))
end

local function setCurrentTest()
  local ret = getCurrentTest()
  vim.cmd('silent !tmux setenv CURRENT_TEST ' .. ret)
  print(string.format("Set $CURRENT_TEST to %s.", ret))
end

local function copyCurrentTest()
  local ret = getCurrentTest()
  vim.fn.setreg("+", ret)
  vim.cmd('normal! zz')
  print(string.format("Copied %s to clipboard.", ret))
end

-- Telescope
local pwd = .55
local phd = .8
-- Returns the current visual selection as a single-line string. Yanks it into
-- a scratch register (z) so we don't clobber the unnamed register, then
-- restores z. Multi-line selections are flattened to spaces so default_text
-- stays a valid prompt.
local function visual_selection()
  local save = vim.fn.getreg('z')
  local save_type = vim.fn.getregtype('z')
  vim.cmd('noautocmd normal! "zy')
  local sel = vim.fn.getreg('z')
  vim.fn.setreg('z', save, save_type)
  return (sel:gsub('[\r\n]+', ' '))
end

function M.buffers()
  -- Buffers picker without the leading buffer-number and flag (a/#a/…) columns.
  -- gen_from_buffer hardcodes a width-4 flag column, so blanking the indicator
  -- would still leave 4 blank spaces. Instead we build our own entry_maker with
  -- a displayer that has only icon + filename columns.
  local entry_display = require('telescope.pickers.entry_display')
  local utils = require('telescope.utils')
  local Path = require('plenary.path')

  local cwd = utils.path_expand(vim.uv.cwd())
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 2 },        -- devicon
      { remaining = true }, -- filename
    },
  })

  local function make_display(entry)
    -- Reserve room for everything that isn't the path so "truncate" accounts for
    -- the trailing ":lnum" (otherwise the line number gets appended after
    -- truncation and overflows the column). __prefix mirrors gen_from_buffer:
    -- icon (2) + separator (1) + ":" (1) + the lnum's digit count.
    local opts = { path_display = { 'truncate' } }
    opts.__prefix = 2 + 1 + 1 + #tostring(entry.lnum)
    local display_bufname = utils.transform_path(opts, entry.filename)
    display_bufname = display_bufname .. ':' .. entry.lnum
    local icon, hl_group = utils.get_devicons(entry.filename)
    return displayer({
      { icon, hl_group },
      { display_bufname, function() return {} end },
    })
  end

  local function entry_maker(buf)
    local filename = buf.info.name ~= '' and buf.info.name or nil
    local bufname = filename and Path:new(filename):normalize(cwd) or '[No Name]'
    local lnum = 0
    if buf.info.lnum ~= 0 then
      if vim.api.nvim_buf_is_loaded(buf.bufnr) then
        local line_count = vim.api.nvim_buf_line_count(buf.bufnr)
        lnum = math.max(math.min(buf.info.lnum, line_count), 1)
      else
        lnum = buf.info.lnum
      end
    end
    return require('telescope.make_entry').set_default_entry_mt({
      value = bufname,
      ordinal = buf.bufnr .. ' : ' .. bufname,
      display = make_display,
      bufnr = buf.bufnr,
      path = filename,
      filename = bufname,
      lnum = lnum,
    }, {})
  end

  require('telescope.builtin').buffers({
    sort_mru = true,
    sort_buffers = require("buffer_history").less,
    entry_maker = entry_maker,
  })
end

-- Persistent most-recently-used store: maps absolute path -> { time, lnum }
-- (last-open epoch and the cursor line we left the file on). Backs the ordering
-- of <leader>fv (by time) and its preview scroll position (lnum), surviving
-- nvim restarts. Older versions stored a bare epoch number per path; ts()/lnum
-- lookups below tolerate that shape so existing data keeps working.
local fv_mru_path = vim.fn.stdpath("data") .. "/fv_mru.json"
local fv_mru = {}
do
  local ok, data = pcall(function()
    local f = io.open(fv_mru_path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    if content == "" then return {} end
    return vim.json.decode(content)
  end)
  if ok and type(data) == "table" then
    fv_mru = data
  end
end

local fv_mru_write_pending = false
local function fv_mru_flush()
  fv_mru_write_pending = false
  local ok, encoded = pcall(vim.json.encode, fv_mru)
  if not ok then return end
  local f = io.open(fv_mru_path, "w")
  if not f then return end
  f:write(encoded)
  f:close()
end

local function fv_mru_schedule_flush()
  if not fv_mru_write_pending then
    fv_mru_write_pending = true
    vim.defer_fn(fv_mru_flush, 2000)
  end
end

-- Stamp a file's open time on enter, and its cursor line on leave (BufLeave
-- captures where we actually stopped, not where we landed). Debounce the disk
-- write so rapid buffer hopping doesn't thrash the file.
local function fv_mru_trackable(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" then
    return nil
  end
  if vim.fn.filereadable(name) ~= 1 then
    return nil
  end
  return vim.fn.fnamemodify(name, ":p")
end

local function setup_history()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("fv_mru", { clear = true }),
    callback = function(args)
      local path = fv_mru_trackable(args.buf)
      if not path then return end
      local entry = fv_mru[path]
      if type(entry) ~= "table" then
        -- migrate old bare-epoch entries (or absent) to the { time, lnum } shape
        entry = {}
        fv_mru[path] = entry
      end
      entry.time = os.time()
      fv_mru_schedule_flush()
    end,
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    group = "fv_mru",
    callback = function(args)
      local path = fv_mru_trackable(args.buf)
      if not path then return end
      local entry = fv_mru[path]
      if type(entry) ~= "table" then
        entry = {}
        fv_mru[path] = entry
      end
      entry.lnum = vim.api.nvim_win_get_cursor(0)[1]
      fv_mru_schedule_flush()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = "fv_mru",
    callback = fv_mru_flush,
  })

  require("file_bookmarks").setup({ get_mru = function(path) return fv_mru[path] end })
end

-- Files changed since the fork point from master/main (committed + uncommitted)
local function telescopeChangedSinceFork()
  local base_branch = nil
  for _, branch in ipairs({ "main", "master" }) do
    if vim.fn.system("git rev-parse --verify --quiet " .. branch) ~= "" then
      base_branch = branch
      break
    end
  end
  if not base_branch then
    print("No master or main branch found")
    return
  end

  -- Fork point: where the current branch diverged from master/main
  local fork_point = vim.trim(vim.fn.system("git merge-base " .. base_branch .. " HEAD"))
  if vim.v.shell_error ~= 0 or fork_point == "" then
    print("Could not determine fork point from " .. base_branch)
    return
  end

  local seen = {}
  local files = {}
  local function collect(cmd)
    for _, line in ipairs(vim.fn.systemlist(cmd)) do
      if line ~= "" and not seen[line] then
        seen[line] = true
        table.insert(files, line)
      end
    end
  end

  -- Committed changes since the fork point, plus anything currently modified
  -- (staged or not) and untracked files. --diff-filter=d drops deletions so we
  -- never list a path that no longer exists on disk (was previously a per-file
  -- filereadable() stat loop; git filters it for free).
  collect("git diff --name-only --diff-filter=d " .. fork_point .. " HEAD")
  collect("git diff --name-only --diff-filter=d HEAD")
  collect("git ls-files --others --exclude-standard")

  if #files == 0 then
    print("No files changed since fork from " .. base_branch)
    return
  end

  -- Order by most-recently-used using the persistent fv_mru store (epoch of
  -- last open, survives restarts): larger timestamp = more recent. Files never
  -- opened have no timestamp and fall back to git's original order, after all
  -- files that do have one.
  local orig = {}
  for i, f in ipairs(files) do
    orig[f] = i
  end
  -- fv_mru entries are { time, lnum }; tolerate the old bare-epoch shape too.
  local function mru(f)
    return fv_mru[vim.fn.fnamemodify(f, ":p")]
  end
  local function ts(f)
    local e = mru(f)
    if type(e) == "table" then return e.time end
    return e -- old bare-number entry, or nil
  end
  table.sort(files, function(a, b)
    local ta, tb = ts(a), ts(b)
    if ta and tb then
      if ta ~= tb then
        return ta > tb
      end
      return orig[a] < orig[b]
    elseif ta then
      return true
    elseif tb then
      return false
    end
    return orig[a] < orig[b]
  end)

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local previewers = require("telescope.previewers")
  local from_entry = require("telescope.from_entry")
  local conf = require("telescope.config").values

  -- Previewer that scrolls to the last cursor line we left the file on (from the
  -- fv_mru store) instead of the top of the file, so the preview matches where
  -- the buffer will open. We can't read the shada `"` mark here: it's only
  -- restored on a real :edit, and the preview maker reads raw lines into a
  -- scratch buffer — so fv_mru's own recorded lnum is the source of truth.
  local last_pos_previewer = previewers.new_buffer_previewer({
    title = "Preview",
    get_buffer_by_name = function(_, entry)
      return from_entry.path(entry, false)
    end,
    define_preview = function(self, entry)
      local path = from_entry.path(entry, false)
      local e = fv_mru[vim.fn.fnamemodify(path, ":p")]
      local lnum = type(e) == "table" and e.lnum or nil
      conf.buffer_previewer_maker(path, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          if lnum and lnum > 0 and lnum <= vim.api.nvim_buf_line_count(bufnr) then
            pcall(vim.api.nvim_win_set_cursor, self.state.winid, { lnum, 0 })
            -- center the last-position line in the preview window
            vim.api.nvim_win_call(self.state.winid, function()
              vim.cmd("normal! zz")
            end)
          end
        end,
      })
    end,
  })

  pickers.new({}, {
    prompt_title = "Changed since fork from " .. base_branch,
    -- gen_from_file gives the same devicon + filetype highlight entries that
    -- builtin.find_files / buffers use, so <leader>fv matches <leader>l's look.
    -- path_display = "truncate" matches <leader>ff: long paths get elided with
    -- a leading "..." rather than overflowing.
    finder = finders.new_table({
      results = files,
      entry_maker = make_entry.gen_from_file({ cwd = vim.loop.cwd(), path_display = { "truncate" } }),
    }),
    sorter = conf.generic_sorter({}),
    previewer = last_pos_previewer,
    layout_config = { preview_width = pwd },
  }):find()
end

-- Restore the last cursor position when opening a file (shada `"` mark), so
-- fv/fl/gf/:e all land where you left off — like switching to a live buffer.
local function setup_last_position()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("restore_last_position", { clear = true }),
    callback = function(args)
      local ft = vim.bo[args.buf].filetype
      if ft == "gitcommit" or ft == "gitrebase" then
        return
      end
      local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
      local lcount = vim.api.nvim_buf_line_count(args.buf)
      if mark[1] > 0 and mark[1] <= lcount then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })
end

function RunAsyncCommand(command)
    vim.system(
        { "sh", "-c",
            command },
        nil,
        function(obj)
            print("\n\n" ..
            "<Return code: " .. obj.code .. ">\n" ..
            "<Signal: " .. obj.signal .. ">\n"    ..
            "<Stderr>\n" .. obj.stderr .. "\n"    ..
            "<Stdout>\n" .. obj.stdout .. "\n"      )
        end)
    print("\n\n" .. "Running: " .. command)
end

-- fugitive (git)
local function gitForkDiff(excludes)
  local base = vim.trim(vim.fn.system("git merge-base HEAD origin/HEAD"))
  if vim.v.shell_error ~= 0 or base == "" then
    vim.notify(
      "Could not determine fork point (is origin/HEAD set? try: git remote set-head origin --auto)",
      vim.log.levels.ERROR)
    return
  end
  local cmd = "tab Git diff " .. base .. " -- ."
  for _, pat in ipairs(excludes) do
    cmd = cmd .. " ':(exclude)" .. pat .. "'"
  end
  vim.cmd(cmd)
end

-- From inside a `:Git diff <base> ...` buffer (e.g. the one <leader>gd opens),
-- open the file under the cursor in a NEW TAB as a Gvdiffsplit against the SAME
-- base the current diff is against, landing the cursor on the line the diff
-- cursor is on. Unlike fugitive's `O` (which just opens the working-tree file),
-- this reproduces the two-pane diff view for that one file.
--
-- base      <- FugitiveResult().args, i.e. the revision this diff buffer was
--              produced against (not recomputed), so it tracks whatever the
--              diff is actually comparing to.
-- file/line <- parsed from the unified-diff text around the cursor: the nearest
--              `+++ b/<path>` header above, and the new-file line number from
--              the nearest `@@ ... +start,count @@` hunk header counted down to
--              the cursor (skipping removed `-` lines, which don't exist in the
--              new file).
local function gitDiffOpenSplitInTab()
  local result = vim.fn.FugitiveResult(vim.fn.bufnr(""))
  local base
  if type(result) == "table" and type(result.args) == "table" then
    for i, a in ipairs(result.args) do
      -- first non-flag token after `diff` is the base revision
      if a == "diff" and result.args[i + 1] and result.args[i + 1]:sub(1, 1) ~= "-" then
        base = result.args[i + 1]
        break
      end
    end
  end
  if not base or base == "" then
    -- fall back to the fork point if we couldn't read the diff's own base
    base = vim.trim(vim.fn.system("git merge-base HEAD origin/HEAD"))
    if vim.v.shell_error ~= 0 or base == "" then
      vim.notify("Could not determine the diff's base revision", vim.log.levels.ERROR)
      return
    end
  end

  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, cur, false)

  -- Pass 1: find the new-file line number. Walk up to the nearest `@@` hunk
  -- header, counting new-file content lines (everything except removed `-`
  -- lines and the structural header lines) between it and the cursor.
  local target_line
  local hunk_idx
  local offset = 0
  for i = #lines, 1, -1 do
    local l = lines[i]
    local start = l:match("^@@ %-%d+,?%d* %+(%d+)")
    if start then
      target_line = tonumber(start) + offset
      hunk_idx = i
      break
    end
    local c = l:sub(1, 1)
    if c ~= "-" and not l:match("^%+%+%+") and not l:match("^%-%-%-") and not l:match("^diff ") then
      offset = offset + 1
    end
  end
  -- offset counts the cursor line itself as one step past the hunk start, so the
  -- new-file line is one less than start+offset.
  if target_line then target_line = math.max(target_line - 1, 1) end

  -- Pass 2: find the new-side path from the `+++ b/<path>` header above the hunk
  -- (fall back to `diff --git a/… b/<path>` if +++ is absent, e.g. new files).
  local file
  for i = (hunk_idx or #lines), 1, -1 do
    local l = lines[i]
    local p = l:match('^%+%+%+ "b/(.*)"$') or l:match("^%+%+%+ b/(.*)")
    if p then file = p break end
    p = l:match("^diff %-%-git a/.* b/(.*)$")
    if p then file = p break end
  end

  if not file then
    vim.notify("Not on a diff hunk (no file header above cursor)", vim.log.levels.WARN)
    return
  end

  vim.cmd("tabedit " .. vim.fn.fnameescape(file))
  vim.cmd("Gvdiffsplit " .. base)
  -- Gvdiffsplit opens the base (old) revision in a left vertical split and
  -- leaves the cursor there; move focus to the right pane (the working-tree
  -- file) before positioning the cursor.
  vim.cmd("wincmd l")
  if target_line then
    pcall(vim.api.nvim_win_set_cursor, 0, { target_line, 0 })
    vim.cmd("normal! zz")
  end
end

-- Open the GitHub page for the current file/line(s). Files in the Go module
-- cache (.../pkg/mod/<module>@<version>/...) are mapped to their upstream repo
-- at the matching tag/commit; anything else falls back to fugitive's :GBrowse.
local k8s_staging = {}
for _, name in ipairs({
  "api", "apiextensions-apiserver", "apimachinery", "apiserver", "cli-runtime", "client-go",
  "cloud-provider", "cluster-bootstrap", "code-generator", "component-base", "component-helpers",
  "controller-manager", "cri-api", "cri-client", "csi-translation-lib", "dynamic-resource-allocation",
  "endpointslice", "externaljwt", "kms", "kube-aggregator", "kube-controller-manager", "kube-proxy",
  "kube-scheduler", "kubectl", "kubelet", "metrics", "mount-utils", "pod-security-admission",
  "sample-apiserver", "sample-cli-plugin", "sample-controller",
}) do
  k8s_staging[name] = true
end

local simple_vanity = {
  { "^golang%.org/x/([^/]+)(.*)$", "golang" },
  { "^sigs%.k8s%.io/([^/]+)(.*)$", "kubernetes-sigs" },
  { "^go%.uber%.org/([^/]+)(.*)$", "uber-go" },
}
local fixed_vanity = {
  ["google.golang.org/grpc"] = "grpc/grpc-go",
  ["google.golang.org/protobuf"] = "protocolbuffers/protobuf-go",
  ["google.golang.org/genproto"] = "googleapis/go-genproto",
  ["google.golang.org/api"] = "googleapis/google-api-go-client",
}

local function pseudo_commit(version)
  return version:match("%d%d%d%d%d%d%d%d%d%d%d%d%d%d%-(%x%x%x%x%x%x%x%x%x%x%x%x)$")
end

-- Returns repo URL, subdirectory of the module inside the repo, and git ref.
local function resolve_go_module(mod, version)
  version = version:gsub("%+incompatible$", "")
  local commit = pseudo_commit(version)

  local name, rest = mod:match("^k8s%.io/([^/]+)(.*)$")
  if name and k8s_staging[name] then
    -- staging repos are published from kubernetes/kubernetes; v0.X.Y <-> v1.X.Y
    local ref = (not commit and version:match("^v0%.")) and ("v1." .. version:sub(4)) or "master"
    return "https://github.com/kubernetes/kubernetes", "staging/src/k8s.io/" .. name .. rest, ref
  end

  local repo, subdir
  if name then
    repo, subdir = "kubernetes/" .. name, rest
  end
  if not repo then
    local owner, r, sub = mod:match("^github%.com/([^/]+)/([^/]+)(.*)$")
    if owner then repo, subdir = owner .. "/" .. r, sub end
  end
  if not repo then
    for _, v in ipairs(simple_vanity) do
      local n, sub = mod:match(v[1])
      if n then repo, subdir = v[2] .. "/" .. n, sub break end
    end
  end
  if not repo then
    for prefix, r in pairs(fixed_vanity) do
      if mod == prefix or vim.startswith(mod, prefix .. "/") then
        repo, subdir = r, mod:sub(#prefix + 1)
        break
      end
    end
  end
  if not repo then
    -- gopkg.in/pkg.vN -> go-pkg/pkg, gopkg.in/user/pkg.vN -> user/pkg
    local user, pkg = mod:match("^gopkg%.in/([^/]+)/([^/.]+)%.v%d+$")
    if not user then
      pkg = mod:match("^gopkg%.in/([^/.]+)%.v%d+$")
      user = pkg and ("go-" .. pkg)
    end
    if user then repo, subdir = user .. "/" .. pkg, "" end
  end

  local repo_url
  if repo then
    repo_url = "https://github.com/" .. repo
  else
    -- generic fallback: ask the vanity server for its go-import meta tag
    local html = vim.fn.system({ "curl", "-sL", "--max-time", "3", "https://" .. mod .. "?go-get=1" })
    local prefix, url = html:match('<meta%s+name="go%-import"%s+content="(%S+)%s+git%s+(%S-)"')
    if not prefix then return nil end
    repo_url, subdir = url:gsub("%.git$", ""), mod:sub(#prefix + 1)
  end

  -- a trailing /vN major-version suffix is usually not a real directory
  subdir = subdir:gsub("^/", ""):gsub("/?v%d+$", "")
  local ref = commit or ((subdir ~= "" and (subdir .. "/") or "") .. version)
  return repo_url, subdir, ref
end

local function openGithubLink()
  local l1, l2 = vim.fn.line("v"), vim.fn.line(".")
  if l1 > l2 then l1, l2 = l2, l1 end
  local in_visual = vim.fn.mode():find("[vV\22]") ~= nil
  if in_visual then
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  else
    l1, l2 = l2, l2
  end

  local path = vim.api.nvim_buf_get_name(0)

  -- Go standard library: files live under $GOROOT/src, published from
  -- github.com/golang/go under src/, tagged like "go1.26.7".
  local goroot = vim.env.GOROOT or vim.fn.trim(vim.fn.system({ "go", "env", "GOROOT" }))
  if goroot ~= "" and vim.startswith(path, goroot .. "/src/") then
    local file = path:sub(#goroot + #"/src/" + 1)
    local goversion = vim.fn.trim(vim.fn.system({ "go", "env", "GOVERSION" }))
    local ref = goversion:match("^go%d") and goversion or "master"
    local url = ("https://github.com/golang/go/blob/%s/src/%s#L%d"):format(ref, file, l1)
    if l2 ~= l1 then url = url .. "-L" .. l2 end
    vim.fn.setreg("+", url)
    vim.ui.open(url)
    print("Opened (and copied) " .. url)
    return
  end

  local modcache = vim.env.GOMODCACHE or ((vim.env.GOPATH or (vim.env.HOME .. "/go")) .. "/pkg/mod")
  local mod_path = vim.startswith(path, modcache .. "/") and path:sub(#modcache + 2) or path:match("/pkg/mod/(.+)$")
  local mod, version, file
  if mod_path then
    mod, version, file = mod_path:match("^(.-)@([^/]+)/(.*)$")
  end
  if not mod then
    vim.cmd(("%d,%dGBrowse"):format(l1, l2))
    return
  end
  -- module cache escapes uppercase letters as !<lower>
  local function unescape(s) return (s:gsub("!(%l)", string.upper)) end
  mod, version, file = unescape(mod), unescape(version), unescape(file)

  local repo_url, subdir, ref = resolve_go_module(mod, version)
  if not repo_url then
    vim.notify("Could not resolve repository for " .. mod, vim.log.levels.ERROR)
    return
  end
  local url = ("%s/blob/%s/%s#L%d"):format(repo_url, ref, subdir ~= "" and (subdir .. "/" .. file) or file, l1)
  if l2 ~= l1 then url = url .. "-L" .. l2 end
  vim.fn.setreg("+", url)
  vim.ui.open(url)
  print("Opened (and copied) " .. url)
end

M.preview_width = pwd
M.preview_height = phd
M.toggle_quickfix = toggleQuickfix
M.toggle_location = toggleLocation
M.set_breakpoint = setFilePathAndLineNumber
M.set_current_test = setCurrentTest
M.copy_file_path_and_line = copyFilePathAndLineNumber
M.copy_file_path = copyFilePath
M.copy_current_test = copyCurrentTest
M.copy_line_number = copyLineNumber
M.copy_nvim_command = copyFilePathAndLineNumberForNvimOpen
M.visual_selection = visual_selection
M.changed_since_fork = telescopeChangedSinceFork
M.fork_diff = gitForkDiff
M.diff_open_split = gitDiffOpenSplitInTab
M.open_github_link = openGithubLink
M.run_async_command = RunAsyncCommand
M.navigate_fold = NavigateFold

-- Startup hooks belong to configuration setup, not keymap registration.
function M.setup()
  vim.g.copilot_no_tab_map = true
  NoIgnore = false
  setup_history()
  setup_last_position()
  require("buffer_history").setup()
end

return M
