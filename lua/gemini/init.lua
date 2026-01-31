--- gemini.nvim - Neovim AI Plugin with Full File Context

local operations = require("gemini.operations")
local language = require("gemini.language")
local context = require("gemini.context")

--- @class Gemini.Config
--- @field model string
--- @field debug boolean

--- @class Gemini.State
--- @field config Gemini.Config
--- @field active_requests table<number, vim.SystemObj>
local State = {
  config = { model = "", debug = false },
  active_requests = {},
}

local M = {}

--- @param opts Gemini.Config?
function M.setup(opts)
  if opts then
    State.config = vim.tbl_extend("force", State.config, opts)
  end
  language.initialize()
  context.setup_autocmds()  -- Setup auto-clear on buffer close
end

--- @return Gemini.Config
function M.get_config() return State.config end

--- @return Gemini.State
function M._get_state() return State end

function M.fill_in_function()
  operations.fill_in_function(State)
end

--- @param prompt string?
function M.visual(prompt)
  operations.visual_edit(State, prompt)
end

--- @param prompt string
function M.ask(prompt)
  operations.ask(State, prompt)
end

function M.stop_all()
  for id, proc in pairs(State.active_requests) do
    pcall(function() proc:kill() end)
    State.active_requests[id] = nil
  end
  vim.notify("Stopped", vim.log.levels.INFO)
end

function M.info()
  local model = State.config.model ~= "" and State.config.model or "auto"
  local langs = table.concat(language.get_supported(), ", ")
  vim.notify(string.format("gemini.nvim\nModel: %s\nActive: %d\nLanguages: %s\nContext: cached per buffer",
    model, vim.tbl_count(State.active_requests), langs), vim.log.levels.INFO)
end

--- Clear context cache for current buffer
function M.clear_context()
  context.clear(vim.api.nvim_get_current_buf())
  vim.notify("Context cleared", vim.log.levels.INFO)
end

--- Clear all context caches
function M.clear_all_context()
  context.clear_all()
  vim.notify("All context cleared", vim.log.levels.INFO)
end

return M
