# gemini.nvim

A simplified Neovim plugin for AI-assisted coding powered by **Gemini CLI**.

## Features

- 🚀 **Fill-in-function**: AI completes function bodies based on signature
- ✏️ **Visual edit**: Modify selected code with AI assistance
- 💬 **Ask**: Ask questions about your code with context
- 🌍 **Multi-language**: Treesitter support for Lua, Python, JavaScript, TypeScript, Go, Rust, C, C++

## Requirements

- Neovim 0.9+ with treesitter
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "your-username/gemini.nvim",
    config = function()
        local gemini = require("gemini")
        gemini.setup({
            model = "gemini-3",  -- or "gemini-2.5-pro"
            auto_approve = true,          -- auto-approve Gemini actions
            debug = false,                -- enable debug logging
        })

        -- Keymaps
        vim.keymap.set("n", "<leader>gf", gemini.fill_in_function, { desc = "Gemini: Fill function" })
        vim.keymap.set("v", "<leader>gv", gemini.visual, { desc = "Gemini: Edit selection" })
        vim.keymap.set("n", "<leader>ga", function()
            vim.ui.input({ prompt = "Ask Gemini: " }, function(input)
                if input then gemini.ask(input) end
            end)
        end, { desc = "Gemini: Ask" })
        vim.keymap.set("n", "<leader>gs", gemini.stop_all, { desc = "Gemini: Stop all" })
        vim.keymap.set("n", "<leader>gi", gemini.info, { desc = "Gemini: Info" })
    end,
}
```

### Local Development

```lua
{
    dir = "/home/amxnn05/Dev/testing/99/gemini.nvim",
    config = function()
        -- Same config as above
    end,
}
```

## Usage

### Fill-in-function

1. Write a function with signature and optionally a docstring/comment
2. Place cursor inside the function
3. Press `<leader>gf`
4. AI generates the implementation

```lua
-- Before
function calculate_fibonacci(n)
    -- Calculate the nth Fibonacci number
end

-- After (AI fills in)
function calculate_fibonacci(n)
    -- Calculate the nth Fibonacci number
    if n <= 1 then
        return n
    end
    local a, b = 0, 1
    for i = 2, n do
        a, b = b, a + b
    end
    return b
end
```

### Visual Edit

1. Select code in visual mode
2. Press `<leader>gv`
3. Enter an instruction (e.g., "add error handling")
4. AI modifies the selection

### Ask

1. Press `<leader>ga`
2. Enter your question
3. AI responds in a floating window with context from your file

## Supported Languages

| Language       | Parser       | Status |
|---------------|--------------|--------|
| Lua           | lua          | ✅     |
| Python        | python       | ✅     |
| JavaScript    | javascript   | ✅     |
| TypeScript    | typescript   | ✅     |
| TSX           | tsx          | ✅     |
| JSX           | javascript   | ✅     |
| Go            | go           | ✅     |
| Rust          | rust         | ✅     |
| C             | c            | ✅     |
| C++           | cpp          | ✅     |

## API

```lua
local gemini = require("gemini")

gemini.setup(opts)           -- Configure the plugin
gemini.fill_in_function()    -- Fill function at cursor
gemini.visual(prompt?)       -- Edit visual selection
gemini.ask(prompt)           -- Ask about code
gemini.stop_all()            -- Cancel all active requests
gemini.info()                -- Display plugin info
gemini.get_config()          -- Get current configuration
```

## Configuration

```lua
gemini.setup({
    model = "gemini-2.5-flash",  -- Gemini model to use
    auto_approve = true,          -- Auto-approve Gemini CLI actions
    debug = false,                -- Enable debug logging
})
```

## License

MIT
