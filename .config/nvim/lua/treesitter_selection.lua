-- Selection-aware Tree-sitter helpers. Ranges are byte-based, 0-indexed and
-- end-exclusive, just like TSNode:range(); no yanking or scratch registers.
local M = {}

local function before(a, b)
  return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
end

local function same_range(a, b)
  return a and b and a[1] == b[1] and a[2] == b[2]
    and a[3] == b[3] and a[4] == b[4]
end

local function line(buf, row)
  return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
end

-- Convert a byte offset in extracted text back to a buffer position.
local function offset_pos(text, offset, row, col)
  local prefix = text:sub(1, offset)
  local _, newlines = prefix:gsub("\n", "")
  if newlines == 0 then return { row, col + offset } end
  return { row + newlines, #prefix:match("[^\n]*$") }
end

local function trim_range(buf, range)
  local sr, sc, er, ec = unpack(range)
  local count = vim.api.nvim_buf_line_count(buf)
  -- Tree-sitter roots can end one row past the buffer's last line.
  if er == count and ec == 0 then
    er, ec = count - 1, #line(buf, count - 1)
  end
  local text = table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
  local first = text:find("%S")
  if not first then return nil end
  local last = text:match(".*%S()") - 1
  local from = offset_pos(text, first - 1, sr, sc)
  local to = offset_pos(text, last, sr, sc)
  return { from[1], from[2], to[1], to[2] }
end

local function parser_for(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then return nil end
  if not pcall(parser.parse, parser, true) then return nil end
  return parser
end

-- Shared by scope search, the scoped Telescope picker and <leader>v.
function M.find_scope(pick)
  if not parser_for(0) then return nil end
  local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
  if not ok then return nil end
  while node do
    if pick(node) then return node end
    node = node:parent()
  end
end

local function visual_range(buf)
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then return nil end
  -- getregionpos handles backwards and 'selection=exclusive' selections;
  -- '< / '> would still refer to the PREVIOUS selection while Visual is active.
  local regions = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), {
    type = mode,
    exclusive = vim.o.selection == "exclusive",
  })
  if #regions == 0 then return nil end
  local from, to = regions[1][1], regions[#regions][2]
  local sr, sc, er, ec = from[2] - 1, from[3] - 1, to[2] - 1, to[3] - 1
  local text = line(buf, er)
  -- getregionpos gives inclusive character positions, not exclusive byte ends.
  local char = text:sub(ec + 1):match("^.[\128-\191]*") or ""
  ec = math.min(ec + #char, #text)
  return trim_range(buf, { sr, sc, er, ec })
end

-- Match the whole selection (ignoring edge whitespace), not the node at the
-- closing delimiter. Never silently widen a partial selection to its parent.
local function selected_node(buf, parser, range)
  local found, language
  parser:for_each_tree(function(tree, langtree)
    if not tree or found then return end
    local root = tree:root()
    local rr = { root:range() }
    if before({ range[1], range[2] }, { rr[1], rr[2] })
      or before({ rr[3], rr[4] }, { range[3], range[4] }) then return end
    local node = root:named_descendant_for_range(unpack(range))
    while node do
      if same_range(trim_range(buf, { node:range() }), range) then
        found, language = node, langtree:lang()
        return
      end
      node = node:parent()
    end
  end)
  return found, language
end

-- Delimiters must be actual anonymous syntax tokens. A bracket in a string or
-- comment cannot be mistaken for the boundary of a block/list/argument list.
local pairs_by_open = { ["("] = ")", ["["] = "]", ["{"] = "}" }
local function delimited_range(node)
  local first, last = node:child(0), node:child(node:child_count() - 1)
  if not first or not last or last:named() then return nil end
  -- Indexing nodes include the receiver: items[index]. Look for a trailing
  -- delimiter pair among DIRECT children, not brackets in a nested expression.
  if first:named() then
    for i = node:child_count() - 2, 0, -1 do
      local child = node:child(i)
      if not child:named() and pairs_by_open[child:type()] == last:type() then
        first = child
        break
      end
    end
  end
  if first:named() then return nil end
  if pairs_by_open[first:type()] ~= last:type() then return nil end
  local _, _, sr, sc = first:range()
  local er, ec = last:range()
  return { sr, sc, er, ec }
end

-- Custom per-language queries pair an exact outer node with its body. Captures
-- from nested constructs are deliberately ignored. Queries may capture several
-- sibling statements: take their combined range, not just the first statement.
local function query_inner(buf, node, language)
  local ok, query = pcall(vim.treesitter.query.get, language, "scope_inner")
  if not ok or not query then return nil end
  for _, match, metadata in query:iter_matches(node, buf) do
    local owns_node, ranges = false, {}
    for id, nodes in pairs(match) do
      for _, capture in ipairs(nodes) do
        if query.captures[id] == "scope.outer" and capture:id() == node:id() then
          owns_node = true
        elseif query.captures[id] == "scope.inner" then
          local r = vim.treesitter.get_range(capture, buf, metadata[id])
          ranges[#ranges + 1] = { r[1], r[2], r[4], r[5] }
        end
      end
    end
    if owns_node and #ranges > 0 then
      local result = ranges[1]
      for i = 2, #ranges do
        local r = ranges[i]
        if before({ r[1], r[2] }, { result[1], result[2] }) then
          result[1], result[2] = r[1], r[2]
        end
        if before({ result[3], result[4] }, { r[3], r[4] }) then
          result[3], result[4] = r[3], r[4]
        end
      end
      return result
    end
  end
end

local function contents_range(node)
  local delimited = delimited_range(node)
  if delimited then return delimited end
  -- Some grammars wrap a delimited node in an identically-sized named node
  -- (e.g. YAML flow_node). Only unwrap equal ranges, never an arbitrary child.
  if node:named_child_count() == 1 then
    local child = node:named_child(0)
    if same_range({ child:range() }, { node:range() }) then
      return contents_range(child)
    end
  end
end

function M.inner_range(buf, node, language)
  local outer = trim_range(buf, { node:range() })
  local range = contents_range(node) or query_inner(buf, node, language)
  -- Body/argument fields cover brace-based grammars without language-specific
  -- queries, including C/C++, Go, Rust and JavaScript. For conditionals, use
  -- the primary consequence; select an else node separately for its contents.
  if not range then
    for _, field in ipairs({ "body", "consequence", "arguments" }) do
      local child = node:field(field)[1]
      if child then
        range = contents_range(child) or { child:range() }
        break
      end
    end
  end
  -- Typed literals can put the actual {...} in a value field (e.g. Go's
  -- []int{1, 2}). Do not treat arbitrary scalar assignment values as bodies.
  if not range then
    local value = node:field("value")[1]
    if value then range = contents_range(value) end
  end
  if not range then return nil end
  range = trim_range(buf, range)
  if not range or same_range(range, outer) then return nil end
  if before({ range[1], range[2] }, { outer[1], outer[2] })
    or before({ outer[3], outer[4] }, { range[3], range[4] }) then return nil end
  return range
end

local function previous_pos(buf, row, col)
  if col == 0 then
    row = row - 1
    col = #line(buf, row)
    if col == 0 then return { row, 0 } end
  end
  local text = line(buf, row)
  col = col - 1
  while col > 0 and text:byte(col + 1) >= 128 and text:byte(col + 1) < 192 do
    col = col - 1
  end
  return { row, col }
end

function M.select_range(range, whole_lines)
  local buf = vim.api.nvim_get_current_buf()
  local sr, sc, er, ec = unpack(range)
  if er == vim.api.nvim_buf_line_count(buf) and ec == 0 then
    er, ec = er - 1, #line(buf, er - 1)
  end
  if not before({ sr, sc }, { er, ec }) then return false end
  local last = previous_pos(buf, er, ec)
  local linewise = whole_lines
    and line(buf, sr):sub(1, sc):match("^%s*$")
    and line(buf, er):sub(ec + 1):match("^%s*$")
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("normal! " .. mode) -- leave the old selection without invoking maps
  end
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd("normal! " .. (linewise and "V" or "v"))
  if not linewise and vim.o.selection == "exclusive" then
    -- Exclusive Visual mode needs the cursor one character past the contents,
    -- including at EOL. Temporarily permit that position without changing the
    -- user's selection option (Flash also temporarily changes it on a jump).
    local virtualedit = vim.wo.virtualedit
    vim.wo.virtualedit = "onemore"
    vim.api.nvim_win_set_cursor(0, { er + 1, ec })
    vim.wo.virtualedit = virtualedit
  else
    vim.api.nvim_win_set_cursor(0, { last[1] + 1, last[2] })
  end
  return true
end

function M.select_scope(pick)
  local node = M.find_scope(pick)
  if not node then
    vim.notify("No Tree-sitter scope at the cursor", vim.log.levels.INFO)
    return false
  end
  return M.select_range({ node:range() })
end

function M.select_inner()
  local buf = vim.api.nvim_get_current_buf()
  local parser = parser_for(buf)
  local range = visual_range(buf)
  local node, language
  if parser and range then node, language = selected_node(buf, parser, range) end
  local inner
  -- Several named wrappers can share an identical range, particularly YAML
  -- document/block/mapping nodes. Try their semantic parents too, but only
  -- while they still represent EXACTLY the existing selection.
  while node and same_range(trim_range(buf, { node:range() }), range) do
    inner = M.inner_range(buf, node, language)
    if inner then break end
    node = node:parent()
  end
  if not inner then
    vim.notify("No inner Tree-sitter range for this selection", vim.log.levels.INFO)
    return false
  end
  return M.select_range(inner, true)
end

return M
