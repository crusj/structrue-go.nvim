-- split string by sep
function string:split_s(sep)
	local cuts = {}
	for v in string.gmatch(self, "[^'" .. sep .. "']+") do
		table.insert(cuts,v)
	end

	return cuts
end
