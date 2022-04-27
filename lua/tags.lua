local symbol = require('symbol')

local tags = {
	consts                 = {},
	vars                   = {},
	functions              = {},
	currentFileStructs     = {},
	currentFileMethods     = {},
	currentFileLeftMethods = {},
	othersFileStructs      = {},
	othersFileMethods      = {},
	current_buff_name      = "",
	current_buff_fullname  = ""
}

function tags.run(buff, bufs, windows)
	print(buff)
	tags.buff = buff
	tags.bufs = bufs
	tags.windows = windows
	local file_path = tags.get_current_buff_path()
	tags.generate(file_path)

	tags.current_buff_name = string.sub(tags.current_buff_fullname, #file_path + 2)
	print(tags.current_buff_name, tags.current_buff_fullname)
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
			tags:flushToWindow()
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
		if cut.kind == "const" then
			self.consts[#self.consts + 1] = cut
		elseif cut.kind == "variable" then
			self.vars[#self.vars + 1] = cut
		elseif cut.kind == "function" then
			self.functions[#self.functions + 1] = cut
		elseif cut.kind == "struct" then
			self.currentFileStructs[#self.currentFileStructs + 1] = cut
		elseif cut.kind == "method" then
			self.currentFileMethods[#self.currentFileMethods + 1] = cut
		end
	else
		if cut.kind == "struct" then
			self.othersFileStructs[#self.othersFileStructs + 1] = cut
		elseif cut.kind == "method" then
			self.othersFileMethods[#self.othersFileMethods + 1] = cut
		end
	end
end

-- write symbols to window.
function tags:flushToWindow()
	-- flush const
	self:flushConstToWindow()
	-- flush vars
	self:flushVarsToWindow()
	-- flush functions
	self:flushFunctionsToWindow()
end

function tags:flushConstToWindow()
	for index, cut in ipairs(self.consts) do
		print(tonumber(tags.bufs), cut.name, index, #cut.name)
		vim.api.nvim_buf_set_lines(tonumber(tags.bufs), index - 1, -1, 0,{ cut.name })
	end
end

function tags:flushVarsToWindow()
	for _, cut in ipairs(self.vars) do
	end
end

function tags:flushFunctionsToWindow()
	for _, cut in ipairs(self.functions) do
	end
end

function tags:flushCurrentFileStructAndAllMethodsToWindow()
	for _, scut in ipairs(self.currentFileStructs) do
		-- flush struct

		-- local file methods
		for _, mcut in ipairs(self.currentFileMethods) do
			if mcut.ctype == scut.name then
			else
			end
		end

		-- others file methods
		for _, mcut in ipairs(self.otherFileMethods) do
			if mcut.ctype == scut.name then

			end
		end
	end
end

function tags:flushCurrentFileMethodsAndStructToWindow()
	local sm = {}
	for _, mcut in ipairs(self.currentFileMethods) do
		local find = false
		for _, scut in ipairs(self.currentFileStructs) do
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
		-- flush struct
		for _, mcut in ipairs(methods) do
			-- flush method
		end
	end

end

-- init tags.
function tags:init()

end

return tags
