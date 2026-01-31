--- Optimized Gemini CLI provider

local M = {}

--- @class Gemini.Provider.Observer
--- @field on_stdout fun(data: string)
--- @field on_stderr fun(data: string)
--- @field on_complete fun(success: boolean, result: string)

local NOOP = function() end
local DevNull = { on_stdout = NOOP, on_stderr = NOOP, on_complete = NOOP }

--- Build command - minimal flags for speed
--- @param prompt string
--- @param model string
--- @return string[]
local function build_cmd(prompt, model)
  -- Don't use --approval-mode as it may not be supported in all CLI versions
  local cmd = { "gemini", "-p", prompt, "-o", "text" }
  if model and model ~= "" then
    table.insert(cmd, "-m")
    table.insert(cmd, model)
  end
  return cmd
end

--- Make request - optimized with single completion guard
--- @param prompt string
--- @param state Gemini.State
--- @param observer Gemini.Provider.Observer?
--- @return number
function M.make_request(prompt, state, observer)
  observer = observer or DevNull
  local id = vim.uv.now()
  local stdout, stderr = {}, {}
  local done = false

  local function complete(ok, result)
    if done then return end
    done = true
    state.active_requests[id] = nil
    observer.on_complete(ok, result)
  end

  local cmd = build_cmd(prompt, state.config.model)

  -- Run from current working directory with HOME set
  local proc = vim.system(cmd, {
    text = true,
    cwd = vim.fn.getcwd(),
    env = {
      HOME = vim.env.HOME,
      PATH = vim.env.PATH,
      XDG_CONFIG_HOME = vim.env.XDG_CONFIG_HOME,
      NODE_PATH = vim.env.NODE_PATH,
    },
    stdout = vim.schedule_wrap(function(_, data)
      if done then return end
      if data then
        stdout[#stdout + 1] = data
        observer.on_stdout(data)
      end
    end),
    stderr = vim.schedule_wrap(function(_, data)
      if done then return end
      if data then stderr[#stderr + 1] = data end
    end),
  }, vim.schedule_wrap(function(obj)
    if obj.code ~= 0 then
      complete(false, table.concat(stderr, "") or "Exit code: " .. obj.code)
    else
      complete(true, table.concat(stdout, ""))
    end
  end))

  state.active_requests[id] = proc
  return id
end

--- @return boolean
function M.check_available()
  return vim.fn.executable("gemini") == 1
end

return M
