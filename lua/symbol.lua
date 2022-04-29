-- symbol parser
local S = {
	SymbolKind = {
		n = { "interface", "❙ ", "guifg=Green" },
		i = { "import", "⍺ ", "guifg=Gray" },
		m = { "method", "◨ ", "guifg=DarkGreen" },
		f = { "function", "◧ ", "guifg=DarkBlue" },
		w = { "field", "▪ ", "guifg=LightGray" },
		c = { "const", "π ", "guifg=Orange" },
		t = { "type", { "▱ ", "❏ " }, "guifg=Purple" },
		v = { "variable", "◈ ", "guifg=Magenta" },
		p = { "package", "⊞", "guifg=Red" },
		F = { "filename", "", "guifg=Black" }
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
