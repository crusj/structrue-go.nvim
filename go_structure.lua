local tags = require("tags")
local gs = {}
-- create window
function gs.create_window()
	vim.cmd('botright vs')
end

function gs.setup_view()
	-- create window
	gs.create_window()

	local buf = vim.api.nvim_create_buf(false, true)
	local window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(window, buf)

	vim.api.nvim_buf_set_name(buf, 'structure')
	vim.api.nvim_buf_set_option(buf, 'filetype', 'structure')
	vim.api.nvim_buf_set_option(buf, 'modifiable', false)

	return buf, window
end

function gs.run()
	local buf,window =gs.setup_view()
	tags.run(buf,window)
end
return gs
