local M = {
    cmd_win_leave = nil,
    cmd_win_enter = nil
}

local api = vim.api

function M.structure_leave(hl, w)
    -- reset
    if M.cmd_win_leave ~= nil then
        api.nvim_del_autocmd(M.cmd_win_leave)
        M.cmd_win_leave = nil
    end

    M.cmd_win_leave = api.nvim_create_autocmd({ "BufWinLeave" }, {
        callback = function()
            hl.hl_line = nil
            if w.bufsw ~= nil and vim.api.nvim_win_is_valid(w.bufsw) then
                vim.api.nvim_win_close(w.bufsw, true)
            end
            w.bufsw = nil
            hl.stop_hl_cls()
        end,
        buffer = w.bufs
    })
end

function M.structure_win_enter(sg, w)
    if M.cmd_win_enter ~= nil then
        api.nvim_del_autocmd(M.cmd_win_enter)
        M.cmd_win_enter = nil
    end

    M.cmd_win_enter = api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function()
            print("win enter")
            sg.hl_buff_line()
        end,
        buffer = w.bufs
    })
end

function M.win_enter(tags, w, sg)
    api.nvim_create_autocmd({ "BufWinEnter" }, {
        callback = function()
            local filetype = vim.api.nvim_buf_get_option(0, "filetype")
            if filetype == "go" then
                if w.bufsw ~= nil and vim.api.nvim_win_is_valid(w.bufsw) then
                    local buf = vim.api.nvim_get_current_buf()
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name ~= tags.current_buff_fullname and w.bufs ~= nil then
                        tags.init()
                        w.buff = buf
                        local file_path = tags.get_current_buff_path()
                        sg.generate(file_path)
                    end
                end
            elseif filetype == "structrue-go" then
                sg.hl_buff_line()
            end
        end
    })
end

return M
