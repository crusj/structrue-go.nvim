local tags = require("structrue-go.tags")
local hl = require("structrue-go.highlight")


local config = {}
local event = {
	previewf = nil
}

function event.setup()
    config = require("structrue-go.config").get_data()
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

	event.global_key_binds()
end

-- buf enter refresh symbols info
function event.enter()
	if tags.open_status == true then
		tags.refresh()
	end
end

function event.global_key_binds()
	vim.api.nvim_set_keymap("n", config.keymap.toggle, ":lua require'structrue-go'.toggle()<cr>", { silent = true })
	vim.api.nvim_set_keymap("n", config.keymap.preview_close, ":lua require'structrue-go'.preview_close()<cr>", { silent = true })
end

return event
