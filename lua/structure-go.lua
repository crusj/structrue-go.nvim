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

	sg.create_window()
	sg.windows = vim.api.nvim_get_current_win()

	if sg.bufs == nil then
		sg.bufs = vim.api.nvim_create_buf(false, true)

		vim.api.nvim_buf_set_name(sg.bufs, 'structure')
		vim.api.nvim_buf_set_option(sg.bufs, 'filetype', 'structure')
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	else
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	end

	tags.run(sg.buff,sg.bufs,sg.windows)
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

return sg
