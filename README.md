# README.md

# catt.nvim

A Neovim plugin for catt support providing syntax highlighting and auto-indentation.

## Features

- Syntax highlighting for keywords, operators, strings, numbers, and built-ins
- Automatic indentation
- File type detection
- Configurable settings

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "daikonk/catt.nvim",
    opts = {
        file_patterns = { "*.catt" },  -- Customize file patterns
        indent_size = 4,             -- Customize indent size
    },
    config = true,
    ft = "catt",
}
```

## Configuration

Default configuration:

```lua
{
    file_patterns = { "*.catt" },  -- File patterns to match
    indent_size = 4,             -- Number of spaces for indentation
}
```
