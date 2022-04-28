local symbol = require('symbol')

local tags = {}

-- init tags.
function tags.init()
	tags.consts                 = {}
	tags.vars                   = {}
	tags.functions              = {}
	tags.currentFileStructs     = {}
	tags.currentFileMethods     = {}
	tags.currentFileLeftMethods = {}
	tags.othersFileStructs      = {}
	tags.othersFileMethods      = {}
	tags.current_buff_name      = ""
	tags.current_buff_fullname  = ""
	tags.highlight_lines        = {}

	tags.next_line_start = 0

end

-- run tags parse and write to bufs
function tags.run(buff, bufs, windows)
	tags.init()

	tags.buff = buff
	tags.bufs = bufs
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
		if cut.kind == "const" then
			self.consts[#self.consts + 1] = cut
		elseif cut.kind == "variable" then
			self.vars[#self.vars + 1] = cut
		elseif cut.kind == "function" then
			self.functions[#self.functions + 1] = cut
		elseif cut.kind == "type" and cut.type == "struct" then
			self.currentFileStructs[#self.currentFileStructs + 1] = cut
		elseif cut.kind == "method" then
			self.currentFileMethods[#self.currentFileMethods + 1] = cut
		end
		print(cut.kind)
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
	-- flush const
	tags.flushConstToWindow()
	-- flush vars
	tags.flushVarsToWindow()
	-- flush functions
	tags.flushFunctionsToWindow()
	-- flush struct and methods
	tags.flushCurrentFileStructAndAllMethodsToWindow()
	-- flush method and struct
	tags.flushCurrentFileMethodsAndStructToWindow()

	tags.highlight()
end

function tags.highlight()
	for _, line in ipairs(tags.highlight_lines) do
		vim.api.nvim_buf_add_highlight(tags.bufs, -1, "Folded", line, 0, -1)
	end
end

function tags.flushConstToWindow()
	local consts = {
		"Constant",
	}
	for _, cut in ipairs(tags.consts) do
		consts[#consts + 1] = "\t" .. cut.name
	end

	if #consts > 1 then
		vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, consts)
		-- vim.api.nvim_buf_add_highlight(tags.bufs,-1,"Folded",0,0,-1)
		tags.next_line_start = #tags.consts + 1
	end
end

function tags.flushVarsToWindow()
	local vars = {
		"Variable"
	}

	for _, cut in ipairs(tags.vars) do
		vars[#vars + 1] = "\t" .. cut.name
	end

	if #vars > 1 then
		vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, vars)
		tags.next_line_start = tags.next_line_start + #tags.vars + 1
	end
end

function tags.flushFunctionsToWindow()
	local functions = {
		"Function"
	}
	for _, cut in ipairs(tags.functions) do
		functions[#functions + 1] = "\t" .. cut.name .. cut.signature .. cut.type
	end

	if #functions > 1 then
		vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, functions)
		tags.next_line_start = tags.next_line_start + #tags.functions + 1
	end
end

function tags.flushCurrentFileStructAndAllMethodsToWindow()
	for _, scut in ipairs(tags.currentFileStructs) do
		-- flush struct
		vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, { scut.name })
		tags.next_line_start = tags.next_line_start + 2

		-- local file methods
		local lm = {}
		for _, mcut in ipairs(tags.currentFileMethods) do
			if mcut.ctype == scut.name then
				lm[#lm + 1] = "\t" .. mcut.name .. mcut.signature
			else
			end
		end
		if #lm > 0 then
			vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, lm)
			tags.next_line_start = tags.next_line_start + #lm + 1
		end

		-- others file methods
		local om = {}
		for _, mcut in ipairs(tags.othersFileMethods) do
			if mcut.ctype == scut.name then
				om[#om + 1] = "\t" .. mcut.name .. mcut.signature
			end
		end
		if #om > 0 then
			vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, om)
			for i = 1, #om do
				tags.highlight_lines[#tags.highlight_lines + 1] = tags.next_line_start + i - 3
			end
			tags.next_line_start = tags.next_line_start + #om + 1
		end
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

		if not find then
			if sm[mcut.ctype] ~= nil then
				table.insert(sm[mcut.ctype], mcut)
			else
				sm[mcut.ctype] = { mcut }
			end
		end
	end


	for sname, methods in pairs(sm) do
		-- find not in current file's struct's methods
		for _, cut in ipairs(tags.othersFileMethods) do
			if cut.ctype == sname then
				methods[#methods + 1] = cut
				tags.highlight_lines[#tags.highlight_lines + 1] = tags.next_line_start + #methods - 4
			end
		end

		-- flush struct
		vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, { sname })
		tags.highlight_lines[#tags.highlight_lines + 1] = tags.next_line_start - 4
		tags.next_line_start = tags.next_line_start + 2

		local om = {}
		for _, mcut in ipairs(methods) do
			om[#om + 1] = "\t" .. mcut.name .. mcut.signature
		end

		-- flush method
		if #om > 0 then
			vim.api.nvim_buf_set_lines(tags.bufs, tags.next_line_start, -1, false, om)
			tags.next_line_start = tags.next_line_start + #om + 1
		end
	end

end

return tags
