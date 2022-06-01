local hl = require("structrue-go.highlight")
local c = require("structrue-go.config")
local tags = require("structrue-go.tags")
local symbol = require("structrue-go.symbol")
local env = require("structrue-go.env")
local w = require("structrue-go.window")
local ns = require("structrue-go.namespace")

local sg = {}

local config = {}
function sg.setup(user_config)
	c.setup(user_config)
	config = require("structrue-go.config").get_data()
	env.setup()
	symbol.setup()
	hl.setup()
	tags.setup()
	w.setup()

	sg.global_key_bind()
	sg.auto_cmd()

end

-- open
function sg.open()
	if w.bufsw ~= nil then
		return
	end

	local buff = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_get_option(buff, "filetype") ~= "go" then
		return
	end

	w.buff = buff
	w.bufw = vim.api.nvim_get_current_win()

	tags.init()
	local file_path = tags.get_current_buff_path()
	sg.generate(file_path)
	tags.current_buff_name = string.sub(tags.current_buff_fullname, #file_path + 2)
end

-- bind global kemmap.
function sg.global_key_bind()
	vim.api.nvim_set_keymap("n", config.keymap.toggle, ":lua require'structrue-go'.toggle()<cr>", { silent = true })
	vim.api.nvim_set_keymap("n", config.keymap.preview_close, ":lua require'structrue-go'.preview_close()<cr>", { silent = true })
	vim.api.nvim_set_keymap("n", config.keymap.center_symbol, ":lua require'structrue-go'.center_symbol()<cr>", { silent = true })
end

-- create autocmd.
function sg.auto_cmd()
	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
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

	vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
		callback = function()
			local t = vim.api.nvim_buf_get_option(0, "filetype")
			if t == "structrue-go" then
				hl.hl_line = nil
				if w.bufsw ~= nil and vim.api.nvim_win_is_valid(w.bufsw) then
					vim.api.nvim_win_close(w.bufsw, true)
				end
				w.bufsw = nil
				hl.stop_hl_cls()
			end
		end
	})

	vim.api.nvim_create_autocmd({ "WinLeave" }, {
		pattern = "*.go",
		callback = function()
			if vim.api.nvim_get_current_win() ~= w.previeww then
				w.buff_leave_line = vim.fn.line(".")
			else
				w.previeww = nil
			end
		end
	})

	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		callback = function()
			if vim.api.nvim_get_current_win() == w.bufsw then
				sg.hl_buff_line()
			end
		end
	})
end

-- highlight buffer's symbol in structrue-go.
function sg.hl_buff_line()
	if hl.hl_line ~= nil then
		vim.api.nvim_buf_clear_highlight(tonumber(w.bufs), ns["sg_cls"], hl.hl_line - 1, hl.hl_line)
	end

	local hl_line = hl.get_bufs_hl_line(w.buff_leave_line)
	if hl_line ~= nil then
		hl.hl_line = hl_line
		vim.api.nvim_buf_add_highlight(tonumber(w.bufs), ns["sg_cls"], "sg_cls", hl_line - 1, 3, -1)
	end
end

-- generate symbols.
function sg.generate(path, type)
	if not env.install_gotags then
		vim.notify("Miss gotags or not in PATH", vim.log.levels.ERROR)
		return
	end

	local gofiles = path .. env.path_sep .. "*.go"
	vim.fn.jobstart("gotags " .. gofiles, {
		on_stdout = function(_, data)
			for _, line in pairs(data) do
				if line == "" or string.sub(line, 1, 1) == "!" then
					goto continue
				end
				tags:group(symbol.New(line))
				::continue::
			end
		end,
		on_exit = function()
			sg.generate_finish(type)
		end
	})
end

-- generated symbols callback.
function sg.generate_finish(type)
	tags.flush_to_bufs()
	w.attach_structrue_window()
	hl.start_hl_cls()

	if type == "refresh" then
		sg.hl_buff_line()
	end
end

-- close structrue-go window.
function sg.close()
	if w.bufsw ~= nil and vim.api.nvim_win_is_valid(w.bufsw) then
		vim.api.nvim_win_close(w.bufsw, true)
	end

	w.bufsw = nil
end

-- toggle.
function sg.toggle()
	if w.bufsw == nil then
		sg.open()
	else
		sg.close()
	end

end

-- refresh buffer symbols structure.
function sg.refresh()
	local buff = w.buff
	tags.init()
	w.buff = buff
	sg.generate(tags.get_current_buff_path(), "refresh")
end

-- jump from symbol.
function sg.jump()
	local line = vim.api.nvim_exec("echo line('.')", true)
	tags.jump(tonumber(line))
end

-- hide.
function sg.hide_others_methods_toggle()
	tags.hide_others_methods_toggle()
end

-- fold toggle.
function sg.fold_toggle()
	tags.fold_toggle()
end

-- open symbol preview.
function sg.preview_open()
	local line = vim.fn.line(".")
	local buff_line = tags.lines.lines[line]
	local name = tags.lines.names[tonumber(line)][2]

	w.preview_open(buff_line, name)
end

-- close symbol preview.
function sg.preview_close()
	w.preview_close()
end

-- Center the highlighted symbol
function sg.center_symbol()
	local t = vim.api.nvim_buf_get_option(0, "filetype")
	if t ~= "go" then
		return
	end
	hl.center_symbol()
end

return sg
