-- Workaround for COQ v2 (765da9f): completion edits are applied asynchronously.
-- Remember where the accepted word ended before the character that closed the
-- menu is inserted, so its LSP text edit cannot consume that character (or
-- subsequent typing). Remove this shim once upstream fixes deferred insertion.
local M = {}
local configured = false

function M.setup()
    if configured then return end
    configured = true
    local context = require("coq.lib.context")
    local inserted = require("coq.completions.inserted")
    local lsp = require("coq.producers.lsp.util")
    local ns = vim.api.nvim_create_namespace("coq_commit")
    local accepted

    vim.api.nvim_create_autocmd("CompleteDone", {
        group = vim.api.nvim_create_augroup("coq_commit", { clear = true }),
        callback = function()
            local item = vim.v.completed_item.user_data
            accepted = type(item) == "table" and item.meta
                and { uid = item.meta.uid, ctx = context.full() } or nil
        end,
    })

    local apply = inserted.apply
    inserted.apply = function(settings, ctx, resolver, item)
        local saved = accepted
        if not saved or saved.uid ~= item.meta.uid then
            return apply(settings, ctx, resolver, item)
        end
        local before = saved.ctx
        local row, col = unpack(before.pos)
        local current_row, current_col = unpack(ctx.pos)
        local extra = current_col - col
        if before.buf ~= ctx.buf or row ~= current_row or extra <= 0
            or ctx.line:sub(1, col) ~= before.line:sub(1, col)
            or ctx.line:sub(current_col + 1) ~= before.line:sub(col + 1) then
            return apply(settings, ctx, resolver, item)
        end

        local anchored = vim.tbl_extend("force", ctx, { pos = before.pos, coq_commit = {} })
        local ok, result = pcall(apply, settings, anchored, resolver, item)
        local mark = anchored.coq_commit.cursor
        if mark and vim.api.nvim_buf_is_valid(ctx.buf) then
            local pos = vim.api.nvim_buf_get_extmark_by_id(ctx.buf, ns, mark, {})
            if #pos == 2 and vim.api.nvim_win_is_valid(ctx.win)
                and vim.api.nvim_win_get_buf(ctx.win) == ctx.buf then
                vim.api.nvim_win_set_cursor(ctx.win, { pos[1] + 1, pos[2] })
            end
            vim.api.nvim_buf_del_extmark(ctx.buf, ns, mark)
        end
        if not ok then error(result) end
        return result
    end

    local main_edit = inserted._main_edit
    inserted._main_edit = function(ctx, item, main)
        local edit = main_edit(ctx, item, main)
        if not ctx.coq_commit then return edit end
        -- The fallback span may also include trailing keyword characters.
        local row, col = unpack(ctx.pos)
        local encoding = lsp.encoding(item)
        local end_col = vim.str_utfindex(ctx.line, encoding, col, true)
        local finish = edit.range["end"]
        if finish.line == row - 1 and finish.character > end_col then
            finish.character = end_col
        end
        return edit
    end

    local apply_edits = inserted._apply_edits
    inserted._apply_edits = function(ctx, item, main, additional)
        if ctx.coq_commit then
            -- Do this only after COQ's asynchronous resolve/validity checks.
            -- Snippet expansion must happen before the continuation, too.
            local row, col = unpack(vim.api.nvim_win_get_cursor(ctx.win))
            ctx.coq_commit.cursor = vim.api.nvim_buf_set_extmark(ctx.buf, ns, row - 1, col, { right_gravity = true })
            vim.api.nvim_win_set_cursor(ctx.win, { ctx.pos[1], ctx.pos[2] })
        end
        return apply_edits(ctx, item, main, additional)
    end

    local apply_snippet = inserted._apply_snippet
    inserted._apply_snippet = function(ctx, body)
        if not ctx.coq_commit then return apply_snippet(ctx, body) end
        -- Continuing after the completion opts out of visiting its tabstops.
        -- Native expansion queues selection keys, which would otherwise move
        -- the cursor back into a placeholder after our cursor restoration.
        local jump = vim.snippet.jump
        vim.snippet.jump = function() end
        local ok, err = pcall(apply_snippet, ctx, body)
        vim.snippet.jump = jump
        vim.snippet.stop()
        if not ok then error(err) end
    end
end

return M
