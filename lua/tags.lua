local symbol = require('symbol')
local ns = require('namespace')

local tags = {}

-- init tags.
function tags.init()
	tags.package                   = nil
	tags.consts                    = {}
	tags.vars                      = {}
	tags.functions                 = {}
	tags.types                     = {}
	tags.interfaces                = {}
	tags.currentFileIMethods       = {}
	tags.imports                   = {}
	tags.currentFileTypes          = {} -- inclue struct and type
	tags.currentFileSFields        = {}
	tags.currentFileMethods        = {}
	tags.othersFileTypes           = {}
	tags.othersFileMethods         = {}
	tags.current_buff_name         = ""
	tags.current_buff_fullname     = ""
	tags.lines                     = { names = {}, lines = {}, lines_reverse = {}, icons = {}, fullnames = {}, highlights = {} }
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
	if not tags.check_bin() then
		print('gotags is not found.')
		return
	end

	local gofiles = path .. "/*.go"
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

-- check gotags is exists.
function tags.check_bin()
	return os.execute("which gotags") == 0
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
			self.currentFileTypes[#self.currentFileTypes + 1] = cut
		elseif cut.kind == "field" then
			self.currentFileSFields[#self.currentFileSFields + 1] = cut
		elseif cut.kind == "method" then
			if cut.ntype ~= "" then -- interface method
				self.currentFileIMethods[#self.currentFileIMethods + 1] = cut
			else
				self.currentFileMethods[#self.currentFileMethods + 1] = cut
			end
		end
	else
		if cut.kind == "type" then
			self.othersFileTypes[#self.othersFileTypes + 1] = cut
		elseif cut.kind == "method" then
			self.othersFileMethods[#self.othersFileMethods + 1] = cut
		end
	end
end

-- write symbols to window.
function tags.flushToWindow()
	vim.api.nvim_buf_set_option(tags.bufs, "modifiable", true)
	-- flush filename
	tags.flushFileNameToWindow()
	-- flush package
	tags.flushPackageToWindow()
	-- flush import
	tags.flushImportsToWindow()
	-- flush const
	tags.flushConstToWindow()
	-- flush vars
	tags.flushVarsToWindow()
	-- flush functions
	tags.flushFunctionsToWindow()
	-- flush interfaces
	tags.flushInterfacesToWindow()
	-- flush struct and methods
	tags.flushCurrentFileTypeAndAllMethodsToWindow()
	-- flush method and struct
	tags.flushCurrentFileMethodsAndTypeToWindow()

	tags.set_symbols_to_buf()
	tags.highlight_lines()
	vim.api.nvim_buf_set_option(tags.bufs, "modifiable", false)
end

function tags.set_symbols_to_buf()
	vim.api.nvim_buf_set_lines(tags.bufs, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(tags.bufs, 0, #tags.lines.names, false, tags.lines.names)
end

function tags.highlight_lines()
	for index, hl in ipairs(tags.lines.highlights) do
		vim.api.nvim_buf_add_highlight(tags.bufs, ns[hl], hl, index - 1, 0, -1)
	end
end

function tags.flushFileNameToWindow()
	tags.re_line("File: " .. tags.current_buff_fullname, "", -1, "sg_F")
end

function tags.flushPackageToWindow()
	tags.re_line(symbol.SymbolKind.p[1] .. " Package: " .. tags.package.name, tags.package.filename, tags.package.line, "sg_p")
end

function tags.flushImportsToWindow()
	if #tags.imports > 0 then
		tags.re_line(symbol.SymbolKind.i[2][1] .. "Import", "", -1, "sg_i")

		for _, cut in ipairs(tags.imports) do
			tags.re_line("\t" .. symbol.SymbolKind.i[2][2] .. cut.name, cut.filename, cut.line, "sg_i")
		end
	end
end

function tags.flushConstToWindow()
	if #tags.consts > 0 then
		tags.re_line(symbol.SymbolKind.c[2][1] .. "Constant", "", -1, "sg_c")

		for _, cut in ipairs(tags.consts) do
			tags.re_line("\t" .. symbol.SymbolKind.c[2][2] .. cut.name, cut.filename, cut.line, "sg_c")
		end
	end
end

function tags.flushVarsToWindow()
	if #tags.vars >= 1 then
		tags.re_line(symbol.SymbolKind.v[2][1] .. "Variable", "", -1, "sg_v")

		for _, cut in ipairs(tags.vars) do
			tags.re_line("\t" .. symbol.SymbolKind.v[2][2] .. cut.name, cut.filename, cut.line, "sg_v")
		end
	end
end

function tags.flushFunctionsToWindow()
	if #tags.functions >= 1 then
		tags.re_line(symbol.SymbolKind.f[2][1] .. "Function", "", -1, "sg_f")

		for _, cut in ipairs(tags.functions) do
			tags.re_line("\t" .. symbol.SymbolKind.f[2][2] .. cut.name .. cut.signature .. cut.type, cut.filename, cut.line, "sg_f")
		end
	end
end

function tags.flushInterfacesToWindow()
	for _, icut in ipairs(tags.interfaces) do
		tags.re_line(symbol.SymbolKind.n[2][1] .. icut.name, icut.filename, icut.line, "sg_i")
		for _, cut in ipairs(tags.currentFileIMethods) do
			if cut.ntype == icut.name then
				tags.re_line(string.format("\t %s%s%s %s", symbol.SymbolKind.m[2][2], cut.name, cut.signature, cut.type), cut.filename, cut.line, "sg_m")
			end
		end
	end
end

function tags.flushCurrentFileTypeAndAllMethodsToWindow()
	for _, tcut in ipairs(tags.currentFileTypes) do
		local icon = symbol.SymbolKind.t[2][3] -- struct icon
		if tcut.type ~= "struct" then
			icon = symbol.SymbolKind.t[2][1]
		end
		local name = icon .. tcut.name
		if tcut.type ~= "struct" then
			name = string.format("%s%s(%s)", icon, tcut.name, tcut.type)
		end
		tags.re_line(name, tcut.filename, tcut.line, "sg_t")

		-- current file fields
		for _, fcut in ipairs(tags.currentFileSFields) do
			if fcut.ctype == tcut.name then
				tags.re_line(string.format("\t %s%s %s", symbol.SymbolKind.w[2], fcut.name, fcut.type), fcut.filename, fcut.line, "sg_w")
			end
		end
		-- current file methods
		for _, mcut in ipairs(tags.currentFileMethods) do
			if mcut.ctype == tcut.name then
				tags.re_line(string.format("\t %s%s%s %s", symbol.SymbolKind.m[2], mcut.name, mcut.signature, mcut.type), mcut.filename, mcut.line, "sg_m_1")
			end
		end

		if tags.hide_others_method_status then
			goto continue
		end

		for _, mcut in ipairs(tags.othersFileMethods) do
			if mcut.ctype == tcut.name then
				tags.re_line(string.format("\t %s%s%s %s", symbol.SymbolKind.m[2], mcut.name, mcut.signature, mcut.type), mcut.filename, mcut.line, "sg_m_2")
			end
		end
		::continue::
	end
end

function tags.flushCurrentFileMethodsAndTypeToWindow()
	-- struct methods
	local sm = {}
	for _, mcut in ipairs(tags.currentFileMethods) do
		local find = false
		for _, scut in ipairs(tags.currentFileTypes) do
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
		for _, cut in ipairs(tags.othersFileTypes) do
			if cut.name == sname then
				local icon = symbol.SymbolKind.t[2][3] -- struct icon
				if cut.type ~= "struct" then
					icon = symbol.SymbolKind.t[2][1]
				end
				local name = icon..cut.name
				if cut.type ~= "struct" then
					name = string.format("%s%s(%s)", icon, cut.name, cut.type)
				end

				tags.re_line(name, cut.filename, cut.line, "sg_t")
				break
			end
		end

		-- find not in current file's struct's methods
		local others_method_start_index = -1
		if not tags.hide_others_method_status then
			others_method_start_index = #methods + 1
			for _, cut in ipairs(tags.othersFileMethods) do
				if cut.ctype == sname then
					methods[#methods + 1] = cut
				end
			end
		end

		for index, mcut in ipairs(methods) do
			local hl = "sg_m_1"
			if index == others_method_start_index - 1 then
				hl = "sg_m_2"
			end
			tags.re_line(string.format("\t %s%s%s %s", symbol.SymbolKind.m[2], mcut.name, mcut.signature, mcut.type), mcut.filename, mcut.line, hl)
		end

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
	tags.lines = { names = {}, lines = {}, icons = {}, fullnames = {}, highlights = {}, lines_reverse = {} }
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

return tags
