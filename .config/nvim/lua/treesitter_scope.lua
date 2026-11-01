-- Shared scope policy for search, selection and Telescope. Grammar-specific
-- aliases live here; the rest of the code only deals with nodes and line ranges.
local M = {}
local selection = require("treesitter_selection")

local function type_set(names)
  local result = {}
  for name in names:gmatch("%S+") do result[name] = true end
  return result
end

local function_types = type_set([[
  function_declaration function_definition function_expression function_item
  generator_function_declaration generator_function function anonymous_function
  method_declaration method_definition method arrow_function lambda lambda_expression closure_expression
  func_literal func_declaration class_declaration class_definition struct_item
]])
local container_types = type_set([[class_declaration class_definition struct_item]])
local scope_types = type_set([[
  block statement_block compound_statement if_statement for_statement for_in_statement
  while_statement switch_statement case_statement expression_switch_statement
  type_switch_statement select_statement do_statement try_statement catch_clause
  with_statement composite_literal literal_value table_constructor object dictionary list array
]])

-- Convert TS's exclusive end to inclusive buffer lines once, including roots
-- that end at column zero one row beyond EOF. Empty nodes aren't useful scopes.
function M.line_range(node, buf)
  local sr, sc, er, ec = node:range()
  if sr == er and sc == ec then return nil end
  local first = sr + 1
  local last = math.min(ec == 0 and er or er + 1, vim.api.nvim_buf_line_count(buf or 0))
  if last < first then return nil end
  return first, last
end

local function pick_innermost(node)
  if function_types[node:type()] or scope_types[node:type()] then return true end
  -- Retain the original fallback for grammars without explicit aliases, but
  -- count actual buffer lines rather than the parser's exclusive end row.
  local first, last = M.line_range(node)
  return first ~= nil and last > first
end

function M.find(kind)
  local pick = kind == "function"
    and function(node) return function_types[node:type()] or false end
    or pick_innermost
  local node = selection.find_scope(pick)
  if not node then return nil end
  local first, last = M.line_range(node)
  if not first then return nil end
  return { node = node, first = first, last = last, type = node:type(), bufnr = vim.api.nvim_get_current_buf() }
end

local function search_prefix(scope)
  return scope and ("\\%%>%dl\\%%<%dl\\&"):format(scope.first - 1, scope.last + 1) or ""
end

-- The line constraints live in the native search pattern, so n/N and search
-- highlighting still work. Without a parser/scope, open a plain search prompt.
-- Explicit \| alternatives need grouping: \%(foo\|bar\), just as before.
function M.search(kind, forward)
  local scope = M.find(kind)
  local slash = forward and "/" or "?"
  local prefix = search_prefix(scope)
  local label = kind == "function" and "function" or "scope"
  local detail = scope and ("%s [%d-%d]"):format(scope.type, scope.first, scope.last) or "none (plain search)"
  vim.api.nvim_echo({ { label .. ": ", "Comment" }, { detail, "Identifier" } }, false, {})
  vim.api.nvim_feedkeys(slash .. prefix, "n", false)
end

-- Like native */#: respect 'iskeyword', ignore 'smartcase', and skip the
-- current word even when # is invoked from its middle or from whitespace.
function M.search_word(forward)
  local scope = M.find("function")
  local count = vim.v.count1
  local word = vim.fn.expand("<cword>")
  if not scope or word == "" then
    vim.cmd("normal! " .. count .. (forward and "*" or "#"))
    return
  end
  local pattern = "\\V"
    .. (vim.fn.match(word, [[^\k]]) == 0 and [[\<]] or "")
    .. vim.fn.escape(word, [[\]])
    .. (vim.fn.match(word, [[\k$]]) >= 0 and [[\>]] or "")

  -- Native * first moves to the beginning of the chosen word. Locate that
  -- exact occurrence, not a previous identical word on the same line.
  local cursor = vim.api.nvim_win_get_cursor(0)
  local text, offset = vim.api.nvim_get_current_line(), 0
  while true do
    local match = vim.fn.matchstrpos(text, [[\C]] .. pattern, offset)
    if match[2] < 0 then return end
    if match[3] > cursor[2] then
      vim.cmd("normal! m'") -- record the original cursor, before normalization
      vim.api.nvim_win_set_cursor(0, { cursor[1], match[2] })
      break
    end
    offset = match[3]
  end
  pattern = search_prefix(scope) .. (vim.o.ignorecase and [[\c]] or [[\C]]) .. pattern
  vim.fn.setreg("/", pattern)
  vim.fn.histadd("search", pattern)
  vim.v.searchforward = forward and 1 or 0
  vim.v.hlsearch = 1
  -- Let native search handle count, wrapscan and errors; n/N reuse the scope.
  vim.cmd("keepjumps normal! " .. count .. "n")
end

function M.select()
  local scope = M.find()
  if not scope then
    vim.notify("No Tree-sitter scope at the cursor", vim.log.levels.INFO)
    return false
  end
  return selection.select_range({ scope.node:range() })
end

function M.goto_signature()
  -- Search scopes also accept classes/structs; a function-signature jump must
  -- instead find an actual enclosing function, method or anonymous function.
  local node = selection.find_scope(function(candidate)
    local kind = candidate:type()
    return function_types[kind] and not container_types[kind]
  end)
  if not node then
    vim.notify("No enclosing Tree-sitter function at the cursor", vim.log.levels.INFO)
    return false
  end
  local row, col = node:start()
  local target = { row + 1, col }
  if not vim.deep_equal(vim.api.nvim_win_get_cursor(0), target) then
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(0, target)
  end
  vim.cmd("normal! zv") -- reveal the signature if its fold is closed
  return true
end

function M.fuzzy(opts)
  opts = opts or {}
  local scope = M.find()
  if not scope then return require("telescope.builtin").current_buffer_fuzzy_find(opts) end

  local filename = vim.api.nvim_buf_get_name(scope.bufnr)
  local entries = {}
  for i, text in ipairs(vim.api.nvim_buf_get_lines(scope.bufnr, scope.first - 1, scope.last, false)) do
    entries[i] = { lnum = scope.first + i - 1, bufnr = scope.bufnr, filename = filename, text = text }
  end
  -- A custom finder avoids scanning/highlighting the entire buffer just to
  -- search a small scope. Keep Telescope's standard entry/sorter/preview APIs.
  local entry_maker = require("telescope.make_entry").gen_from_buffer_lines(opts)
  local conf = require("telescope.config").values
  require("telescope.pickers").new(opts, {
    prompt_title = ("Scope fuzzy (%s %d-%d)"):format(scope.type, scope.first, scope.last),
    finder = require("telescope.finders").new_table({
      results = entries,
      entry_maker = function(entry)
        local result = entry_maker(entry)
        if result then result.bufnr = scope.bufnr end -- also works for unnamed buffers
        return result
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
  }):find()
end

return M
