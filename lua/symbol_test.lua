require('split')
local s = require('symbol')

local tags = [[
AddBufferHighlight	api.go	2643;"	m	access:public	ctype:Nvim	line:2643	signature:(buffer Buffer, srcID int, hlGroup string, line int, startCol int, endCol int)	type:int, error
]]

for _, each in ipairs(tags:split("\n")) do
	local cut = s.New(each)
	for k, v in pairs(cut) do
		print(k, v)
	end
end
