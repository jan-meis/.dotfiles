-- Traverse a snapshot of the same MRU buffers shown by <leader>l. Buffer visits
-- during traversal still update MRU order, but don't reshuffle that snapshot.
local M = {}
local visits, sequence = {}, 0
local snapshot, snapshot_win, unlisted_origin
local switching = false

local function record()
  sequence = sequence + 1
  visits[vim.api.nvim_get_current_buf()] = sequence
  if not switching then snapshot = nil end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("buffer_history", { clear = true }),
    callback = record,
  })
  record()
end

-- Shared with Telescope. Track visits within a single second too: Neovim's
-- lastused timestamp alone cannot reliably order rapid buffer switches.
function M.less(a, b)
  local current = vim.api.nvim_get_current_buf()
  if a == current or b == current then return a == current and b ~= current end
  if (visits[a] or 0) ~= (visits[b] or 0) then return (visits[a] or 0) > (visits[b] or 0) end
  local ai, bi = vim.fn.getbufinfo(a)[1], vim.fn.getbufinfo(b)[1]
  local at, bt = ai and ai.lastused or 0, bi and bi.lastused or 0
  if at ~= bt then return at > bt end
  local alternate = vim.fn.bufnr("#")
  if a == alternate or b == alternate then return a == alternate and b ~= alternate end
  return a > b
end

function M.ordered()
  local buffers = {}
  for _,info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    buffers[#buffers + 1] = info.bufnr
  end
  table.sort(buffers, M.less)
  return buffers
end

-- direction=1 goes older, -1 goes newer. Stop at the ends, like history rather
-- than a wrapping buffer carousel. A normal buffer switch starts a fresh chain.
function M.step(direction, count)
  local current, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  if not snapshot or snapshot_win ~= win or not vim.tbl_contains(snapshot, current) then
    snapshot, snapshot_win = M.ordered(), win
    unlisted_origin = not vim.bo[current].buflisted and current or nil
    -- Also allow returning to an unlisted starting buffer, e.g. a help window.
    if not vim.tbl_contains(snapshot, current) then table.insert(snapshot, 1, current) end
  end
  snapshot = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and (buf == unlisted_origin or vim.bo[buf].buflisted)
  end, snapshot)
  local index
  for i, buf in ipairs(snapshot) do
    if buf == current then index = i; break end
  end
  local target = math.max(1, math.min(#snapshot, index + direction * (count or 1)))
  if target == index then
    vim.notify(direction > 0 and "No older buffer" or "No newer buffer", vim.log.levels.INFO)
    return false
  end
  switching = true
  local ok, err = pcall(vim.cmd.buffer, snapshot[target])
  switching = false
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
    return false
  end
  return true
end

return M
