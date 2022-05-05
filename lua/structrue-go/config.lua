local config = {
	data = nil
}

function config.setup(user_config)
	config.data = {
		show_filename = true, -- bool
		number = "no", -- show number: no | nu | rnu
		fold_open_icon = " ",
		fold_close_icon = " ",
		cursor_symbol_hl = "guibg=Gray guifg=White", -- symbol hl under cursor,
		indent = "┠", -- Hierarchical indent icon, nil or empty will be a tab
		position = "botright", -- window position,default botright,also can set float
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
			fold_toggle = "\\z",
			refresh = "R", -- refresh symbols
			preview_open = "P", -- preview  symbol toggle
			preview_close = "\\p" -- preview  symbol toggle
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
	if user_config == nil or type(user_config) ~= "table" then
		return
	end

	for dk, dv in pairs(config.data) do
		if type(dv) ~= "table" then
			if user_config[dk] ~= nil then
				config.data[dk] = user_config[dk]
			end
			goto continue
		end

		if (dk == "fold" or dk == "keymap") and user_config[dk] ~= nil then
			for fk, fv in pairs(dv) do
				if user_config[dk][fk] ~= nil then
					config.data[dk][fk] = user_config[dk][fk]
				end
			end
		end

		-- symbol
		if dk == "symbol" and user_config[dk] ~= nil then
			for sk, sv in pairs(dv) do
				if user_config[dk][sk] ~= nil then
					for k, v in pairs(sv) do
						if user_config[dk][sk][k] ~= nil then
							config.data[dk][sk][k] =user_config[dk][sk][k]
						end
					end
				end
			end
		end

		::continue::
	end
end

function config.get_data()
	return config.data
end

return config
