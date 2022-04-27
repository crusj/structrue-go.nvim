local symbol = require('symbol')

local Tags = {
	consts = {},
	vars = {},
	functions = {},
	currentFileStructs = {},
	currentFileMethods = {},
	currentFileLeftMethods = {},
	othersFileStructs = {},
	otherFileMethods = {},
}
-- generate tags use gotags.
function Tags:generate(path)
	if not self.checkBin then
		print('gotags is not found.')
		return
	end

	local tags = vim.api.nvim_exec("gotags " .. path .. "/*.go")
	local cuts = {}
	for _, each in ipairs(tags:split("\n")) do
		local cut = symbol:New(each)
		table.insert(cuts, cut)
	end

end

-- check gotags is exists.
function Tags:checkBin()
	return true
end

-- group each tag line.
function Tags:group(cut)
	if cut.filename == self.bufname then
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
function Tags:flushToWindow()
	-- flush const
	self:flushConstToWindow()
	-- flush vars
	self:flushVarsToWindow()
	-- flush functions
	self:flushFunctionsToWindow()
end

function Tags:flushConstToWindow()
	for _, cut in ipairs(self.consts) do
	end
end

function Tags:flushVarsToWindow()
	for _, cut in ipairs(self.vars) do
	end
end

function Tags:flushFunctionsToWindow()
	for _, cut in ipairs(self.functions) do
	end
end

function Tags:flushCurrentFileStructAndAllMethodsToWindow()
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

function Tags:flushCurrentFileMethodsAndStructToWindow()
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
function Tags:init()

end

return Tags
