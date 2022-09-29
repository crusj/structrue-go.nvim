local symbol = require('structrue-go.symbol')
local ns = require("structrue-go.namespace")
local w = require("structrue-go.window")

local tags = {
	fold_status = {},
	indent = "\t"
}

local config

function tags.setup()
	config = require("structrue-go.config").get_data()
	if config.indent ~= nil and config.indent ~= "" then
		tags.indent = config.indent .. " "
	end
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

-- get file path include.
function tags.get_current_buff_path()
	tags.current_buff_fullname = vim.api.nvim_buf_get_name(tonumber(w.buff))
	return (string.gsub(tags.current_buff_fullname, "/[^/]+$", ""))
end

-- record line data.
function tags.re_line(name, fullname, line, highlight)
	tags.lines.names[#tags.lines.names + 1] = name
	tags.lines.fullnames[#tags.lines.fullnames + 1] = fullname
	tags.lines.lines[#tags.lines.lines + 1] = line

	if highlight ~= "sg_m_2" then
		tags.lines.lines_reverse[line] = #tags.lines.lines
	end

	tags.lines.highlights[#tags.lines.highlights + 1] = highlight

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

-- write symbols to buff.
function tags.flush_to_bufs()
	w.create_buf()

	if tags.fold_status[tags.current_buff_fullname] == nil then
		tags.fold_status[tags.current_buff_fullname] = {}
	end

	vim.api.nvim_buf_set_option(w.bufs, "modifiable", true)

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

	vim.api.nvim_buf_set_option(w.bufs, "modifiable", false)
end

-- flush symbols to structrue-go window.
function tags.set_symbols_to_buf()
	vim.api.nvim_buf_set_lines(w.bufs, 0, -1, false, {})
	local names = {}
	for _, v in ipairs(tags.lines.names) do
		table.insert(names, v[1])
	end
	vim.api.nvim_buf_set_lines(w.bufs, 0, #names, false, names)
end

-- highlight structrue-go lines.
function tags.highlight_lines()
	for index, hl in ipairs(tags.lines.highlights) do
		vim.api.nvim_buf_add_highlight(w.bufs, ns[hl], hl, index - 1, 3, -1)
	end
end

function tags.parse_file_name()
	if config.show_filename == true then
		tags.re_line({ symbol.SymbolKind.fi[2] .. "file: " .. tags.current_buff_fullname }, "", -1, "sg_fi")
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

		tags.re_line({ fold_icon .. "P import", "import" }, "", -1, "sg_i")

		if tags.fold_status[tags.current_buff_fullname]["import"] == true then
			return
		end

		for _, cut in ipairs(tags.imports) do
			tags.re_line({ tags.indent .. symbol.SymbolKind.i[2] .. cut.name, cut.name }, cut.filename, cut.line, "sg_i")
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

		tags.re_line({ fold_icon .. "C const", "const" }, "", -1, "sg_c")

		if tags.fold_status[tags.current_buff_fullname]["const"] == true then
			return
		end

		for _, cut in ipairs(tags.consts) do
			tags.re_line({ tags.indent .. symbol.SymbolKind.c[2] .. cut.name, cut.name }, cut.filename, cut.line, "sg_c")
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

		tags.re_line({ fold_icon .. "V var", "var" }, "", -1, "sg_v")

		if tags.fold_status[tags.current_buff_fullname]["var"] == true then
			return
		end

		for _, cut in ipairs(tags.vars) do
			tags.re_line({ tags.indent .. symbol.SymbolKind.v[2] .. cut.name, cut.name }, cut.filename, cut.line, "sg_v")
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
		tags.re_line({ fold_icon .. "F func", "func" }, "", -1, "sg_f")

		if tags.fold_status[tags.current_buff_fullname]["func"] == true then
			return
		end

		for _, cut in ipairs(tags.functions) do
			tags.re_line({ tags.indent .. symbol.SymbolKind.f[2] .. cut.name .. cut.signature .. cut.type, cut.name }, cut.filename, cut.line, "sg_f")
		end
	end
end

function tags.parse_interface()
	for _, icut in ipairs(tags.interfaces) do
		if tags.fold_status[tags.current_buff_fullname][icut.name] == nil then
			tags.fold_status[tags.current_buff_fullname][icut.name] = config.fold.interface
		end

		local show_methods = true
		if tags.fold_status[tags.current_buff_fullname][icut.name] == true then
			show_methods = false
		end

		local i_methods = {}
		local exists_methods = false -- find methods  exists

		for _, cut in ipairs(tags.current_file_i_methods) do
			if cut.ntype == icut.name then
				if show_methods == false then
					exists_methods = true
					break
				else
					table.insert(i_methods, {
						{ string.format("%s%s%s%s %s", tags.indent, symbol.SymbolKind.m[2][1], cut.name, cut.signature, cut.type), cut.name },
						cut.filename,
						cut.line,
						"sg_m_1"
					})
				end
			end
		end

		local i_icon = symbol.SymbolKind.n[2]

		if show_methods == false and exists_methods then -- hide methods and exists methods
			i_icon = config.fold_close_icon
		elseif show_methods == true and #i_methods > 0 then -- show methods and methods least 1
			i_icon = config.fold_open_icon
		end

		tags.re_line({ i_icon .."I ".. icut.name, icut.name }, icut.filename, icut.line, "sg_n")

		if show_methods then
			for _, item in ipairs(i_methods) do
				tags.re_line(item[1], item[2], item[3], item[4])
			end
		end
	end
end

-- current file type and methods.
function tags.parse_c_t_m()
	for _, tcut in ipairs(tags.current_file_types) do
		if tags.fold_status[tags.current_buff_fullname][tcut.name] == nil then
			tags.fold_status[tags.current_buff_fullname][tcut.name] = config.fold.type
		end

		local members = {}
		local show_members = false
		if tags.fold_status[tags.current_buff_fullname][tcut.name] == false then
			show_members = true
		end

		local exists_members = false

		for _, fcut in ipairs(tags.current_file_s_fields) do
			if fcut.ctype == tcut.name then
				if show_members == true then
					table.insert(members, { { string.format("%s%s%s %s", tags.indent, symbol.SymbolKind.w[2], fcut.name, fcut.type), fcut.name }, fcut.filename, fcut.line, "sg_w" })
				else
					exists_members = true
					break
				end
			end
		end

		if show_members == false and exists_members == true then
			goto continue
		end

		-- current file methods
		for _, mcut in ipairs(tags.current_file_methods) do
			if mcut.ctype == tcut.name then
				if show_members == true then
					table.insert(members, { { string.format("%s%s%s%s %s", tags.indent, symbol.SymbolKind.m[2][1], mcut.name, mcut.signature, mcut.type), mcut.name }, mcut.filename, mcut.line, "sg_m_1" })
				else
					exists_members = true
					break
				end
			end
		end

		if show_members == false and exists_members == true then
			goto continue
		end

		if tags.hide_others_method_status then
			goto continue
		end

		for _, mcut in ipairs(tags.others_file_method) do
			if mcut.ctype == tcut.name then
				if show_members == true then
					table.insert(members, {
						{ string.format("%s%s%s%s %s", tags.indent, symbol.SymbolKind.m[2][2], mcut.name, mcut.signature, mcut.type), mcut.name },
						mcut.filename,
						mcut.line,
						"sg_m_2",
					})
				else
					exists_members = true
					break
				end
			end
		end

		::continue::
		local icon = symbol.SymbolKind.t[2][2]
		if tcut.type ~= "struct" then
			icon = symbol.SymbolKind.t[2][1]
		end

		if show_members == false and exists_members then -- hide members and exists members
			icon = config.fold_close_icon
		elseif show_members == true and #members > 0 then -- show members and members least 1
			icon = config.fold_open_icon
		end

		local name = icon .. "T ".. tcut.name
		if tcut.type ~= "struct" then
			name = string.format("%sT %s(%s)", icon, tcut.name, tcut.type)
		end

		tags.re_line({ name, tcut.name }, tcut.filename, tcut.line, "sg_t")

		for _, item in ipairs(members) do
			tags.re_line(item[1], item[2], item[3], item[4])
		end
	end
end

-- parse current methods type
function tags.parse_c_m_t()
	local sm = {}
	-- find methods whose struct not in current file.
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
		if tags.fold_status[tags.current_buff_fullname][sname] == nil then
			tags.fold_status[tags.current_buff_fullname][sname] = config.fold.type
		end

		local show_members = false
		if tags.fold_status[tags.current_buff_fullname][sname] == false then
			show_members = true
		end

		local exists_members = #methods > 0
		local tcut = nil
		-- find not in current file's struct's methods
		local others_method_start_index = -1

		for _, cut in ipairs(tags.others_file_type) do
			if cut.name == sname then
				tcut = cut
				break
			end
		end

		if show_members == false and exists_members == true then
			goto continue
		end

		if not tags.hide_others_method_status then
			others_method_start_index = #methods + 1
			for _, cut in ipairs(tags.others_file_method) do
				if cut.ctype == sname then
					if show_members == true then
						methods[#methods + 1] = cut
					else
						exists_members = true
						break
					end
				end
			end
		end

		::continue::
		local icon = symbol.SymbolKind.t[2][2]
		if tcut.type ~= "struct" then
			icon = symbol.SymbolKind.t[2][1]
		end

		if show_members == false and exists_members then -- hide members and exists members
			icon = config.fold_close_icon
		elseif show_members == true and #methods > 0 then -- show members and members least 1
			icon = config.fold_open_icon
		end

		local name = icon .. tcut.name
		if tcut.type ~= "struct" then
			name = string.format("%s%s(%s)", icon, tcut.name, tcut.type)
		end

		tags.re_line({ name, tcut.name }, tcut.filename, tcut.line, "sg_t")

		if show_members == true then
			for index, mcut in ipairs(methods) do
				local hl = "sg_m_1"
				icon = symbol.SymbolKind.m[2][1]
				if index > others_method_start_index - 1 then
					hl   = "sg_m_2"
					icon = symbol.SymbolKind.m[2][2]
				end

				tags.re_line({ string.format("%s%s%s%s %s", tags.indent, icon, mcut.name, mcut.signature, mcut.type), mcut.name }, mcut.filename, mcut.line, hl)
			end
		end

	end
end

function tags.jump(line)
	local jump_line = tags.lines.lines[line]
	local name = tags.lines.names[line][2]
	local pattern = string.format("\\%%%dl%s\\C", jump_line, name)

	if tags.lines.fullnames[line] ~= "" then
		vim.api.nvim_set_current_win(w.bufw)
		if tags.lines.fullnames[line] ~= tags.current_buff_fullname then
			vim.cmd("e " .. tags.lines.fullnames[line])
		end

		if jump_line ~= 0 then
			vim.fn.search(pattern)
			vim.fn.execute("normal zz")
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
	tags.flush_to_bufs()
end

function tags.hide_others_methods()
	tags.hide_others_method_status = true
	tags.flush_to_bufs()
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
	tags.flush_to_bufs()
    vim.api.nvim_win_set_cursor(0,{line,0})
end

return tags
