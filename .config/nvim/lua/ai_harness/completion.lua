local M = {}

local HARNESS_COMMANDS = {
  agy = {
    { label = "/help", detail = "Show agy help" },
    { label = "/plan", detail = "Enter planning mode" },
    { label = "/compact", detail = "Compact conversation context" },
    { label = "/goal", detail = "Run thorough goal-oriented loop" },
    { label = "/model", detail = "Switch model" },
    { label = "/agents", detail = "List available agents" },
    { label = "/mcp", detail = "Manage MCP servers" },
    { label = "/tasks", detail = "View background tasks" },
    { label = "/keybindings", detail = "Customize keybindings" },
    { label = "/clear", detail = "Clear terminal screen" },
  },
  claude = {
    { label = "/help", detail = "Show Claude Code help" },
    { label = "/compact", detail = "Compact conversation" },
    { label = "/clear", detail = "Clear conversation history" },
    { label = "/model", detail = "Select Claude model" },
    { label = "/review", detail = "Review current changes" },
    { label = "/cost", detail = "Show token usage and cost" },
    { label = "/memory", detail = "Edit CLAUDE.md memory" },
    { label = "/mcp", detail = "Manage MCP servers" },
  },
  opencode = {
    { label = "/help", detail = "Show OpenCode help" },
    { label = "/compact", detail = "Compact session" },
    { label = "/models", detail = "List or switch models" },
    { label = "/sessions", detail = "Switch session" },
    { label = "/new", detail = "Start new session" },
    { label = "/share", detail = "Share session" },
    { label = "/ponytail-audit", detail = "Run ponytail repo audit" },
    { label = "/ponytail-review", detail = "Run ponytail change review" },
    { label = "/ponytail-debt", detail = "List ponytail debt" },
  },
}

---@return table[]
function M.discover_skills()
  local skills = {}
  local seen = {}
  local roots = {
    vim.fn.expand("~/.config/opencode/skills"),
    vim.fn.expand("~/.gemini/antigravity-cli/builtin/skills"),
    vim.fn.expand("~/.gemini/config/plugins/ponytail/skills"),
    vim.fn.getcwd() .. "/.claude/commands",
  }

  for _, root in ipairs(roots) do
    if vim.fn.isdirectory(root) == 1 then
      local handle = vim.uv.fs_scandir(root)
      if handle then
        while true do
          local name, typ = vim.uv.fs_scandir_next(handle)
          if not name then
            break
          end
          if typ == "directory" and not seen[name] then
            seen[name] = true
            table.insert(skills, {
              label = "/" .. name,
              detail = "Skill (" .. vim.fn.fnamemodify(root, ":t") .. ")",
            })
          elseif typ == "file" and name:match("%.md$") then
            local cmd = name:gsub("%.md$", "")
            if not seen[cmd] then
              seen[cmd] = true
              table.insert(skills, { label = "/" .. cmd, detail = "Command" })
            end
          end
        end
      end
    end
  end

  return skills
end

---@param harness string
---@return table[]
function M.get_commands(harness)
  local items = {}
  local seen = {}
  for _, cmd in ipairs(HARNESS_COMMANDS[harness] or {}) do
    seen[cmd.label] = true
    table.insert(items, cmd)
  end
  for _, skill in ipairs(M.discover_skills()) do
    if not seen[skill.label] then
      seen[skill.label] = true
      table.insert(items, skill)
    end
  end
  return items
end

---@param prefix? string
---@return table[]
function M.get_files(prefix)
  local files = {}
  local cmd = vim.fn.executable("rg") == 1 and { "rg", "--files", "--hidden", "--glob", "!.git" }
    or { "find", ".", "-maxdepth", "4", "-type", "f" }
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return files
  end
  local count = 0
  for _, path in ipairs(out) do
    local clean = path:gsub("^%./", "")
    if not prefix or prefix == "" or clean:lower():find(prefix:lower(), 1, true) then
      table.insert(files, { label = "@" .. clean, detail = "Workspace file" })
      count = count + 1
      if count >= 150 then
        break
      end
    end
  end
  return files
end

--- Omnifunc for the AI prompt buffer (<C-x><C-o>)
---@param findstart integer
---@param base string
function M.omnifunc(findstart, base)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  if findstart == 1 then
    local start = before:find("[/@][^%s]*$")
    return start and (start - 1) or -3
  end

  local harness = require("ai_harness").get_active_harness().id
  local results = {}
  if base:sub(1, 1) == "@" then
    local query = base:sub(2)
    for _, item in ipairs(M.get_files(query)) do
      table.insert(results, { word = item.label, menu = item.detail })
    end
  else
    local query = base:lower()
    for _, item in ipairs(M.get_commands(harness)) do
      if query == "" or item.label:lower():find(query, 1, true) then
        table.insert(results, { word = item.label, menu = item.detail })
      end
    end
  end
  return results
end

--- blink.cmp source implementation
function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return vim.b.ai_harness_prompt == true
end

function M:get_trigger_characters()
  return { "/", "@" }
end

function M:get_completions(ctx, callback)
  local line = ctx.line:sub(1, ctx.cursor[2])
  local token = line:match("([/@][^%s]*)$")
  if not token then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return
  end

  local harness = require("ai_harness").get_active_harness().id
  local raw = token:sub(1, 1) == "@" and M.get_files(token:sub(2)) or M.get_commands(harness)
  local items = {}
  for _, entry in ipairs(raw) do
    table.insert(items, {
      label = entry.label,
      insertText = entry.label,
      detail = entry.detail,
      kind = token:sub(1, 1) == "@" and 17 or 14, -- File / Keyword
    })
  end

  callback({
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = items,
  })
end

return M
