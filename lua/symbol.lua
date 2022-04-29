-- symbol parser
local S = {
	SymbolKind = {
		n = { "interface", "❙ " },
		i = { "import", "⍺ " },
		m = { "method", "◨ " },
		f = { "function", "◧ " },
		w = { "field", "▪ " },
		c = { "const", "π " },
		t = { "type", { "▱ ", "❏ " } },
		v = { "variable", "◈ " },
		p = { "package", "⊞" }
	}
}


-- parse tag line
function S.New(tagline)
	local cuts = {}
	for cut in string.gmatch(tagline, "%C+") do
		local sp = cut:split(":")

		if #sp == 2 then
			cuts[sp[1]] = sp[2]
		else
			table.insert(cuts, cut)
		end
	end

	print(cuts[4])
	return {
		name = cuts[1],
		filename = cuts[2],
		line = cuts["line"],
		kind = S.SymbolKind[cuts[4]][1],
		access = cuts["access"] or "public",
		signature = cuts["signature"] or "",
		ctype = cuts["ctype"],
		ntype = cuts["ntype"] or "",
		type = cuts["type"] or ""
	}
end

return S
