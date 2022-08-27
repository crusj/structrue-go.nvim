require('structrue-go.split')
local s = require('structrue-go.symbol')

local tags = [[
AddBufferHighlight	api.go	2643;"	m	access:public	ctype:Nvim	line:2643	signature:(buffer Buffer, srcID int, hlGroup string, line int, startCol int, endCol int)	type:int, error
Login	/Users/crusj/Project/admin-go/server/auth.go	37;"	m	access:public	ctype:AuthServer	line:37	signature:(ctx *fasthttp.RequestCtx)
]]

for _, each in ipairs(tags:split_s("\n")) do
	local cut = s.New(each)
	for k, v in pairs(cut) do
		print(k, v)
	end
end
