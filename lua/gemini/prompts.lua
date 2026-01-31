--- Optimized prompts with full file context for gemini.nvim

local M = {}

--- Fill-in-function prompt with file context
--- @param func_text string Function to implement
--- @param file_context string Full file content
--- @param language string Programming language
--- @return string
function M.fill_in_function(func_text, file_context, language)
  local prompt = string.format([[TASK: Implement this %s function.

FILE CONTEXT:
%s

FUNCTION TO IMPLEMENT:
%s

RULES:
- Return ONLY the complete function with implementation
- No explanations, no markdown
- Be idiomatic and efficient
- Consider the file context for consistency]], language, file_context, func_text)

  return prompt
end

--- Visual edit prompt with file context
--- @param code string Selected code
--- @param instruction string User instruction
--- @param file_context string Full file content
--- @param language string Programming language
--- @return string
function M.visual_edit(code, instruction, file_context, language)
  return string.format([[TASK: Modify this %s code.

FILE CONTEXT:
%s

CODE TO MODIFY:
%s

INSTRUCTION: %s

Return ONLY the modified code, no explanations, no markdown.]], language, file_context, code, instruction)
end

--- Ask about code prompt with file context
--- @param question string User question
--- @param file_context string Full file content
--- @param language string Programming language
--- @return string
function M.ask(question, file_context, language)
  return string.format([[%s file context:
%s

Question: %s

Answer concisely based on the full file context:]], language, file_context, question)
end

return M
