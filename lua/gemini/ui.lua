--- Optimized UI for gemini.nvim

local M = {}

--- Create floating window - optimized
--- @param content string|string[]
--- @param title string?
--- @return number, number
function M.create_floating_window(content, title)
  local lines = type(content) == "string" and vim.split(content, "\n") or content
  
  -- Calculate size efficiently
  local w = math.min(80, vim.o.columns - 4)
  local h = math.min(#lines + 2, 30)
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    style = "minimal",
    border = "rounded",
    title = title and (" " .. title .. " ") or nil,
    title_pos = title and "center" or nil,
  })

  -- Close keymaps
  local close = function() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })

  return buf, win
end

--- Show loading spinner - optimized
--- @param msg string?
--- @return function
function M.show_loading(msg)
  msg = msg or "Working..."
  local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local i, ns = 1, vim.api.nvim_create_namespace("gemini_loading")
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  
  local timer = vim.uv.new_timer()
  timer:start(0, 80, vim.schedule_wrap(function()
    pcall(function()
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      vim.api.nvim_buf_set_extmark(buf, ns, line, 0, {
        virt_text = { { frames[i] .. " " .. msg, "Comment" } },
        virt_text_pos = "eol",
      })
      i = i % #frames + 1
    end)
  end))

  return function()
    timer:stop()
    timer:close()
    pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
  end
end

--- Capture input
--- @param prompt string
--- @param callback fun(input: string?)
function M.capture_input(prompt, callback)
  vim.ui.input({ prompt = prompt }, callback)
end

--- Notifications
--- @param msg string
--- @param level number?
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

function M.notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

function M.notify_success(msg)
  vim.notify(msg, vim.log.levels.INFO)
end

return M
