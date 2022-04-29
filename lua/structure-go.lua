local hl = require("highlight")
local tags = require("tags")
local event = require("event")
local sg = {
	buff = nil,
	bufs = nil,
	windows = nil,
	buff_width = 0
}
-- create window
function sg.create_window()
	sg.buff_width = math.floor(vim.api.nvim_win_get_width(0) / 4)
	vim.cmd('botright vs')
end

function sg.setup()
	sg.register_events()
	hl.init()
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
		vim.api.nvim_buf_set_option(sg.bufs, 'filetype', 'structure-go')
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	else
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	end

	vim.api.nvim_win_set_option(sg.windows, 'number', false)
	vim.api.nvim_win_set_option(sg.windows, 'relativenumber', false)
	vim.api.nvim_win_set_option(sg.windows, 'winfixwidth', true)
	vim.api.nvim_win_set_option(sg.windows, 'wrap', false)
	vim.api.nvim_win_set_option(sg.windows, 'cursorline', false)
	vim.api.nvim_win_set_width(sg.windows, sg.buff_width)

	tags.run(sg.buff, sg.bufs, sg.windowf, sg.windows)

	hl.sg_open_handle()
end

-- close
function sg.close()
	vim.api.nvim_win_close(sg.windows, true)
	sg.windows = nil
	hl.sg_close_handle()
end

-- toggle
function sg.toggle()
	if sg.windows == nil then
		sg.open()
		return
	end

	if vim.api.nvim_win_is_valid(sg.windows) then
		sg.close()
	else
		sg.open()
	end
end

function sg.key_binds()
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", "<cr>", ":lua require'structure-go'.jump()<cr>", {})
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", "H", ":lua require'structure-go'.hide_others_methods_toggle()<cr>", {})
end

function sg.register_events()
	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
		pattern = { "*.go" },
		callback = event.enter
	})
end

function sg.register_timer()
end

-- jump from symbols
function sg.jump()
	local line = vim.api.nvim_exec("echo line('.')", true)
	tags.jump(tonumber(line))
end

function sg.hide_others_methods_toggle()
	tags.hide_others_methods_toggle()
end

return sg
