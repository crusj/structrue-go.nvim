local hl = require("highlight")
local c = require("config")
local tags = require("tags")
local ev = require("event")
local symbol = require("symbol")
local env = require("env")

local sg = {
	buff = nil,
	bufs = nil,
	windows = nil,
	buff_width = 0,
}

local config = {}

-- create window
function sg.create_window()
	sg.buff_width = math.floor(vim.api.nvim_win_get_width(0) / 4)
	vim.cmd('botright vs')
end

function sg.setup(user_config)
	c.setup(user_config)
	config = c.get_data()

	ev.setup() -- event
	env.setup()
	symbol.setup()
	hl.setup()
	tags.setup()
end

-- open
function sg.open()
	local buff = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_get_option(buff, "filetype") ~= "go" then
		return
	end
	sg.buff = buff
	sg.windowf = vim.api.nvim_get_current_win()

	sg.create_window()
	sg.windows = vim.api.nvim_get_current_win()



	if sg.bufs == nil then
		sg.bufs = vim.api.nvim_create_buf(false, true)
		sg.buf_key_binds()

		vim.api.nvim_buf_set_name(sg.bufs, 'structrue')
		vim.api.nvim_buf_set_option(sg.bufs, 'filetype', 'structrue-go')
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
		sg.buf_key_binds()
	else
		vim.api.nvim_win_set_buf(sg.windows, sg.bufs)
	end

	if config.number == "nu" then
		vim.api.nvim_win_set_option(sg.windows, 'number', true)
	elseif config.number == "rnu" then
		vim.api.nvim_win_set_option(sg.windows, 'relativenumber', true)
	else
		vim.api.nvim_win_set_option(sg.windows, 'relativenumber', false)
		vim.api.nvim_win_set_option(sg.windows, 'number', false)
	end

	vim.api.nvim_win_set_option(sg.windows, 'winfixwidth', true)
	vim.api.nvim_win_set_option(sg.windows, 'wrap', false)
	vim.api.nvim_win_set_option(sg.windows, 'cursorline', false)
	vim.api.nvim_win_set_width(sg.windows, sg.buff_width)

	if sg.finish_buf_key_binds == false then
		sg.finish_buf_key_binds = true
	end

	tags.run(sg.buff, sg.bufs, sg.windowf, sg.windows)

	hl.sg_open_handle()
end

-- close
function sg.close()
	vim.api.nvim_win_close(sg.windows, true)
	sg.windows = nil
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

function sg.buf_key_binds()
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", config.keymap.symbol_jump, ":lua require'structrue-go'.jump()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", config.keymap.show_others_method_toggle, ":lua require'structrue-go'.hide_others_methods_toggle()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", config.keymap.fold_toggle, ":lua require'structrue-go'.fold_toggle()<cr>", { silent = true })
end

-- register events

-- jump from symbols
function sg.jump()
	local line = vim.api.nvim_exec("echo line('.')", true)
	tags.jump(tonumber(line))
end

function sg.hide_others_methods_toggle()
	tags.hide_others_methods_toggle()
end

function sg.fold_toggle()
	tags.fold_toggle()
end

return sg
