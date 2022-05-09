local ns = require("structrue-go.namespace")
local w = {
	buff = nil,
	bufw = nil,
	bufw_height = 0,

	bufs = nil,
	bufsw = nil,
	bufsw_width = 0,

	previeww = nil, -- preview window

	hl_line = nil, -- line of last hl

	buff_leave_line = nil -- line of buff window leave
}

local config = nil

function w.setup()
	config = require("structrue-go.config").get_data()
end

function w.create_buf()
	if w.bufs == nil then -- structrue buf
		w.bufs = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(w.bufs, 'structrue')
		vim.api.nvim_buf_set_option(w.bufs, 'filetype', 'structrue-go')
		w.buf_key_binds()
	end
end

function w.attach_structrue_window()
	if w.bufsw == nil then
		if config.position == "float" then
			local buffw = vim.api.nvim_win_get_width(w.bufw)
			local buffh = vim.api.nvim_win_get_height(w.bufw)
			local fw = math.floor(buffw * 0.4)
			local fh = math.floor(buffh * 0.9)

			w.bufsw = vim.api.nvim_open_win(w.bufs, true, {
				relative = "win",
				width = fw,
				height = fh,
				row = math.floor((buffh - fh) / 2),
				col = math.floor((buffw - fw) / 2),
				border = "double",
				zindex = 100,
			})
			w.bufsw_width = fw

		else
			w.bufsw_width = math.floor(vim.api.nvim_win_get_width(w.bufw) / 4)
			vim.cmd(config.position .. ' vs')
		end
		w.bufsw = vim.api.nvim_get_current_win()

		if config.number == "nu" then
			vim.api.nvim_win_set_option(w.bufsw, 'number', true)
		elseif config.number == "rnu" then
			vim.api.nvim_win_set_option(w.bufsw, 'relativenumber', true)
		else
			vim.api.nvim_win_set_option(w.bufsw, 'relativenumber', false)
			vim.api.nvim_win_set_option(w.bufsw, 'number', false)
		end

		vim.api.nvim_win_set_option(w.bufsw, 'winfixwidth', true)
		vim.api.nvim_win_set_option(w.bufsw, 'wrap', false)
		vim.api.nvim_win_set_option(w.bufsw, 'cursorline', true)
		vim.api.nvim_win_set_width(w.bufsw, w.bufsw_width)
		w.bufw_height = vim.api.nvim_win_get_height(w.bufw)
	end
	vim.api.nvim_win_set_buf(w.bufsw, w.bufs) -- bind buf and window
end

function w.preview_open(buf_line, name)
	if w.previeww ~= nil and vim.api.nvim_win_is_valid(w.previeww) then
		vim.api.nvim_win_close(w.previeww, true)
	end

	local ew = vim.api.nvim_get_option("columns")
	local eh = vim.api.nvim_get_option("lines")

	local width = math.floor(ew * 0.6)
	local height = math.floor(eh / 2)

	w.previeww = vim.api.nvim_open_win(w.buff, true, {
		relative = 'editor',
		row = math.floor((eh - height) / 2),
		col = math.floor((ew - width) / 2),
		width = width,
		height = height,
		border = "double",
		zindex = 101,
	})

	local pattern = string.format("\\%%%dl%s\\C", buf_line, name)
	vim.fn.search(pattern)
	vim.fn.execute("normal zz")

	vim.api.nvim_buf_set_option(w.buff, "modifiable", true)
end

function w.preview_close()
	if w.previeww ~= nil and vim.api.nvim_win_is_valid(w.previeww) then
		vim.api.nvim_win_close(w.previeww, true)
	end

	w.previeww = nil
end

function w.buf_key_binds()
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.symbol_jump, ":lua require'structrue-go'.jump()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.show_others_method_toggle, ":lua require'structrue-go'.hide_others_methods_toggle()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.fold_toggle, ":lua require'structrue-go'.fold_toggle()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.refresh, ":lua require'structrue-go'.refresh()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.preview_open, ":lua require'structrue-go'.preview_open()<cr>", { silent = true })
	-- esc
	vim.api.nvim_buf_set_keymap(w.bufs, "n", "<Esc>", ":lua require'structrue-go'.preview_close()<cr>", { silent = true })
end

return w
