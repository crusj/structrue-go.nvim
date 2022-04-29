local symbol = require('symbol')

local tags = {}

-- init tags.
function tags.init()
	tags.package                   = nil
	tags.consts                    = {}
	tags.vars                      = {}
	tags.functions                 = {}
	tags.types                     = {}
	tags.interfaces                = {}
	tags.imports                   = {}
	tags.currentFileStructs        = {}
	tags.currentFileMethods        = {}
	tags.currentFileIMethods       = {}
	tags.currentFileLeftMethods    = {}
	tags.othersFileStructs         = {}
	tags.othersFileMethods         = {}
	tags.current_buff_name         = ""
	tags.current_buff_fullname     = ""
	tags.lines                     = { names = {}, lines = {}, icons = {}, fullnames = {} }
	tags.hide_others_method_status = false
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
			if cut.type == "struct" then
				self.currentFileStructs[#self.currentFileStructs + 1] = cut
			else
				self.types[#self.types + 1] = cut
			end
		elseif cut.kind == "method" then
			if cut.ntype ~= "" then -- interface method
				self.currentFileIMethods[#self.currentFileIMethods + 1] = cut
			else
				self.currentFileMethods[#self.currentFileMethods + 1] = cut
			end
		end
	else
		if cut.kind == "type" and cut.type == "struct" then
			self.othersFileStructs[#self.othersFileStructs + 1] = cut
		elseif cut.kind == "method" then
			self.othersFileMethods[#self.othersFileMethods + 1] = cut
		end
	end
end

-- write symbols to window.
function tags.flushToWindow()
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
	-- flush types
	tags.flushTypesToWindow()
	-- flush functions
	tags.flushFunctionsToWindow()
	-- flush interfaces
	tags.flushInterfacesToWindow()
	-- flush struct and methods
	tags.flushCurrentFileStructAndAllMethodsToWindow()
	-- flush method and struct
	tags.flushCurrentFileMethodsAndStructToWindow()

	tags.set_symbols_to_buf()
	tags.highlight_extra()
end

function tags.set_symbols_to_buf()
	vim.api.nvim_buf_set_lines(tags.bufs, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(tags.bufs, 0, #tags.lines.names, false, tags.lines.names)
end

function tags.highlight_extra()
	for index, fullname in ipairs(tags.lines.fullnames) do
		if fullname ~= "" and fullname ~= tags.current_buff_fullname then
			vim.api.nvim_buf_add_highlight(tags.bufs, -1, "Folded", index - 1, 0, -1)
		end
	end
end

function tags.flushFileNameToWindow()
	tags.lines.names[#tags.lines.names + 1] = "File: " .. tags.current_buff_fullname
	tags.lines.fullnames[#tags.lines.fullnames + 1] = ""
	tags.lines.lines[#tags.lines.lines + 1] = -1
end

function tags.flushPackageToWindow()
	tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.p[2] .. " Package: " .. tags.package.name
	tags.lines.fullnames[#tags.lines.fullnames + 1] = tags.package.filename
	tags.lines.lines[#tags.lines.lines + 1] = tags.package.line
end

function tags.flushImportsToWindow()
	if #tags.imports > 0 then
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.i[2] .. "Import"
		tags.lines.fullnames[#tags.lines.fullnames + 1] = ""
		tags.lines.lines[#tags.lines.lines + 1] = -1

		for _, cut in ipairs(tags.imports) do
			tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.i[2] .. cut.name
			tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
			tags.lines.lines[#tags.lines.lines + 1] = cut.line
		end
	end
end

function tags.flushConstToWindow()
	if #tags.consts > 0 then
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.c[2] .. "Constant"
		tags.lines.fullnames[#tags.lines.fullnames + 1] = ""
		tags.lines.lines[#tags.lines.lines + 1] = -1

		for _, cut in ipairs(tags.consts) do
			tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.c[2] .. cut.name
			tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
			tags.lines.lines[#tags.lines.lines + 1] = cut.line
		end
	end
end

function tags.flushVarsToWindow()
	if #tags.vars >= 1 then
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.v[2] .. "Variable"
		tags.lines.fullnames[#tags.lines.fullnames + 1] = ""
		tags.lines.lines[#tags.lines.lines + 1] = -1

		for _, cut in ipairs(tags.vars) do
			tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.v[2] .. cut.name
			tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
			tags.lines.lines[#tags.lines.lines + 1] = cut.line
		end
	end
end

function tags.flushTypesToWindow()
	if #tags.vars >= 1 then
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.t[2][1] .. "Type"
		tags.lines.fullnames[#tags.lines.fullnames + 1] = ""
		tags.lines.lines[#tags.lines.lines + 1] = -1

		for _, cut in ipairs(tags.types) do
			tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.t[2][1] .. cut.name
			tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
			tags.lines.lines[#tags.lines.lines + 1] = cut.line
		end
	end
end

function tags.flushFunctionsToWindow()
	if #tags.functions >= 1 then
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.f[2] .. "Function"
		tags.lines.fullnames[#tags.lines.fullnames + 1] = ""
		tags.lines.lines[#tags.lines.lines + 1] = -1

		for _, cut in ipairs(tags.functions) do
			tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.f[2] .. cut.name .. cut.signature .. cut.type
			tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
			tags.lines.lines[#tags.lines.lines + 1] = cut.line
		end
	end
end

function tags.flushInterfacesToWindow()
	for _, icut in ipairs(tags.interfaces) do
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.n[2] .. icut.name
		tags.lines.fullnames[#tags.lines.fullnames + 1] = icut.filename
		tags.lines.lines[#tags.lines.lines + 1] = icut.line
		for _, cut in ipairs(tags.currentFileIMethods) do
			if cut.ntype == icut.name then
				tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.m[2] .. cut.name .. cut.signature .. cut.type
				tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
				tags.lines.lines[#tags.lines.lines + 1] = cut.line
			end
		end
	end
end

function tags.flushCurrentFileStructAndAllMethodsToWindow()
	for _, scut in ipairs(tags.currentFileStructs) do
		tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.t[2][2] .. scut.name
		tags.lines.fullnames[#tags.lines.fullnames + 1] = scut.filename
		tags.lines.lines[#tags.lines.lines + 1] = scut.line

		for _, mcut in ipairs(tags.currentFileMethods) do
			if mcut.ctype == scut.name then
				tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.m[2] .. mcut.name .. mcut.signature .. mcut.type
				tags.lines.fullnames[#tags.lines.fullnames + 1] = mcut.filename
				tags.lines.lines[#tags.lines.lines + 1] = mcut.line
			end
		end

		if tags.hide_others_method_status then
			goto continue
		end

		for _, mcut in ipairs(tags.othersFileMethods) do
			print(mcut.name, mcut.signature)
			if mcut.ctype == scut.name then
				tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.m[2] .. mcut.name .. mcut.signature .. mcut.type
				tags.lines.fullnames[#tags.lines.fullnames + 1] = mcut.filename
				tags.lines.lines[#tags.lines.lines + 1] = mcut.line
			end
		end
		::continue::
	end
end

function tags.flushCurrentFileMethodsAndStructToWindow()
	-- struct methods
	local sm = {}
	for _, mcut in ipairs(tags.currentFileMethods) do
		local find = false
		for _, scut in ipairs(tags.currentFileStructs) do
			if scut.name == mcut.ctype then
				find = true
				break
			end
		end

		print(mcut.name, mcut.ctype)
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
		for _, cut in ipairs(tags.othersFileStructs) do
			if cut.name == sname then
				tags.lines.names[#tags.lines.names + 1] = symbol.SymbolKind.t[2][2] .. cut.name
				tags.lines.fullnames[#tags.lines.fullnames + 1] = cut.filename
				tags.lines.lines[#tags.lines.lines + 1] = cut.line
				break
			end
		end

		-- find not in current file's struct's methods
		if not tags.hide_others_method_status then
			for _, cut in ipairs(tags.othersFileMethods) do
				if cut.ctype == sname then
					methods[#methods + 1] = cut
				end
			end
		end

		for _, mcut in ipairs(methods) do
			tags.lines.names[#tags.lines.names + 1] = "\t" .. symbol.SymbolKind.m[2] .. mcut.name
			tags.lines.fullnames[#tags.lines.fullnames + 1] = mcut.filename
			tags.lines.lines[#tags.lines.lines + 1] = mcut.line
		end

	end

end

function tags.jump(line)
	local jump_line = tags.lines.lines[line]
	if tags.lines.fullnames[line] ~= "" then
		vim.api.nvim_set_current_win(tags.windowf)
		if tags.lines.fullnames[line] ~= tags.current_buff_fullname then
			vim.cmd("e " .. tags.lines.fullnames[line])
			tags.init()
			tags.buff = vim.api.nvim_get_current_buf()
			local file_path = tags.get_current_buff_path()
			tags.generate(file_path)
		end
		if jump_line ~= 0 then
			vim.cmd("execute  \"normal! " .. jump_line .. "G;zz\"")
			vim.cmd("execute  \"normal! zz\"")
		end
	end
end

function tags.hide_others_methods_toggle()
	tags.lines = { names = {}, lines = {}, icons = {}, fullnames = {} }
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

return tags
