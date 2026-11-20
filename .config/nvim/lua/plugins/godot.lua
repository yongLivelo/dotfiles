-- let external tools (Godot) open files in this instance; see ~/.local/bin/godot-nvim
-- virtual: no repo to install, this spec only runs startup config
return {
  "godot-pin",
  virtual = true,
  config = function()
    local runtime = vim.env.XDG_RUNTIME_DIR or "/tmp"
    local sock = ("%s/nvim-%d.sock"):format(runtime, vim.fn.getpid())
    local ok, started = pcall(vim.fn.serverstart, sock)
    local listening = ok and started ~= nil and started ~= 0
    if listening then
      -- the /tmp fallback has no private parent dir, so keep other users out
      pcall(vim.uv.fs_chmod, sock, 448) -- 0700
    end

    -- register this instance for the current Godot project (or cwd), without hijacking a live owner
    -- the uid suffix keeps the fallback /tmp path private on a shared machine
    local projects = runtime .. "/nvim-projects-" .. vim.uv.getuid()
    local map
    local function project_root()
      local cwd = vim.fn.getcwd()
      -- getcwd() is empty when nvim starts in a directory that was deleted
      if cwd == "" then
        cwd = vim.env.HOME or "/"
      end
      return vim.fs.root(cwd, "project.godot") or cwd
    end

    local function is_alive(s)
      if not s or s == "" then
        return false
      end
      if s == sock then
        return listening
      end
      if not vim.uv.fs_stat(s) then
        return false
      end
      local ok, ch = pcall(vim.fn.sockconnect, "pipe", s, { rpc = false })
      if ok and ch > 0 then
        pcall(vim.fn.chanclose, ch)
        return true
      end
      return false
    end

    local function register(force)
      local root = project_root()
      map = ("%s/%s"):format(projects, vim.fn.sha256(root))
      if not listening then
        vim.notify("Godot pinning disabled: cannot start a server at " .. sock, vim.log.levels.WARN)
        return false, root
      end
      pcall(vim.fn.mkdir, projects, "p")
      local st = vim.uv.fs_lstat(projects)
      -- the /tmp fallback must not trust a path another user planted there
      if not st or st.type ~= "directory" or st.uid ~= vim.uv.getuid() then
        vim.notify("Godot pinning disabled: cannot use " .. projects, vim.log.levels.WARN)
        return false, root
      end
      pcall(vim.uv.fs_chmod, projects, 448) -- 0700, even with a lax umask
      if not force then
        local ok, lines = pcall(vim.fn.readfile, map)
        if ok and is_alive(lines[1]) then
          return false, root
        end
      end
      local ok, res = pcall(vim.fn.writefile, { sock }, map)
      if not ok or res ~= 0 then
        vim.notify("Godot pinning disabled: cannot write " .. map, vim.log.levels.WARN)
        return false, root
      end
      return true, root
    end

    -- drop the map this instance owns, so :cd or exit leaves no stale socket file behind
    local function unregister()
      if not map then
        return
      end
      local ok, lines = pcall(vim.fn.readfile, map)
      if ok and lines[1] == sock then
        vim.fn.delete(map)
      end
    end

    register(false)
    vim.api.nvim_create_autocmd("DirChanged", {
      callback = function()
        unregister()
        register(false)
      end,
    })
    vim.api.nvim_create_autocmd("VimLeave", { callback = unregister })
    vim.api.nvim_create_user_command("GodotPin", function()
      local pinned, root = register(true)
      if pinned then
        vim.notify("Godot pinned to this nvim (" .. root .. ")")
      else
        vim.notify("GodotPin failed: could not register this nvim's socket (" .. root .. ")", vim.log.levels.ERROR)
      end
    end, { desc = "Pin this nvim as the Godot target for the current project" })
  end,
}
