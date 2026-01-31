--- Optimized language detection and treesitter integration

local M = {}

--- Cached queries per parser
--- @type table<string, vim.treesitter.Query>
local query_cache = {}

--- Mapping of filetypes to treesitter parsers and function patterns
--- @type table<string, {parser: string, query: string}>
local LANG_CONFIG = {
  lua = {
    parser = "lua",
    query = "(function_declaration) @fn (function_definition) @fn",
  },
  python = {
    parser = "python",
    query = "(function_definition) @fn",
  },
  javascript = {
    parser = "javascript",
    query = "(function_declaration) @fn (arrow_function) @fn (method_definition) @fn",
  },
  typescript = {
    parser = "typescript",
    query = "(function_declaration) @fn (arrow_function) @fn (method_definition) @fn",
  },
  typescriptreact = {
    parser = "tsx",
    query = "(function_declaration) @fn (arrow_function) @fn (method_definition) @fn",
  },
  javascriptreact = {
    parser = "javascript",
    query = "(function_declaration) @fn (arrow_function) @fn (method_definition) @fn",
  },
  go = {
    parser = "go",
    query = "(function_declaration) @fn (method_declaration) @fn",
  },
  rust = {
    parser = "rust",
    query = "(function_item) @fn",
  },
  c = {
    parser = "c",
    query = "(function_definition) @fn",
  },
  cpp = {
    parser = "cpp",
    query = "(function_definition) @fn",
  },
}

--- Get or create cached query
--- @param parser_name string
--- @param query_str string
--- @return vim.treesitter.Query?
local function get_query(parser_name, query_str)
  local key = parser_name
  if query_cache[key] then
    return query_cache[key]
  end
  
  local ok, query = pcall(vim.treesitter.query.parse, parser_name, query_str)
  if ok then
    query_cache[key] = query
    return query
  end
  return nil
end

function M.initialize()
  -- Pre-cache queries for common languages
  for _, config in pairs(LANG_CONFIG) do
    pcall(function()
      get_query(config.parser, config.query)
    end)
  end
end

--- @return string[]
function M.get_supported()
  local langs = vim.tbl_keys(LANG_CONFIG)
  table.sort(langs)
  return langs
end

--- @param ft string
--- @return boolean
function M.is_supported(ft)
  return LANG_CONFIG[ft] ~= nil
end

--- Get function at cursor - optimized with caching
--- @param bufnr number
--- @return TSNode?, string?
function M.get_function_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local config = LANG_CONFIG[ft]
  if not config then return nil, nil end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, config.parser)
  if not ok or not parser then return nil, nil end

  local tree = parser:parse()[1]
  if not tree then return nil, nil end

  local query = get_query(config.parser, config.query)
  if not query then return nil, nil end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  -- Find innermost function containing cursor
  local best_node, best_start = nil, -1
  
  for _, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
    local sr, sc, er, ec = node:range()
    if row >= sr and row <= er and (row > sr or col >= sc) and (row < er or col <= ec) then
      if sr > best_start then
        best_node, best_start = node, sr
      end
    end
  end

  if best_node then
    return best_node, vim.treesitter.get_node_text(best_node, bufnr)
  end
  return nil, nil
end

--- @param bufnr number
--- @return string?, number?, number?
function M.get_function_signature(bufnr)
  local node, text = M.get_function_at_cursor(bufnr)
  if not node or not text then return nil, nil, nil end
  local sr, _, er, _ = node:range()
  return vim.split(text, "\n")[1], sr + 1, er + 1
end

--- @param bufnr number
--- @return number?, number?, number?, number?
function M.get_function_range(bufnr)
  local node = M.get_function_at_cursor(bufnr)
  if not node then return nil, nil, nil, nil end
  local sr, sc, er, ec = node:range()
  return sr + 1, sc + 1, er + 1, ec
end

--- @param ft string
--- @return table?
function M.get_config(ft)
  return LANG_CONFIG[ft]
end

return M
