require('highlight')
local tags = require("tags")
local sg = {
	buff = nil,
	bufs = nil,
	windows = nil,
}
-- create window
function sg.create_window()
	vim.cmd('botright vs')
end

-- open
function sg.open()
	sg.buff = vim.api.nvim_get_current_buf()
	sg.windowf = vim.api.nvim_get_current_win()

	sg.create_window()
	sg.windows = vim.api.nvim_get_current_win()

	if sg.bufs == nil then
		sg.bufs = vim.api.nvim_create_buf(false, true)
		sg.key_binds()

		vim.api.nvim_buf_set_name(sg.bufs, 'structure')
		vim.api.nvim_buf_set_option(sg.bufs, 'filetype', 'structure')
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	else
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	end

	tags.run(sg.buff, sg.bufs, sg.windowf, sg.windows)
end

-- close
function sg.close()
	vim.api.nvim_win_close(sg.windows, true)
	sg.windows = nil
end

-- toggle
function sg.toggle()
	if sg.windows ~= nil then
		sg.close()
	else
		sg.open()
	end
end

function sg.key_binds()
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", "<cr>", ":lua require'structure-go'.jump()<cr>", {})
end

-- jump from symbols
function sg.jump()
	local line = vim.api.nvim_exec("echo line('.')", true)
	tags.jump(tonumber(line))
end

return sg

