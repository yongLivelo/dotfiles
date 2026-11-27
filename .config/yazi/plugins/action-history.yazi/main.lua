--- @since 25.12.29

local MAX_HISTORY = 100

local function push_undo(state, entry)
	state._undo_stack = state._undo_stack or {}
	state._redo_stack = {}
	table.insert(state._undo_stack, entry)
	if #state._undo_stack > MAX_HISTORY then
		table.remove(state._undo_stack, 1)
	end
end

local pop_undo = ya.sync(function(state)
	state._undo_stack = state._undo_stack or {}
	if #state._undo_stack == 0 then
		return nil
	end
	return table.remove(state._undo_stack)
end)

local push_undo_sync = ya.sync(function(state, entry, clear_redo)
	state._undo_stack = state._undo_stack or {}
	if clear_redo then
		state._redo_stack = {}
	end
	table.insert(state._undo_stack, entry)
	if #state._undo_stack > MAX_HISTORY then
		table.remove(state._undo_stack, 1)
	end
end)

local pop_redo = ya.sync(function(state)
	state._redo_stack = state._redo_stack or {}
	if #state._redo_stack == 0 then
		return nil
	end
	return table.remove(state._redo_stack)
end)

local push_redo_sync = ya.sync(function(state, entry)
	state._redo_stack = state._redo_stack or {}
	table.insert(state._redo_stack, entry)
	if #state._redo_stack > MAX_HISTORY then
		table.remove(state._redo_stack, 1)
	end
end)

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local function notify(level, msg)
	ya.notify({
		title = "History",
		content = msg,
		timeout = 3,
		level = level,
	})
end

local function run_cmd(program, args)
	local output, err = Command(program):arg(args):output()
	if err then
		return false, tostring(err)
	end
	if not (output and output.status and output.status.success) then
		local stderr = output and output.stderr or ""
		local stdout = output and output.stdout or ""
		local detail = stderr ~= "" and stderr or stdout
		return false, detail ~= "" and detail:gsub("%s+$", "") or (program .. " failed")
	end
	return true, (output.stdout or ""):gsub("%s+$", "")
end

local function path_exists(path)
	return fs.cha(Url(path)) ~= nil
end

local function move_path(from, to)
	if not path_exists(from) then
		return false, "Source missing: " .. from
	end
	if path_exists(to) then
		return false, "Target already exists: " .. to
	end
	local parent = to:match("^(.+)/[^/]+$")
	if parent and parent ~= "" then
		fs.create("dir_all", Url(parent))
	end
	return run_cmd("mv", { "--", from, to })
end

local function trash_paths(paths)
	local existing = {}
	for _, p in ipairs(paths) do
		if path_exists(p) then
			table.insert(existing, p)
		end
	end
	if #existing == 0 then
		return false, "Target file(s) no longer exist"
	end
	local args = { "trash", "--" }
	for _, p in ipairs(existing) do
		table.insert(args, p)
	end
	return run_cmd("gio", args)
end

local function undo_entry(entry)
	if entry.kind == "rename" or entry.kind == "move" then
		local moved = 0
		for i = #entry.items, 1, -1 do
			local it = entry.items[i]
			local ok, err = move_path(it.to, it.from)
			if not ok then
				return false, err
			end
			moved = moved + 1
		end
		return true, string.format("Undid %s (%d item%s)", entry.kind, moved, moved == 1 and "" or "s")
	elseif entry.kind == "create" or entry.kind == "paste" then
		local ok, err = trash_paths(entry.paths)
		if not ok then
			return false, err
		end
		return true,
			string.format("Undid %s (trashed %d item%s)", entry.kind, #entry.paths, #entry.paths == 1 and "" or "s")
	elseif entry.kind == "trash" then
		local ok, err = run_cmd("trash-undo", {})
		if not ok then
			return false, err
		end
		return true, "Restored last trashed batch"
	elseif entry.kind == "delete" then
		return false, "Permanent delete cannot be undone"
	end
	return false, "Unknown history entry: " .. tostring(entry.kind)
end

local function redo_entry(entry)
	if entry.kind == "rename" or entry.kind == "move" then
		local moved = 0
		for _, it in ipairs(entry.items) do
			local ok, err = move_path(it.from, it.to)
			if not ok then
				return false, err
			end
			moved = moved + 1
		end
		return true, string.format("Redid %s (%d item%s)", entry.kind, moved, moved == 1 and "" or "s")
	elseif entry.kind == "create" or entry.kind == "paste" then
		-- Undo trashed the created/pasted paths; redo restores them from trash.
		local ok, err = run_cmd("trash-undo", {})
		if not ok then
			return false, err
		end
		return true, string.format("Redid %s (%d item%s)", entry.kind, #entry.paths, #entry.paths == 1 and "" or "s")
	elseif entry.kind == "trash" then
		local ok, err = run_cmd("trash-redo", {})
		if not ok then
			return false, err
		end
		return true, "Re-trashed restored batch"
	end
	return false, "Nothing to redo for " .. tostring(entry.kind)
end

local M = {}

function M:setup()
	ps.sub("rename", function(body)
		local from = body and (body.from or body.old)
		local to = body and (body.to or body.new)
		if from and to then
			push_undo(self, {
				kind = "rename",
				items = { { from = tostring(from), to = tostring(to) } },
			})
		end
	end)

	ps.sub("move", function(body)
		local items = body and body.items
		if items and #items > 0 then
			local list = {}
			for _, it in ipairs(items) do
				table.insert(list, { from = tostring(it.from), to = tostring(it.to) })
			end
			push_undo(self, { kind = "move", items = list })
		end
	end)

	ps.sub("duplicate", function(body)
		local items = body and body.items
		if items and #items > 0 then
			local paths = {}
			for _, it in ipairs(items) do
				table.insert(paths, tostring(it.to))
			end
			push_undo(self, { kind = "paste", paths = paths })
		end
	end)

	ps.sub("trash", function(body)
		local urls = body and body.urls
		if urls and #urls > 0 then
			local paths = {}
			for _, u in ipairs(urls) do
				table.insert(paths, tostring(u))
			end
			push_undo(self, { kind = "trash", paths = paths })
		end
	end)

	ps.sub("delete", function(body)
		local urls = body and body.urls
		if urls and #urls > 0 then
			local paths = {}
			for _, u in ipairs(urls) do
				table.insert(paths, tostring(u))
			end
			push_undo(self, { kind = "delete", paths = paths })
		end
	end)

	ps.sub("bulk-rename", function(body)
		local changes = body and (body.changes or body)
		if type(changes) == "table" then
			local list = {}
			for from, to in pairs(changes) do
				table.insert(list, { from = tostring(from), to = tostring(to) })
			end
			if #list > 0 then
				push_undo(self, { kind = "rename", items = list })
			end
		end
	end)

	ps.sub("history-create", function(body)
		local paths = body and body.paths
		if paths and #paths > 0 then
			local list = {}
			for _, p in ipairs(paths) do
				table.insert(list, tostring(p))
			end
			push_undo(self, {
				kind = body.kind or "create",
				paths = list,
			})
		end
	end)
end

function M:create()
	local value, event = ya.input({
		title = "Create (trailing / for dir):",
		pos = { "top-center", y = 3, w = 50 },
	})
	if event ~= 1 or not value or value == "" then
		return
	end

	local cwd = Url(get_cwd())
	local is_dir = value:sub(-1) == "/"
	local clean = value:gsub("/+$", "")
	if clean == "" then
		return
	end

	local target = cwd:join(clean)
	if fs.cha(target) then
		return notify("warn", "Already exists: " .. clean)
	end

	local ok, err
	if is_dir then
		ok, err = fs.create("dir_all", target)
	else
		local parent = tostring(target):match("^(.+)/[^/]+$")
		if parent and parent ~= "" then
			fs.create("dir_all", Url(parent))
		end
		ok, err = fs.write(target, "")
	end

	if not ok then
		return notify("error", "Create failed: " .. tostring(err))
	end

	push_undo_sync({
		kind = "create",
		paths = { tostring(target) },
	}, true)
	notify("info", "Created: " .. clean)
end

function M:undo()
	local entry = pop_undo()
	if not entry then
		-- Fallback to trash-undo for batches trashed outside or before this session
		local ok, out = run_cmd("trash-undo", {})
		if ok then
			push_redo_sync({ kind = "trash", paths = {} })
			return notify("info", out ~= "" and out or "Restored last trashed batch")
		end
		return notify("warn", out ~= "" and out or "Nothing to undo")
	end

	local ok, msg = undo_entry(entry)
	if ok then
		if entry.kind ~= "delete" then
			push_redo_sync(entry)
		end
		notify("info", msg)
	else
		push_undo_sync(entry, false)
		notify("error", msg)
	end
end

function M:redo()
	local entry = pop_redo()
	if not entry then
		-- Fallback to trash-redo for batches restored in a previous session
		local ok, out = run_cmd("trash-redo", {})
		if ok then
			push_undo_sync({ kind = "trash", paths = {} }, false)
			return notify("info", out ~= "" and out or "Re-trashed restored batch")
		end
		return notify("warn", out ~= "" and out or "Nothing to redo")
	end

	local ok, msg = redo_entry(entry)
	if ok then
		push_undo_sync(entry, false)
		notify("info", msg)
	else
		push_redo_sync(entry)
		notify("error", msg)
	end
end

function M:entry(job)
	local action = job.args and job.args.action
	if action == "undo" then
		return self:undo()
	elseif action == "redo" then
		return self:redo()
	elseif action == "create" then
		return self:create()
	elseif action == "record" then
		local raw = job.args and job.args.paths or ""
		local paths = {}
		for line in raw:gmatch("[^\n]+") do
			if line ~= "" then
				table.insert(paths, line)
			end
		end
		if #paths > 0 then
			push_undo_sync({
				kind = (job.args and job.args.kind) or "create",
				paths = paths,
			}, true)
		end
		return
	else
		return notify("error", "Unknown history action: " .. tostring(action))
	end
end

return M
