--- @sync entry

return {
	setup = function()
		ps.sub("cd", function()
			local cwd = cx.active.current.cwd
			os.execute("zoxide add " .. ya.quote(tostring(cwd)) .. " &")
		end)
	end,
}
