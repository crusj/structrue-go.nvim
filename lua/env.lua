require("split")
local e = {
	is_windows = false,
	path_sep = "/",
	env_sep = ":",

	install_gotags = false,
}

function e.setup()
	e.get_info()
	e.check_gotags()
end

function e.get_info()
	local os_name = vim.loop.os_uname().sysname
	e.is_windows = os_name == "Windows" or os_name == "Windows_NT"
	if e.is_windows then
		e.path_sep = "\\"
		e.env_sep = ";"
	end
end

function e.check_gotags()
	for _, path in ipairs(os.getenv("PATH"):split(e.env_sep)) do
		if vim.loop.fs_stat(path..e.path_sep.."gotags") then
			e.install_gotags = true
			return
		end
	end
end

return e
