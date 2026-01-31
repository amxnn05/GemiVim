--- File context caching for gemini.nvim
--- Caches file content per buffer for full-context AI operations

local M = {}

--- @type table<number, {content: string, filename: string, filetype: string, updated: number}>
local cache = {}

--- Get or refresh file context for a buffer
--- @param bufnr number
--- @return {content: string, filename: string, filetype: string}
function M.get(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  local cached = cache[bufnr]
  
  -- Return cached if unchanged
  if cached and cached.updated == changedtick then
    return cached
  end
  
  -- Refresh cache
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ctx = {
    content = table.concat(lines, "\n"),
    filename = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.bo[bufnr].filetype,
    updated = changedtick,
  }
  cache[bufnr] = ctx
  return ctx
end

--- Get a summary of the file (first N and last M lines if file is large)
--- @param bufnr number
--- @param max_lines number?
--- @return string
function M.get_summary(bufnr, max_lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  max_lines = max_lines or 200
  
  local ctx = M.get(bufnr)
  local lines = vim.split(ctx.content, "\n")
  local total = #lines
  
  if total <= max_lines then
    return ctx.content
  end
  
  -- Get first half and last half
  local half = math.floor(max_lines / 2)
  local result = {}
  
  for i = 1, half do
    result[#result + 1] = lines[i]
  end
  
  result[#result + 1] = string.format("\n... [%d lines omitted] ...\n", total - max_lines)
  
  for i = total - half + 1, total do
    result[#result + 1] = lines[i]
  end
  
  return table.concat(result, "\n")
end

--- Clear cache for a buffer
--- @param bufnr number
function M.clear(bufnr)
  cache[bufnr] = nil
end

--- Clear all cache
function M.clear_all()
  cache = {}
end

--- Setup auto-clear on buffer close
function M.setup_autocmds()
  vim.api.nvim_create_autocmd("BufUnload", {
    group = vim.api.nvim_create_augroup("GeminiContextCache", { clear = true }),
    callback = function(args)
      M.clear(args.buf)
    end,
  })
end

return M
