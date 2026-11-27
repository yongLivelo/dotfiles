local M = {}

local HARNESSES = {
  agy = {
    id = "agy",
    name = "Agy",
    bin = "agy",
    cmd = { "agy" },
    model = "gemini-4-hydrogen",
    print_cmd = function(prompt)
      return { "agy", "--print", prompt }
    end,
  },
  claude = {
    id = "claude",
    name = "Claude Code",
    bin = "claude",
    cmd = { "claude" },
    model = "claude-sonnet",
    print_cmd = function(prompt)
      return { "claude", "-p", prompt }
    end,
  },
  opencode = {
    id = "opencode",
    name = "OpenCode",
    bin = "opencode",
    cmd = { "opencode" },
    model = "opencode/big-pickle",
    print_cmd = function(prompt)
      return { "opencode", "run", prompt }
    end,
  },
}

local HARNESS_ORDER = { "agy", "claude", "opencode" }

local TEMPLATES = {
  { name = "Explain selection", text = "Explain what this code does, step by step:\n\n" },
  {
    name = "Refactor & simplify",
    text = "Refactor this code to be simpler and cleaner while preserving behavior:\n\n",
  },
  { name = "Write tests", text = "Write unit tests covering the main paths and edge cases for:\n\n" },
  { name = "Bug & security review", text = "Review this code for bugs, edge cases, and security issues:\n\n" },
  { name = "Fix diagnostics", text = "Fix the LSP/compiler errors in the referenced code:\n\n" },
}

local state = {
  active = "agy",
  status = "idle",
  prompt_buf = nil,
  prompt_win = nil,
  term_buf = nil,
  term_win = nil,
  term_job = nil,
  term_harness = nil,
}

---@return table
function M.get_active_harness()
  return HARNESSES[state.active] or HARNESSES.agy
end

---@return string
function M.statusline()
  local h = M.get_active_harness()
  local icon = state.status == "running" and "󱙺" or "󰚩"
  return string.format("%s %s (%s) [%s]", icon, h.name, h.model, state.status)
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

---@param items table[]
---@param opts { prompt: string, format_item: fun(item: table): string }
---@param on_choice fun(item: table?)
local function pick(items, opts, on_choice)
  vim.ui.select(items, {
    prompt = opts.prompt,
    format_item = opts.format_item,
  }, on_choice)
end

---@return string
local function get_visual_or_line_context(line1, line2)
  local buf = vim.api.nvim_get_current_buf()
  if buf == state.prompt_buf or buf == state.term_buf then
    return ""
  end
  local path = vim.api.nvim_buf_get_name(buf)
  local rel = path ~= "" and vim.fn.fnamemodify(path, ":.") or "[No Name]"
  local ft = vim.bo[buf].filetype or ""

  if line1 and line2 and line1 > 0 and line2 >= line1 then
    local lines = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false)
    if #lines > 0 then
      return string.format("@%s:%d-%d\n```%s\n%s\n```", rel, line1, line2, ft, table.concat(lines, "\n"))
    end
  end
  return "@" .. rel
end

function M.ensure_term(focus)
  local h = M.get_active_harness()
  if vim.fn.executable(h.bin) ~= 1 then
    vim.notify("Harness executable not found: " .. h.bin, vim.log.levels.ERROR)
    return false
  end

  -- If harness changed, close old terminal
  if state.term_harness and state.term_harness ~= h.id then
    if is_valid_win(state.term_win) then
      pcall(vim.api.nvim_win_close, state.term_win, true)
    end
    if is_valid_buf(state.term_buf) then
      pcall(vim.api.nvim_buf_delete, state.term_buf, { force = true })
    end
    state.term_buf = nil
    state.term_win = nil
    state.term_job = nil
  end

  local cur_win = vim.api.nvim_get_current_win()
  if not is_valid_win(state.term_win) then
    vim.cmd("botright vsplit")
    state.term_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(state.term_win, math.max(50, math.floor(vim.o.columns * 0.42)))
    if is_valid_buf(state.term_buf) then
      vim.api.nvim_win_set_buf(state.term_win, state.term_buf)
    else
      state.term_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(state.term_win, state.term_buf)
      state.term_harness = h.id
      state.status = "running"
      state.term_job = vim.fn.termopen(h.cmd, {
        on_exit = function()
          state.status = "idle"
          state.term_job = nil
        end,
      })
      vim.bo[state.term_buf].buflisted = false
    end
  end

  if focus and is_valid_win(state.term_win) then
    vim.api.nvim_set_current_win(state.term_win)
  elseif not focus and is_valid_win(cur_win) then
    vim.api.nvim_set_current_win(cur_win)
  end
  return true
end

function M.open_prompt()
  if is_valid_win(state.prompt_win) then
    vim.api.nvim_set_current_win(state.prompt_win)
    return
  end

  if not is_valid_buf(state.prompt_buf) then
    local buf = vim.api.nvim_create_buf(false, true)
    state.prompt_buf = buf
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.b[buf].ai_harness_prompt = true
    vim.bo[buf].omnifunc = "v:lua.require'ai_harness.completion'.omnifunc"
    vim.api.nvim_buf_set_name(buf, "ai-prompt://" .. M.get_active_harness().id)

    local opts = { buffer = buf, silent = true }
    vim.keymap.set({ "n", "i" }, "<C-s>", function()
      vim.cmd("stopinsert")
      M.send_prompt_buffer({ focus_term = true })
    end, vim.tbl_extend("force", opts, { desc = "Submit AI prompt & focus terminal" }))

    vim.keymap.set({ "n", "i" }, "<M-s>", function()
      vim.cmd("stopinsert")
      M.send_prompt_buffer({ focus_term = false })
    end, vim.tbl_extend("force", opts, { desc = "Submit AI prompt in background" }))

    vim.keymap.set("n", "q", function()
      M.close_prompt()
    end, vim.tbl_extend("force", opts, { desc = "Close AI prompt" }))

    vim.keymap.set("n", "<leader>at", function()
      M.pick_template()
    end, vim.tbl_extend("force", opts, { desc = "Insert prompt template" }))
  end

  local width = math.min(90, math.floor(vim.o.columns * 0.7))
  local height = math.min(18, math.floor(vim.o.lines * 0.35))
  state.prompt_win = vim.api.nvim_open_win(state.prompt_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " AI Prompt (" .. M.get_active_harness().name .. ") — <C-s> Submit | <M-s> Bg | q Close ",
    title_pos = "center",
  })
  vim.wo[state.prompt_win].wrap = true
  vim.wo[state.prompt_win].linebreak = true
end

function M.close_prompt()
  if is_valid_win(state.prompt_win) then
    vim.api.nvim_win_close(state.prompt_win, true)
    state.prompt_win = nil
  end
end

function M.toggle()
  local prompt_open = is_valid_win(state.prompt_win)
  local term_open = is_valid_win(state.term_win)
  if prompt_open or term_open then
    M.close_prompt()
    if term_open then
      vim.api.nvim_win_close(state.term_win, true)
      state.term_win = nil
    end
  else
    M.ensure_term(false)
    M.open_prompt()
  end
end

---@param text string
---@param opts? { focus?: boolean }
function M.send_text(text, opts)
  opts = opts or {}
  local clean = vim.trim(text or "")
  if clean == "" then
    vim.notify("Nothing to send to AI harness", vim.log.levels.WARN)
    return
  end

  local is_new_process = (state.term_job == nil) or (state.term_harness ~= M.get_active_harness().id)
  if not M.ensure_term(opts.focus or false) then
    return
  end

  if state.term_job then
    state.status = "running"
    local is_slash_cmd = clean:sub(1, 1) == "/"

    -- Bracket-paste multi-line text and slash commands so TUIs don't trap \r in an autocomplete menu
    local payload = (text:find("\n", 1, true) or is_slash_cmd) and ("\27[200~" .. clean .. "\27[201~") or text

    -- Give freshly spawned Node/Bun CLI TUIs time to initialize stdin before sending input
    local boot_delay = is_new_process and 1200 or 0

    vim.defer_fn(function()
      if not state.term_job then
        return
      end
      vim.api.nvim_chan_send(state.term_job, payload)

      vim.defer_fn(function()
        if not state.term_job then
          return
        end
        vim.api.nvim_chan_send(state.term_job, "\r")
      end, 100)
    end, boot_delay)

    vim.notify("Submitted to " .. M.get_active_harness().name, vim.log.levels.INFO)
  end
end

---@param opts? { keep_open?: boolean, focus_term?: boolean }
function M.send_prompt_buffer(opts)
  opts = opts or {}
  if not is_valid_buf(state.prompt_buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(state.prompt_buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  if vim.trim(text) == "" then
    vim.notify("Prompt buffer is empty", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, {})
  if not opts.keep_open then
    M.close_prompt()
  end

  M.send_text(text, { focus = opts.focus_term })

  if opts.focus_term and is_valid_win(state.term_win) then
    vim.cmd("startinsert")
  end
end

---@param opts? { line1?: integer, line2?: integer, range?: integer, args?: string }
function M.send(opts)
  opts = opts or {}
  if opts.args and vim.trim(opts.args) ~= "" then
    local ctx = (opts.range and opts.range > 0) and get_visual_or_line_context(opts.line1, opts.line2) or ""
    local payload = ctx ~= "" and (opts.args .. "\n\n" .. ctx) or opts.args
    return M.send_text(payload)
  end

  if vim.api.nvim_get_current_buf() == state.prompt_buf then
    return M.send_prompt_buffer({ focus_term = true })
  end

  if opts.range and opts.range > 0 then
    local ctx = get_visual_or_line_context(opts.line1, opts.line2)
    return M.send_text(ctx)
  end

  M.open_prompt()
end

---@param id? string
function M.switch_harness(id)
  if id and HARNESSES[id] then
    state.active = id
    if is_valid_buf(state.prompt_buf) then
      pcall(vim.api.nvim_buf_set_name, state.prompt_buf, "ai-prompt://" .. id)
    end
    vim.notify("Switched AI harness to " .. HARNESSES[id].name, vim.log.levels.INFO)
    return
  end

  local choices = {}
  for _, key in ipairs(HARNESS_ORDER) do
    table.insert(choices, HARNESSES[key])
  end
  pick(choices, {
    prompt = "Select AI Harness:",
    format_item = function(item)
      local mark = item.id == state.active and " (active)" or ""
      return string.format("%s [%s]%s", item.name, item.model, mark)
    end,
  }, function(choice)
    if choice then
      M.switch_harness(choice.id)
    end
  end)
end

function M.pick_template()
  pick(TEMPLATES, {
    prompt = "Select Prompt Template:",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if not choice then
      return
    end
    M.open_prompt()
    local lines = vim.split(choice.text, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(state.prompt_win, { #lines, #lines[#lines] })
  end)
end

---@param cmd? string
function M.run_command(cmd)
  if cmd and vim.trim(cmd) ~= "" then
    M.send_text(cmd, { focus = true })
    if is_valid_win(state.term_win) then
      vim.cmd("startinsert")
    end
    return
  end
  local items = require("ai_harness.completion").get_commands(state.active)
  pick(items, {
    prompt = M.get_active_harness().name .. " Commands & Skills:",
    format_item = function(item)
      return string.format("%-24s %s", item.label, item.detail or "")
    end,
  }, function(choice)
    if choice then
      M.send_text(choice.label, { focus = true })
      if is_valid_win(state.term_win) then
        vim.cmd("startinsert")
      end
    end
  end)
end

---@param lines integer
function M.scroll_output(lines)
  if not is_valid_win(state.term_win) or not is_valid_buf(state.term_buf) then
    vim.notify("No active AI output window", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_win_call(state.term_win, function()
    local line_count = vim.api.nvim_buf_line_count(state.term_buf)
    local cur = vim.api.nvim_win_get_cursor(state.term_win)[1]
    local target = math.max(1, math.min(line_count, cur + lines))
    pcall(vim.api.nvim_win_set_cursor, state.term_win, { target, 0 })
  end)
end

---@param opts? { line1?: integer, line2?: integer, range?: integer, args?: string }
function M.inline(opts)
  opts = opts or {}
  local ctx = get_visual_or_line_context(
    opts.range and opts.range > 0 and opts.line1 or vim.fn.line("."),
    opts.range and opts.range > 0 and opts.line2 or vim.fn.line(".")
  )

  local function dispatch(instruction)
    if not instruction or vim.trim(instruction) == "" then
      return
    end
    local h = M.get_active_harness()
    if vim.fn.executable(h.bin) ~= 1 then
      vim.notify("Harness executable not found: " .. h.bin, vim.log.levels.ERROR)
      return
    end
    local full_prompt = instruction .. "\n\nContext:\n" .. ctx
    state.status = "running"
    vim.notify("Running inline request via " .. h.name .. "...", vim.log.levels.INFO)
    vim.system(h.print_cmd(full_prompt), { text = true }, function(res)
      vim.schedule(function()
        state.status = "idle"
        if res.code ~= 0 then
          vim.notify("AIInline failed: " .. (res.stderr or "unknown error"), vim.log.levels.ERROR)
          return
        end
        local out_lines = vim.split(res.stdout or "", "\n", { plain = true })
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].filetype = "markdown"
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)
        local w = math.min(90, math.floor(vim.o.columns * 0.75))
        local ht = math.min(24, math.max(8, #out_lines + 2))
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = w,
          height = ht,
          row = math.floor((vim.o.lines - ht) / 2),
          col = math.floor((vim.o.columns - w) / 2),
          style = "minimal",
          border = "rounded",
          title = " " .. h.name .. " Inline Response (q to close) ",
          title_pos = "center",
        })
        vim.wo[win].wrap = true
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
      end)
    end)
  end

  if opts.args and vim.trim(opts.args) ~= "" then
    dispatch(opts.args)
  else
    vim.ui.input({ prompt = M.get_active_harness().name .. " inline instruction: " }, dispatch)
  end
end

function M.setup()
  if M._did_setup then
    return
  end
  M._did_setup = true

  vim.api.nvim_create_user_command("AISend", function(opts)
    M.send(opts)
  end, { range = true, nargs = "*", desc = "Send prompt or selection to active AI harness" })

  vim.api.nvim_create_user_command("AISwitch", function(opts)
    M.switch_harness(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    complete = function(arg_lead)
      return vim.tbl_filter(function(k)
        return vim.startswith(k, arg_lead)
      end, HARNESS_ORDER)
    end,
    desc = "Switch active AI harness",
  })

  vim.api.nvim_create_user_command("AIToggle", function()
    M.toggle()
  end, { desc = "Toggle AI prompt window and terminal pane" })

  vim.api.nvim_create_user_command("AIInline", function(opts)
    M.inline(opts)
  end, { range = true, nargs = "*", desc = "Request inline AI edit or explanation" })

  vim.api.nvim_create_user_command("AICommand", function(opts)
    M.run_command(opts.args)
  end, {
    nargs = "?",
    complete = function(arg_lead)
      local cmds = require("ai_harness.completion").get_commands(state.active)
      local out = {}
      for _, c in ipairs(cmds) do
        if arg_lead == "" or vim.startswith(c.label, arg_lead) then
          table.insert(out, c.label)
        end
      end
      return out
    end,
    desc = "Run or pick a slash command / skill for active AI harness",
  })
end

return M
