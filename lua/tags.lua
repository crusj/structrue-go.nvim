local symbol = require('symbol')
local env = require("env")
local ns = require("namespace")

local tags = {
	fold_status = {}
}
local config = {}

function tags.setup()
	config = require("config").get_data()
end

-- init tags.
function tags.init()
	tags.package                   = nil
	tags.consts                    = {}
	tags.vars                      = {}
	tags.functions                 = {}
	tags.types                     = {}
	tags.interfaces                = {}
	tags.current_file_i_methods    = {}
	tags.imports                   = {}
	tags.current_file_types        = {} -- inclue struct and type
	tags.current_file_s_fields     = {}
	tags.current_file_methods      = {}
	tags.others_file_type          = {}
	tags.others_file_method        = {}
	tags.current_buff_name         = ""
	tags.current_buff_fullname     = ""
	tags.lines                     = { names = {}, lines = {}, lines_reverse = {}, fullnames = {}, highlights = {} }
	tags.hide_others_method_status = false
	tags.open_status               = true -- sg is open?
end

-- run tags parse and write to bufs
function tags.run(buff, bufs, windowf, windows)
	tags.init()

	tags.buff = buff
	tags.bufs = bufs
	tags.windowf = windowf
	tags.windows = windows
	local file_path = tags.get_current_buff_path()
	tags.generate(file_path)
	tags.current_buff_name = string.sub(tags.current_buff_fullname, #file_path + 2)
end

function tags.get_current_buff_path()
	tags.current_buff_fullname = vim.api.nvim_buf_get_name(tonumber(tags.buff))
	return (string.gsub(tags.current_buff_fullname, "/[^/]+$", ""))
end

function tags.re_line(name, fullname, line, highlight)
	tags.lines.names[#tags.lines.names + 1] = name
	tags.lines.fullnames[#tags.lines.fullnames + 1] = fullname
	tags.lines.lines[#tags.lines.lines + 1] = line
	tags.lines.lines_reverse[line] = #tags.lines.lines
	tags.lines.highlights[#tags.lines.highlights + 1] = highlight

end

-- generate tags use gotags.
function tags.generate(path)
	if not env.install_gotags then
		print("Miss gotags")
		return
	end

	local gofiles = path .. env.path_sep .. "*.go"
	vim.fn.jobstart("gotags " .. gofiles, {
		on_stdout = function(id, data, name)
			for index, line in pairs(data) do
				if line == "" or string.sub(line, 1, 1) == "!" then
					goto continue
				end
				tags:group(symbol.New(line))
				::continue::
			end
		end,
		on_exit = function()
			tags.flushToWindow()
		end
	})
end

-- group each tag line.
function tags:group(cut)
	if cut.filename == self.current_buff_fullname then
		if cut.kind == "package" then
			self.package = cut
		elseif cut.kind == "interface" then
			self.interfaces[#self.interfaces + 1] = cut
		elseif cut.kind == "import" then
			self.imports[#self.imports + 1] = cut
		elseif cut.kind == "const" then
			self.consts[#self.consts + 1] = cut
		elseif cut.kind == "variable" then
			self.vars[#self.vars + 1] = cut
		elseif cut.kind == "function" then
			self.functions[#self.functions + 1] = cut
		elseif cut.kind == "type" then
			self.current_file_types[#self.current_file_types + 1] = cut
		elseif cut.kind == "field" then
			self.current_file_s_fields[#self.current_file_s_fields + 1] = cut
		elseif cut.kind == "method" then
			if cut.ntype ~= "" then -- interface method
				self.current_file_i_methods[#self.current_file_i_methods + 1] = cut
			else
				self.current_file_methods[#self.current_file_methods + 1] = cut
			end
		end
	else
		if cut.kind == "type" then
			self.others_file_type[#self.others_file_type + 1] = cut
		elseif cut.kind == "method" then
			self.others_file_method[#self.others_file_method + 1] = cut
		end
	end
end

-- write symbols to window.
function tags.flushToWindow()
	if tags.fold_status[tags.current_buff_fullname] == nil then
		tags.fold_status[tags.current_buff_fullname] = {}
	end

	vim.api.nvim_buf_set_option(tags.bufs, "modifiable", true)

	-- parse filename
	tags.parse_file_name()
	-- parse package
	tags.parse_package()
	-- parse import
	tags.parse_import()
	-- parse const
	tags.parse_const()
	-- parse vars
	tags.parse_var()
	-- parse functions
	tags.parse_func()
	-- parse interfaces
	tags.parse_interface()
	-- parse struct and methods
	tags.parse_c_t_m()
	-- parse method and struct
	tags.parse_c_m_t()

	tags.set_symbols_to_buf()
	tags.highlight_lines()
	vim.api.nvim_buf_set_option(tags.bufs, "modifiable", false)
end

function tags.set_symbols_to_buf()
	vim.api.nvim_buf_set_lines(tags.bufs, 0, -1, false, {})
	local names = {}
	for _, v in ipairs(tags.lines.names) do
		table.insert(names, v[1])
	end
	vim.api.nvim_buf_set_lines(tags.bufs, 0, #names, false, names)
end

function tags.highlight_lines()
	for index, hl in ipairs(tags.lines.highlights) do
		vim.api.nvim_buf_add_highlight(tags.bufs, ns[hl], hl, index - 1, 0, -1)
	end
end

function tags.parse_file_name()
	if config.show_filename == true then
		tags.re_line({ symbol.SymbolKind.F[2] .. "file: " .. tags.current_buff_fullname }, "", -1, "sg_F")
	end
end

function tags.parse_package()
	tags.re_line({ symbol.SymbolKind.p[2] .. "package: " .. tags.package.name }, tags.package.filename, tags.package.line, "sg_p")
end

function tags.parse_import()
	if tags.fold_status[tags.current_buff_fullname]["import"] == nil then
		tags.fold_status[tags.current_buff_fullname]["import"] = config.fold.import
	end

	if #tags.imports > 0 then
		local fold_icon = config.fold_open_icon
		if tags.fold_status[tags.current_buff_fullname]["import"] == true then
			fold_icon = config.fold_close_icon
		end

		tags.re_line({ fold_icon .. "import", "import" }, "", -1, "sg_i")

		if tags.fold_status[tags.current_buff_fullname]["import"] == true then
			return
		end

		for _, cut in ipairs(tags.imports) do
			tags.re_line({ "\t" .. symbol.SymbolKind.i[2] .. cut.name }, cut.filename, cut.line, "sg_i")
		end
	end
end

function tags.parse_const()
	if tags.fold_status[tags.current_buff_fullname]["const"] == nil then
		tags.fold_status[tags.current_buff_fullname]["const"] = config.fold.const
	end

	if #tags.consts > 0 then
		local fold_icon = config.fold_open_icon
		if tags.fold_status[tags.current_buff_fullname]["const"] == true then
			fold_icon = config.fold_close_icon
		end

		tags.re_line({ fold_icon .. "const", "const" }, "", -1, "sg_c")

		if tags.fold_status[tags.current_buff_fullname]["const"] == true then
			return
		end

		for _, cut in ipairs(tags.consts) do
			tags.re_line({ "\t" .. symbol.SymbolKind.c[2] .. cut.name }, cut.filename, cut.line, "sg_c")
		end
	end
end

function tags.parse_var()
	if tags.fold_status[tags.current_buff_fullname]["var"] == nil then
		tags.fold_status[tags.current_buff_fullname]["var"] = config.fold.variable
	end

	if #tags.vars >= 1 then
		local fold_icon = config.fold_open_icon
		if tags.fold_status[tags.current_buff_fullname]["var"] == true then
			fold_icon = config.fold_close_icon
		end

		tags.re_line({ fold_icon .. "var", "var" }, "", -1, "sg_v")

		if tags.fold_status[tags.current_buff_fullname]["var"] == true then
			return
		end

		for _, cut in ipairs(tags.vars) do
			tags.re_line({ "\t" .. symbol.SymbolKind.v[2] .. cut.name }, cut.filename, cut.line, "sg_v")
		end
	end
end

function tags.parse_func()
	if tags.fold_status[tags.current_buff_fullname]["func"] == nil then
		tags.fold_status[tags.current_buff_fullname]["func"] = config.fold.func
	end

	if #tags.functions >= 1 then
		local fold_icon = config.fold_open_icon
		if tags.fold_status[tags.current_buff_fullname]["func"] == true then
			fold_icon = config.fold_close_icon
		end
		tags.re_line({ fold_icon .. "func", "func" }, "", -1, "sg_f")

		if tags.fold_status[tags.current_buff_fullname]["func"] == true then
			return
		end

		for _, cut in ipairs(tags.functions) do
			tags.re_line({ "\t" .. symbol.SymbolKind.f[2] .. cut.name .. cut.signature .. cut.type }, cut.filename, cut.line, "sg_f")
		end
	end
end

function tags.parse_interface()
	for _, icut in ipairs(tags.interfaces) do
		if tags.fold_status[tags.current_buff_fullname][icut.name] == nil then
			tags.fold_status[tags.current_buff_fullname][icut.name] = config.fold.interface
		end

		local fold_icon = config.fold_open_icon
		if tags.fold_status[tags.current_buff_fullname][icut.name] == true then
			fold_icon = config.fold_close_icon
		end

		tags.re_line({ fold_icon .. icut.name, icut.filename, icut.name }, icut.filename, icut.line, "sg_i")

		if tags.fold_status[tags.current_buff_fullname][icut.name] == true then
			return
		end

		for _, cut in ipairs(tags.current_file_i_methods) do
			if cut.ntype == icut.name then
				tags.re_line({ string.format("\t %s%s%s %s", symbol.SymbolKind.m[2][1], cut.name, cut.signature, cut.type) }, cut.filename, cut.line, "sg_m_1")
			end
		end
	end
end

-- current file type and methods
function tags.parse_c_t_m()
	for _, tcut in ipairs(tags.current_file_types) do
		if tags.fold_status[tags.current_buff_fullname][tcut.name] == nil then
			tags.fold_status[tags.current_buff_fullname][tcut.name] = config.fold.type
		end

		local fold_icon = config.fold_open_icon
		if tags.fold_status[tags.current_buff_fullname][tcut.name] == true then
			fold_icon = config.fold_close_icon
		end

		local name = fold_icon .. tcut.name
		if tcut.type ~= "struct" then
			name = string.format("%s%s(%s)", fold_icon, tcut.name, tcut.type)
		end
		tags.re_line({ name, tcut.name }, tcut.filename, tcut.line, "sg_t")

		if tags.fold_status[tags.current_buff_fullname][tcut.name] == true then
			goto continue
		end

		for _, fcut in ipairs(tags.current_file_s_fields) do
			if fcut.ctype == tcut.name then
				tags.re_line({ string.format("\t %s%s %s", symbol.SymbolKind.w[2], fcut.name, fcut.type) }, fcut.filename, fcut.line, "sg_w")
			end
		end

		-- current file methods
		for _, mcut in ipairs(tags.current_file_methods) do
			if mcut.ctype == tcut.name then
				tags.re_line({ string.format("\t %s%s%s %s", symbol.SymbolKind.m[2][1], mcut.name, mcut.signature, mcut.type) }, mcut.filename, mcut.line, "sg_m_1")
			end
		end

		if tags.hide_others_method_status then
			goto continue
		end

		for _, mcut in ipairs(tags.others_file_method) do
			if mcut.ctype == tcut.name then
				tags.re_line({ string.format("\t %s%s%s %s", symbol.SymbolKind.m[2][2], mcut.name, mcut.signature, mcut.type) }, mcut.filename, mcut.line, "sg_m_2")
			end
		end
		::continue::
	end
end

-- parse current methods type
function tags.parse_c_m_t()
	-- struct methods
	local sm = {}
	for _, mcut in ipairs(tags.current_file_methods) do
		local find = false
		for _, scut in ipairs(tags.current_file_types) do
			if scut.name == mcut.ctype then
				find = true
				break
			end
		end

		if not find then
			if sm[mcut.ctype] ~= nil then
				table.insert(sm[mcut.ctype], mcut)
			else
				sm[mcut.ctype] = { mcut }
			end
		end
	end


	for sname, methods in pairs(sm) do
		-- search struct
		for _, cut in ipairs(tags.others_file_type) do
			if tags.fold_status[tags.current_buff_fullname][cut.name] == nil then
				tags.fold_status[tags.current_buff_fullname][cut.name] = config.fold.type
			end

			if cut.name == sname then
				local fold_icon = config.fold_open_icon
				if tags.fold_status[tags.current_buff_fullname][cut.name] == true then
					fold_icon = config.fold_close_icon
				end

				local name = fold_icon .. cut.name
				if cut.type ~= "struct" then
					name = string.format("%s%s(%s)", fold_icon, cut.name, cut.type)
				end

				tags.re_line({ name, cut.name }, cut.filename, cut.line, "sg_t")
				if tags.fold_status[tags.current_buff_fullname][cut.name] == true then
					goto continue
				end

				break
			end
		end


		-- find not in current file's struct's methods
		local others_method_start_index = -1
		if not tags.hide_others_method_status then
			others_method_start_index = #methods + 1
			for _, cut in ipairs(tags.others_file_method) do
				if cut.ctype == sname then
					methods[#methods + 1] = cut
				end
			end
		end

		for index, mcut in ipairs(methods) do
			local hl = "sg_m_1"
			local icon = symbol.SymbolKind.m[2][1]
			if index > others_method_start_index - 1 then
				hl   = "sg_m_2"
				icon = symbol.SymbolKind.m[2][2]

			end
			tags.re_line({ string.format("\t %s%s%s %s", icon, mcut.name, mcut.signature, mcut.type) }, mcut.filename, mcut.line, hl)
		end
		::continue::

	end

end

function tags.jump(line)
	local jump_line = tags.lines.lines[line]
	if tags.lines.fullnames[line] ~= "" then
		vim.api.nvim_set_current_win(tags.windowf)
		if tags.lines.fullnames[line] ~= tags.current_buff_fullname then
			vim.cmd("e " .. tags.lines.fullnames[line])
		end
		if jump_line ~= 0 then
			vim.cmd("execute  \"normal! " .. jump_line .. "G;zz\"")
			vim.cmd("execute  \"normal! zz\"")
		end
	end
end

function tags.hide_others_methods_toggle()
	tags.lines = { names = {}, lines = {}, fullnames = {}, highlights = {}, lines_reverse = {} }
	if tags.hide_others_method_status then
		tags.show_others_methods()
	else
		tags.hide_others_methods()
	end

end

function tags.show_others_methods()
	tags.hide_others_method_status = false
	tags.flushToWindow()
end

function tags.hide_others_methods()
	tags.hide_others_method_status = true
	tags.flushToWindow()
end

function tags.refresh()
	local buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(buf)
	if buf_name ~= tags.current_buff_fullname then
		tags.init()
		tags.buff = buf
		local file_path = tags.get_current_buff_path()
		tags.generate(file_path)
	end
end

function tags.update_fold_status(data)
	if tags.fold_status[tags.current_buff_fullname] == nil then
		tags.fold_status[data.current_buff_fullname] = {}
	end
	tags.fold_status[data.current_buff_fullname][data.symbol] = data.symbol.is_fold
end

-- fold symbol
function tags.fold_toggle()
	local line = vim.api.nvim_exec("echo line('.')", true)
	if line == nil then
		return
	end
	line = tonumber(line)
	if line == nil then
		return
	end
	local cursor_symbol = tags.lines.names[line][2]
	if cursor_symbol == nil then
		return
	end

	tags.fold_status[tags.current_buff_fullname][cursor_symbol] = not tags.fold_status[tags.current_buff_fullname][cursor_symbol]
	tags.lines                                                  = { names = {}, lines = {}, lines_reverse = {}, fullnames = {}, highlights = {} }
	tags.flushToWindow()
	vim.cmd("execute  \"normal! " .. line .. "G;zz\"")

end

return tags
