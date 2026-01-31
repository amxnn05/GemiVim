--- Core operations for gemini.nvim with full file context

local provider = require("gemini.provider")
local language = require("gemini.language")
local prompts = require("gemini.prompts")
local context = require("gemini.context")
local ui = require("gemini.ui")

local M = {}

--- Get visual selection
--- @return string, number, number
local function get_visual_selection()
  local sr = vim.fn.line("'<")
  local er = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, sr - 1, er, false)
  return table.concat(lines, "\n"), sr, er
end

--- Extract ONLY the first function from AI response
--- @param response string
--- @param func_signature string? Original function signature to match
--- @return string
local function extract_code(response, func_signature)
  -- Try markdown code block first (most reliable)
  local code = response:match("```%w*\n(.-)\n```")
  if code then 
    -- If code block contains only one function, return it
    return code
  end
  
  -- Try without newlines
  code = response:match("```%w*(.-)```")
  if code then 
    return code:gsub("^\n", ""):gsub("\n$", "") 
  end
  
  -- Split into lines and extract only the FIRST function
  local lines = vim.split(response, "\n")
  local func_start = nil
  local func_end = nil
  local brace_count = 0
  local in_function = false
  
  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$") or ""
    
    -- Find function start
    if not in_function then
      if trimmed:match("^function") or trimmed:match("^async function")
          or trimmed:match("^export function") or trimmed:match("^export async")
          or trimmed:match("^def ") or trimmed:match("^async def")
          or trimmed:match("^fn ") or trimmed:match("^pub fn")
          or trimmed:match("^func ") or trimmed:match("^local function") then
        func_start = i
        in_function = true
        brace_count = 0
      end
    end
    
    -- Count braces to find function end
    if in_function then
      for c in line:gmatch(".") do
        if c == "{" or c == "(" then brace_count = brace_count + 1 end
        if c == "}" or c == ")" then brace_count = brace_count - 1 end
      end
      
      -- Check for function end
      if brace_count <= 0 and (trimmed:match("}$") or trimmed:match("end$") or trimmed == "") then
        -- For languages like Python, check for dedent
        if trimmed == "" and func_end then
          -- Already found end, this is extra blank line
          break
        elseif trimmed:match("}$") or trimmed:match("end$") then
          func_end = i
          break
        end
      end
      
      -- Track potential end for Python-style functions
      if brace_count == 0 and trimmed ~= "" then
        func_end = i
      end
    end
  end
  
  -- Extract function
  if func_start and func_end then
    local result = {}
    for i = func_start, func_end do
      result[#result + 1] = lines[i]
    end
    return table.concat(result, "\n")
  end
  
  -- Fallback: strip markdown and return
  return response:gsub("```%w*\n?", ""):gsub("\n?```", ""):gsub("^%s+", "")
end

--- Fill in function with full file context
--- @param state Gemini.State
function M.fill_in_function(state)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  if not language.is_supported(ft) then
    return ui.notify_error("Unsupported: " .. ft)
  end

  local node, func_text = language.get_function_at_cursor(bufnr)
  if not node or not func_text then
    return ui.notify_error("No function at cursor")
  end

  local sr, _, er, _ = language.get_function_range(bufnr)
  if not sr then return ui.notify_error("Cannot get function range") end

  -- Get full file context (cached)
  local file_ctx = context.get_summary(bufnr, 300)
  
  local prompt = prompts.fill_in_function(func_text, file_ctx, ft)
  local stop = ui.show_loading("Generating...")

  provider.make_request(prompt, state, {
    on_stdout = function() end,
    on_stderr = function() end,
    on_complete = function(ok, result)
      stop()
      if not ok then return ui.notify_error(result) end
      
      local code = extract_code(result)
      if code == "" then return ui.notify_error("Empty response") end
      
      vim.api.nvim_buf_set_lines(bufnr, sr - 1, er, false, vim.split(code, "\n"))
      ui.notify_success("Done!")
    end,
  })
end

--- Visual edit with full file context
--- @param state Gemini.State
--- @param user_prompt string?
function M.visual_edit(state, user_prompt)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  vim.cmd("normal! \027") -- Exit visual mode
  
  local text, sr, er = get_visual_selection()
  if text == "" then return ui.notify_error("No selection") end

  -- Get full file context (cached)
  local file_ctx = context.get_summary(bufnr, 300)

  local function do_edit(instruction)
    if not instruction or instruction == "" then return end

    local prompt = prompts.visual_edit(text, instruction, file_ctx, ft)
    local stop = ui.show_loading("Editing...")

    provider.make_request(prompt, state, {
      on_stdout = function() end,
      on_stderr = function() end,
      on_complete = function(ok, result)
        stop()
        if not ok then return ui.notify_error(result) end
        
        local code = extract_code(result)
        if code == "" then return ui.notify_error("Empty response") end
        
        vim.api.nvim_buf_set_lines(bufnr, sr - 1, er, false, vim.split(code, "\n"))
        ui.notify_success("Done!")
      end,
    })
  end

  if user_prompt then
    do_edit(user_prompt)
  else
    ui.capture_input("Edit: ", do_edit)
  end
end

--- Ask with full file context
--- @param state Gemini.State
--- @param question string
function M.ask(state, question)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  if not question or question == "" then
    return ui.capture_input("Ask: ", function(q)
      if q and q ~= "" then M.ask(state, q) end
    end)
  end

  -- Get full file context (cached)
  local file_ctx = context.get_summary(bufnr, 500)
  
  local prompt = prompts.ask(question, file_ctx, ft)
  local stop = ui.show_loading("Thinking...")

  provider.make_request(prompt, state, {
    on_stdout = function() end,
    on_stderr = function() end,
    on_complete = function(ok, result)
      stop()
      if not ok then return ui.notify_error(result) end
      ui.create_floating_window(result, "Gemini")
    end,
  })
end

return M
