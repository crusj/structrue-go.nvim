# structrue-go.nvim
A more intuitive display of the symbol structure of golang files.

## Description
Fast, asynchronous, intuitive, collapsible, automatic, show all methods even if they are not in the same file as the corresponding type and more.


## Screenshots

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/01-min.png" width="850">

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/02-min.png" width="850">

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/03-min.png" width="850">

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/04-min.png" width="850">

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/05-min.png" width="850">


## Install 

### Requirement

**neovim >= 0.7**

**gotags**

```shell
go get -u github.com/jstemmer/gotags
```

### Installation

**Use your favorite package management tool**

**With Packer**

```lua
use {
	'crusj/structrue-go.nvim',
	branch = "main"
}
```

**Or**

```shell
git clone https://github.com/crusj/structrue-go.nvim.git  ~/.local/share/nvim/site/pack/plugins/start/structrue-go.nvim
```

## Usage

### Start

```lua
require"structrue-go".setup()
```

### Default config

```lua
require"structrue-go".setup({
	show_others_method = true, -- bool show methods of struct whose not in current file
	show_filename = true, -- bool
	number = "no", -- show number: no | nu | rnu
	fold_open_icon = " ",
	fold_close_icon = " ",
	cursor_symbol_hl = "guibg=Gray guifg=White", -- symbol hl under cursor,
	indent = "┠",  -- Hierarchical indent icon, nil or empty will be a tab
	position = "botright", -- window position,default botright,also can set float
	symbol = { -- symbol style
		filename = {
		    hl = "guifg=#0096C7", -- highlight symbol
		    icon = " " -- symbol icon
		},
		package = {
		    hl = "guifg=#0096C7",
		    icon = " "
		},
		import = {
		    hl = "guifg=#0096C7",
		    icon = " ◈ "
		},
		const = {
		    hl = "guifg=#E44755",
		    icon = " π ",
		},
		variable = {
		    hl = "guifg=#52A5A2",
		    icon = " ◈ ",
		},
		func = {
		    hl = "guifg=#CEB996",
		    icon = "  ",
		},
		interface = {
		    hl = "guifg=#00B4D8",
		    icon = "❙ "
		},
		type = {
		    hl = "guifg=#00B4D8",
		    icon = "▱ ",
		},
		struct = {
		    hl = "guifg=#00B4D8",
		    icon = "❏ ",
		},
		field = {
		    hl = "guifg=#CEB996",
		    icon = " ▪ "
		},
		method_current = {
		    hl = "guifg=#CEB996",
		    icon = " ƒ "
		},
		method_others = {
		    hl = "guifg=#CEB996",
		    icon = "  "
		},
	},
	keymap = {
		toggle = "<leader>m", -- toggle structure-go window
		show_others_method_toggle = "H", -- show or hidden the methods of struct whose not in current file
		symbol_jump = "<CR>", -- jump to then symbol file under cursor
		center_symbol = "\\f", -- Center the highlighted symbol
		fold_toggle = "\\z",
		refresh = "R", -- refresh symbols
		preview_open = "P", -- preview  symbol context open
		preview_close = "\\p" -- preview  symbol context close
	},
	fold = { -- fold symbols
		import = true,
		const = false,
		variable = false,
		type = false,
		interface = false,
		func = false,
	},
})

```

### keymap

| Keymap                   | Action                                                                 | Description                                                   | 
|  ----------------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------- |
|          ```<leader>m``` |                ```:lua require'structrue-go'.toggle()```                 | Toggle structure-go                                             |
|                          |               ```:lua require'structrue-go'.close()```                 | Close structrue-go                                              |
|                          |  ```:lua require'structrue-go'.open()```                               | Open structrue-go                                             |
| ```H```                  |  ```:lua require'structrue-go'.hide_others_methods_toggle()```         | Show or hidden the methods of struct whose not in current file|
| ```<CR>```               |  ```:lua require'structrue-go'.jump()```                               | Jump to the symbol file under cursor                          |
| ```R```                  |  ```:lua require'structrue-go'.refresh()```                            | Refresh symbols                                               |
| ```<leader>z```          |  ```:lua require'structrue-go'.fold_toggle()```                        | Toggle fold                                                   |
| ```P```                  |            ```:lua require'structrue-go'.preview_open()```             | Preview symbol context                                        |
| ```\p```                 |            ```:lua require'structrue-go'.preview_close()```            | Close preview symbol context                                  |
| ```<leader>f```          |            ```:lua require'structrue-go'.center_symbol()```             | Center the highlighted symbol                                 |

## Thanks

<a href="https://www.jetbrains.com/"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.png" alt="JetBrains Logo (Main) logo." width="100"></a>
