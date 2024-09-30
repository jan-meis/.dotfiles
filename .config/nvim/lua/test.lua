local qfopen = false
for id,w in pairs(vim.api.nvim_list_wins()) do
  if (vim.fn.win_gettype(w)=="quickfix") then
    qfopen = true
  end
end
if (not qfopen) then
  vim.cmd("copen 4")
else
  vim.cmd.cclose()
end
