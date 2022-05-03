local w = {
	buff = nil,
	bufw = nil,
	bufw_height = 0,

	bufs = nil,
	bufsw = nil,
	bufsw_width = 0,

	previeww = nil
}

local config = nil
function w.setup()
	config = require("structrue-go.config").get_data()
end

function w.create_structrue_window()
	w.bufsw_width = math.floor(vim.api.nvim_win_get_width(w.bufw) / 4)
	vim.cmd('botright vs')
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
	vim.api.nvim_win_set_option(w.bufsw, 'cursorline', false)
	vim.api.nvim_win_set_width(w.bufsw, w.bufsw_width)

	if w.bufs == nil then -- structrue buf
		w.bufs = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(w.bufs, 'structrue')
		vim.api.nvim_buf_set_option(w.bufs, 'filetype', 'structrue-go')
		w.buf_key_binds()
	end

	w.bufw_height = vim.api.nvim_win_get_height(w.bufw)

	vim.api.nvim_win_set_buf(w.bufsw, w.bufs) -- bind buf and window
end

function w.preview_open(buf_line)
	if w.previeww ~= nil and vim.api.nvim_win_is_valid(w.previeww) then
		vim.api.nvim_win_close(w.previeww,true)
	end

	local width = w.bufsw_width
	w.previeww = vim.api.nvim_open_win(w.buff, true, {
		relative = 'win',
		row = 3,
		col = -1 * width * 2 - 5,

		width = width * 2,
		height = math.floor(w.bufw_height / 2),
		border = "double",
	})

	vim.cmd("execute  \"normal! " .. buf_line .. "G;zz\"")
	vim.cmd("execute  \"normal! zz\"")
	vim.api.nvim_buf_set_option(w.buff, "modifiable", true)

	vim.api.nvim_set_current_win(w.bufsw)
end

function w.preview_close()
	if vim.api.nvim_win_is_valid(w.previeww) then
		vim.api.nvim_win_close(w.previeww,true)
	end

	w.previeww = nil
end

function w.buf_key_binds()
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.symbol_jump, ":lua require'structrue-go'.jump()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.show_others_method_toggle, ":lua require'structrue-go'.hide_others_methods_toggle()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.fold_toggle, ":lua require'structrue-go'.fold_toggle()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.refresh, ":lua require'structrue-go'.refresh()<cr>", { silent = true })
	vim.api.nvim_buf_set_keymap(w.bufs, "n", config.keymap.preview_open, ":lua require'structrue-go'.preview_open()<cr>", { silent = true })
end

return w
