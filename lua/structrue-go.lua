local hl = require("highlight")
local c = require("config")
local tags = require("tags")
local ev = require("event")
local symbol = require("symbol")
local env = require("env")
local w = require("window")

local sg = {}

function sg.setup(user_config)
	c.setup(user_config)
	ev.setup() -- event
	env.setup()
	symbol.setup()
	hl.setup()
	tags.setup()
	w.setup()
end

-- open
function sg.open()
	local buff = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_get_option(buff, "filetype") ~= "go" then
		return
	end

	w.buff = buff
	w.bufw = vim.api.nvim_get_current_win()
	w.create_structrue_window()

	tags.run()

	hl.sg_open_handle()
end

-- close
function sg.close()
	vim.api.nvim_win_close(w.bufsw, true)
	w.bufsw = nil
end

-- toggle
function sg.toggle()
	if w.bufsw == nil then
		sg.open()
		return
	end

	if vim.api.nvim_win_is_valid(w.bufsw) then
		sg.close()
	else
		sg.open()
	end
end

function sg.refresh()
	local buff = w.buff
	tags.init()
	w.buff = buff
	tags.generate(tags.get_current_buff_path())
end

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

function sg.preview_open()
	local line = vim.api.nvim_exec("echo line('.')", true)
	local buff_line = tags.lines.lines[tonumber(line)]
	w.preview_open(buff_line)
end

function sg.preview_close()
	w.preview_close()
end

return sg
