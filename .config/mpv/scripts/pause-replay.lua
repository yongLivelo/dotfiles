mp.add_forced_key_binding("SPACE", "space-replay", function()
	local eof = mp.get_property_bool("eof-reached", false)

	if eof then
		-- If the video is at the end, go to the start and play
		mp.command("seek 0 absolute")
		mp.set_property_bool("pause", false)
	else
		-- If the video is still playing, do the normal play/pause toggle
		mp.command("cycle pause")
	end
end)
