-- symbol parser
local S = {}
require("split")

function S.setup(config)
	S.SymbolKind = {
		F = { "filename", config.symbol.filename.icon, config.symbol.filename.hl },
		p = { "package", config.symbol.package.icon, config.symbol.package.hl },
		n = { "interface", config.symbol.interface.icon, config.symbol.interface.hl },
		i = { "import", config.symbol.import.icon, config.symbol.import.hl },
		m = { "method", {config.symbol.method_current.icon,config.symbol.method_others.icon}, { config.symbol.method_current.hl, config.symbol.method_others.hl } },
		f = { "function", config.symbol.func.icon, config.symbol.func.hl },
		w = { "field", config.symbol.field.icon, config.symbol.field.hl },
		c = { "const", config.symbol.const.icon, config.symbol.const.hl },
		t = { "type", { config.symbol.type.icon, config.symbol.struct.icon }, config.symbol.type.hl },
		v = { "variable",  config.symbol.variable.icon , config.symbol.variable.hl },
		e = { "field", config.symbol.field.icon, config.symbol.field.hl },
	}
	S.cls_hl = config.cursor_symbol_hl
end

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
