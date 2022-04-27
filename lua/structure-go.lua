local tags = require("tags")
local sg = {}
-- create window
function sg.create_window()
	vim.cmd('botright vs')
end

function sg.setup_view()
	local buff = vim.api.nvim_get_current_buf()
	-- create window
	sg.create_window()

	local bufs = vim.api.nvim_create_buf(false, true)
	local windows = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(windows, bufs)

	vim.api.nvim_buf_set_name(bufs, 'structure')
	vim.api.nvim_buf_set_option(bufs, 'filetype', 'structure')

	return buff, bufs, windows
end

function sg.run()
	local buff, bufs, windows = sg.setup_view()
	tags.run(buff, bufs, window)
end

return sg
