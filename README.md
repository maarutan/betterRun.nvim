# betterRun.nvim

https://github.com/user-attachments/assets/425909af-e7f6-4bcf-9309-091259eb5e69

A Neovim plugin that simplifies running code for multiple programming languages directly from your editor.

## Features

- Run code in various programming languages with a single keybinding.
- Supports floating, vertical, and horizontal terminal modes.
- Configurable commands and file extensions.
- Users can define their own commands and extensions for additional languages.
- Debug mode for detailed logging.
- Easy to set up and use.
- An alternative to [Code Runner](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) for Neovim users.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "maarutan/betterRun.nvim",
    dependencies = "akinsho/toggleterm.nvim",
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "maarutan/betterRun.nvim",
    requires = "akinsho/toggleterm.nvim",
}
```

## Configuration

Add the following to your Neovim configuration file (e.g., `init.lua` or `init.vim`):

```lua
require("betterRun").setup({
    keymap = "<A-S-r>",
    interrupt_keymap = "<F2>",
    terminal_mode = "float", -- Options: "float", "horizontal", "vertical", "auto"
    commands = {
        python = "python3 -u $dir/$fileName",
        lua = "lua $dir/$fileName",
        javascript = "node $dir/$fileName",
        typescript = "ts-node $dir/$fileName",
        ruby = "ruby $dir/$fileName",
        go = "go run $dir/$fileName",
        java = "java $fileName",
        cpp = "g++ -o $dir/output $dir/$fileName && $dir/output",
    },
    extensions = {
        python = { "py" },
        lua = { "lua" },
        javascript = { "js" },
        typescript = { "ts" },
        ruby = { "rb" },
        go = { "go" },
        java = { "java" },
        cpp = { "cpp" },
    },
    debug = false, -- Enable debug logging
})
```

To add custom runners or extensions, simply extend the `commands` and `extensions` tables in the setup configuration. For example:

```lua
require("betterRun").setup({
    commands = {
        rust = "cargo run", -- Add support for Rust
    },
    extensions = {
        rust = { "rs" },
    },
})
```

## Usage

- **Run Code**: Press `<A-S-r>` to run the current file.
- **Interrupt Execution**: Press `<F2>` to send an interrupt signal (Ctrl+C) to the running process.

### Example Keybindings

- `<A-S-r>`: Runs the code in the current buffer.
- `<F2>`: Interrupts the running process in the terminal.

## Terminal Modes

The terminal mode is dynamically determined based on the screen size unless explicitly set. Available modes:

- `float`: Opens a floating terminal.
- `horizontal`: Opens a terminal at the bottom of the screen.
- `vertical`: Opens a terminal on the side.
- `auto`: Automatically decides the mode based on the screen dimensions.

## Supported Languages

The plugin supports the following languages and file extensions by default:

| Language   | File Extension |
| ---------- | -------------- |
| Python     | `.py`          |
| Lua        | `.lua`         |
| JavaScript | `.js`          |
| TypeScript | `.ts`          |
| Ruby       | `.rb`          |
| Go         | `.go`          |
| Java       | `.java`        |
| C++        | `.cpp`         |

## Debugging

Enable debug mode by setting `debug = true` in the configuration. This will provide detailed logs for troubleshooting.

## Dependencies

- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)

## License

This project is licensed under the MIT License.
