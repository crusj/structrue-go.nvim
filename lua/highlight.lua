local tags = require('tags')
local symbol = require("symbol")
local ns = require("namespace")
local w = require("window")

local hl = {
	last_cls_line = -1,
	last_buff_line = -1,
	cls_timer = nil,
}

function hl.setup()
	hl.register_namespace()
end

function hl.sg_open_handle()
	hl.start_hl_cls()
end

function hl.sg_close_handle()
	hl.last_buff_line = -1
	hl.lasst_cls_line = -1
	hl.stop_hl_cls()
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
	vim.cmd("highlight sg_cls "..symbol.cls_hl)
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
		if vim.api.nvim_buf_get_option(0, "filetype") == "go" then
			if tags.open_status == nil or tags.open_status == false then
				return
			end

			local line = vim.api.nvim_exec("echo line('.')", true)
			if line == nil then
				return
			end
			line = tonumber(line)
			if line == nil then
				return
			end

			if line == hl.last_buff_line then
				return
			end
			hl.last_buf_line = line
			local hl_bufs_line = -1
			if tags.lines.lines_reverse[line .. ""] == nil then
				local tmp_line = line - 2
				local hl_buff_line = -1
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

				if hl_buff_line ~= -1 then
					hl_bufs_line = tags.lines.lines_reverse[hl_buff_line .. ""] or -1
				end
			else
				hl_bufs_line = tags.lines.lines_reverse[line .. ""]
			end

			if hl.last_cls_line ~= -1 then
				local clear_line = hl.last_cls_line
				vim.api.nvim_buf_clear_namespace(tonumber(w.bufs), ns["sg_cls"], clear_line - 1, clear_line)
				hl.last_cls_line = -1
			end

			if hl_bufs_line ~= -1 then
				vim.api.nvim_buf_add_highlight(tonumber(w.bufs), ns["sg_cls"], "sg_cls", hl_bufs_line - 1, 0, -1)
				-- rember last line
				hl.last_cls_line = hl_bufs_line
			end
		end
	end))
end

return hl
