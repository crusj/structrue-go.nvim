local tags = require('structrue-go.tags')
local symbol = require("structrue-go.symbol")
local ns = require("structrue-go.namespace")
local w = require("structrue-go.window")

local hl = {
	last_buff_line = nil,
	cls_timer = nil,
}

function hl.setup()
	hl.register_namespace()
end

function hl.register_namespace()
	for k, v in pairs(symbol.SymbolKind) do
		if k == "m" then
			vim.cmd(string.format("highlight %s_1 %s", "sg_" .. k, v[3][1]))
			ns["sg_" .. k .. "_1"] = vim.api.nvim_create_namespace(v[3][1])
			vim.cmd(string.format("highlight %s_2 %s", "sg_" .. k, v[3][2]))
			ns["sg_" .. k .. "_2"] = vim.api.nvim_create_namespace(v[3][2])
		else
			vim.cmd(string.format("highlight %s %s", "sg_" .. k, v[3]))
			ns["sg_" .. k] = vim.api.nvim_create_namespace(v[3])
		end
	end
	vim.cmd("highlight sg_cls " .. symbol.cls_hl)
	ns["sg_cls"] = vim.api.nvim_create_namespace(symbol.cls_hl)
end

function hl.stop_hl_cls()
	if hl.cls_timer ~= nil then
		hl.cls_timer:close()
		hl.cls_timer = nil
	end
end

function hl.start_hl_cls()
	if hl.cls_timer ~= nil then
		return
	end

	hl.cls_timer = vim.loop.new_timer()
	hl.cls_timer:start(0, 1000, vim.schedule_wrap(function()
		-- vim.notify(os.time() .. "", vim.log.levels.INFO, {})
		if vim.api.nvim_buf_get_option(0, "filetype") == "go" then
			if tags.open_status == nil or tags.open_status == false then
				return
			end

			local hl_line = hl.get_bufs_hl_line(vim.fn.line("."))

			if hl.hl_line ~= nil then
				vim.api.nvim_buf_clear_namespace(tonumber(w.bufs), ns["sg_cls"], hl.hl_line - 1, hl.hl_line)
				hl.hl_line = nil
			end

			if hl_line ~= nil then
				vim.api.nvim_buf_add_highlight(tonumber(w.bufs), ns["sg_cls"], "sg_cls", hl_line - 1, 3, -1)
				hl.hl_line = hl_line
			end
		end
	end))
end

function hl.get_bufs_hl_line(buff_line)
	local hl_line = tags.lines.lines_reverse[buff_line .. ""]
	hl.last_buf_line = buff_line
	if hl_line == nil then
		local tmp_line = buff_line - 2
		local hl_buff_line = nil
		while tmp_line > 0 do
			local prev_line_start_str = vim.api.nvim_buf_get_text(w.buff, tmp_line, 0, tmp_line, 4, {})[1]
			local no_space_str = string.gsub(prev_line_start_str, "%s", "")
			if string.gsub(string.sub(prev_line_start_str, 1, 1), "%s", "") == "" then
				goto continue
			end

			if no_space_str == "func" or no_space_str == "var" or no_space_str == "type" then
				hl_buff_line = tmp_line + 1
				break
			else
				break
			end

			::continue::
			tmp_line = tmp_line - 1
		end

		if hl_buff_line ~= nil then
			hl_line = tags.lines.lines_reverse[hl_buff_line .. ""]
		end
	else
		hl_line = tags.lines.lines_reverse[buff_line .. ""]
	end

	return hl_line
end

return hl
