local hl = require("highlight")
local tags = require("tags")
local event = require("event")
local symbol = require("symbol")
local sg = {
	buff = nil,
	bufs = nil,
	windows = nil,
	buff_width = 0,
	config = {},
}
-- create window
function sg.create_window()
	sg.buff_width = math.floor(vim.api.nvim_win_get_width(0) / 4)
	vim.cmd('botright vs')
end

function sg.setup(config)
	sg.config = sg.merge_config(config)
	sg.register_events()
	symbol.setup(sg.config)
	hl.init()
	tags.setup(sg.config)
	sg.global_key_binds()
	
end

-- merge user defined config
function sg.merge_config(config)
	local default_config = {
		show_filename = true, -- bool
		number = "no", -- show number: no | nu | rnu
		fold_open_icon = " ",
		fold_close_icon = " ",
		cursor_symbol_hl = "guibg=Gray guifg=White", -- symbol hl under cursor,
		symbol = { -- symbol style
			filename = {
				hl = "guifg=Black", -- highlight symbol
				icon = " " -- symbol icon
			},
			package = {
				hl = "guifg=Red",
				icon = "⊞ "
			},
			import = {
				hl = "guifg=Grey",
				icon = "⌬ "
			},
			const = {
				hl = "guifg=Orange",
				icon = "π ",
			},
			variable = {
				hl = "guifg=Magenta",
				icon = "◈ ",
			},
			func = {
				hl = "guifg=DarkBlue",
				icon = "◧ ",
			},
			interface = {
				hl = "guifg=Green",
				icon = "❙ "
			},
			type = {
				hl = "guifg=Purple",
				icon = "▱ ",
			},
			struct = {
				hl = "guifg=Purple",
				icon = "❏ ",
			},
			field = {
				hl = "guifg=DarkYellow",
				icon = "▪ "
			},
			method_current = {
				hl = "guifg=DarkGreen",
				icon = "◨ "
			},
			method_others = {
				hl = "guifg=LightGreen",
				icon = "◨ "
			},
		},
		keymap = {
			toggle = "<leader>m", -- toggle structrue-go window
			show_others_method_toggle = "H", -- show or hidden the methods of struct whose not in current file
			symbol_jump = "<CR>", -- jump to symbol file under cursor
			fold_toggle = "\\z"
		},
		fold = { -- fold symbols
			import = true,
			const = false,
			variable = false,
			type = false,
			interface = false,
			func = false,
		},
	}

	-- invalid config
	if config == nil or type(config) ~= "table" then
		return default_config
	end

	for dk, dv in pairs(default_config) do
		if type(dv) ~= "table" then
			if config[dk] ~= nil then
				default_config[dk] = config[dk]
			end
			goto continue
		end

		if (dk == "fold" or dk == "keymap") and config[dk] ~= nil then
			for fk, fv in pairs(dv) do
				if config[dk][fk] ~= nil then
					default_config[dk][fk] = fv
				end
			end
		end

		-- symbol
		if dk == "symbol" and config[dk] ~= nil then
			for sk, sv in pairs(dv) do
				if config[dk][sk] ~= nil then
					for k, v in pairs(sv) do
						if config[dk][sk][k] ~= nil then
							default_config[dk][sk][k] = v
						end
					end
				end
			end
		end

		::continue::
	end

	return default_config
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

	if sg.config.number == "nu" then
		vim.api.nvim_win_set_option(sg.windows, 'number', true)
	elseif sg.config.number == "rnu" then
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
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", sg.config.keymap.symbol_jump, ":lua require'structrue-go'.jump()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", sg.config.keymap.show_others_method_toggle, ":lua require'structrue-go'.hide_others_methods_toggle()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(sg.bufs, "n", sg.config.keymap.fold_toggle, ":lua require'structrue-go'.fold_toggle()<cr>", { silent = true })
end

function sg.global_key_binds()
	vim.api.nvim_set_keymap("n", sg.config.keymap.toggle, ":lua require'structrue-go'.toggle()<cr>", { silent = true })
end

-- register events
function sg.register_events()
	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
		pattern = { "*.go" },
		callback = event.enter
	})
	vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
		callback = function(data)
			if vim.api.nvim_buf_get_option(data.buf, "filetype") == "structrue-go" then
				hl.sg_close_handle()
			end
		end
	})
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

return sg
