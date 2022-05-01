# structrue-go.nvim
A better structured display of golang symbol information

## Description
I use some plugins that reflect the file struct, they support many languages, but they can't be implemented well in golang, especially in struct and method. Because if a struct has many methods and you don't want the file to be too large,  the struct and the methods belonging to it can be in different files. I hope to create a plugin like goland structure that can show or hide the methods in the structure that are not in the current file.

## Demo

[video demo](https://youtu.be/ePg0UYjWyHU)

## Features

**Categorize symbols and show hierarchical relationships**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature1.png" width="350">

**Jump from symbols and highlight the corresponding symbol under the cursor line**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature2.png" width="350">

**Toggle methods of struct whose not in current file and hl them**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature3.png" width="350">

**Able to fold imports、const、var、func、type、interface and always remember folding state even when switching files**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature4.png" width="350">

**Preview**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature5.png" width="350">

**Configurable highlights, icons, shortcuts**


## Install 

### Requirement

**nvim0.7**

**gotags**

```shell
go get -u github.com/jstemmer/gotags
```

### Install

**Packer**

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
require"structrue-go".setup({})
```

### Default config

```lua
local default_config = {
	show_others_method = true, -- bool show methods of struct whose not in current file
	show_filename = true, -- bool
	number = "no", -- show number: no | nu | rnu
	fold_open_icon = " ",
	fold_close_icon = " ",
	cursor_symbol_hl = "guibg=Gray guifg=White", -- symbol hl under cursor,
	symbol = { -- symbol style
		filename = {
			hl = "guifg=Black", -- highlight symbol
			icon = " " -- symbol icon
		},
		package = {
			hl = "guifg=Red",
			icon = "⊞ "
		},
		import = {
			hl = "guifg=Grey",
			icon = "⌬ "
		},
		const = {
			hl = "guifg=Orange",
			icon = "π ",
		},
		variable = {
			hl = "guifg=Magenta",
			icon = "◈ ",
		},
		func = {
			hl = "guifg=DarkBlue",
			icon = "◧ ",
		},
		interface = {
			hl = "guifg=Green",
			icon = "❙ "
		},
		type = {
			hl = "guifg=Purple",
			icon = "▱ ",
		},
		struct = {
			hl = "guifg=Purple",
			icon = "❏ ",
		},
		field = {
			hl = "guifg=DarkYellow",
			icon = "▪ "
		},
		method_current = {
			hl = "guifg=DarkGreen",
			icon = "◨ "
		},
		method_others = {
			hl = "guifg=LightGreen",
			icon = "◨ "
		},
	},
	keymap = {
		toggle = "<leader>m", -- toggle structure-go window
		show_others_method_toggle = "H", -- show or hidden the methods of struct whose not in current file
		symbol_jump = "<CR>", -- jump to then symbol file under cursor
		fold_toggle = "\\z",
		refresh = "R" -- refresh symbols
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
}

```

### Description

| Operation                | Default Keymap                                                 | Description                                                   | 
| -------------------------|---------------------------------------------------------------|--------------------------------------------------------------| 
| toggle symbols           | ```<leader>m```   ```:lua require'structrue-go'.toggle()```               | toggle structure-go                                           |
| show_others_method_toggle| ```H```        ```:lua require'structrue-go'.hide_others_methods_toggle()```  | show or hidden the methods of struct whose not in current file|
| symbol_jump              | ```CR```   ```:lua require'structrue-go'.jump()```  | jump to the symbol file under cursor                          |
| refresh             | ```R```   ```:lua require'structrue-go'.refresh()```  | refresh symbols                          |
| fold_toggle              | ```<leader>z```     ```:lua require'structrue-go'.fold_toggle()```         | toggle fold                                                   |
| preview_open              | ```P```     ```:lua require'structrue-go'.preview_open```         | preview symbol context                                                   |
| preview_close              | ```\p```     ```:lua require'structrue-go'.preview_close```         | close preview symbol context                                                   |


