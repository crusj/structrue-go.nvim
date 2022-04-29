local tags = require("tags")
local e = {}

function e.enter()
	if tags.open_status == true then
		tags.refresh()
	end
end

return e
