# structrue-go.nvim
A better structured display of golang symbol information

## Description
I use some plugins that reflect the file struct, they support many languages, but they can't be implemented well in golang, especially in struct and method. Because if a struct has many methods and you don't want the file to be too large,  the struct and the methods belonging to it can be in different files. I hope to create a plugin like goland structure that can show or hide the methods in the structure that are not in the current file.

## Demo

[video demo](https://youtu.be/ePg0UYjWyHU)

## Features

**Categorize symbols and show hierarchical relationships**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature1-min.png" width="850">

**Jump from symbols and highlight the corresponding symbol under the cursor line**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature2-min.png" width="850">

**Toggle methods of struct whose not in current file and hl them**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature3-1-min.png" width="400" height="705"> <img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature3-2-min.png" width="400" height="705">

**Able to fold imports、const、var、func、type、interface and always remember folding state even when switching files**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature4-1-min.png" width="400" height="705"> <img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature4-2-min.png" width="400" height="705">

**Preview**

<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature5-min.png" width="850">

**Float support**

```config.position = "float"```
<img src="https://github.com/crusj/structrue-go.nvim/blob/main/screenshots/feature6-min.png" width="850">


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
	indent = "┠",  -- Hierarchical indent icon, nil or empty will be a tab
	position = "botright", -- window position,default botright,also can set float
	symbol = { -- symbol style
		filename = {
			hl = "guifg=Black", -- highlight symbol,value can set by help highlight-gui
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

| Keymap                   | Action                                                                 | Description                                                   | 
| -------------------------|------------------------------------------------------------------------|---------------------------------------------------------------| 
| ```<leader>m```          |  ```:lua require'structrue-go'.toggle()```                             | Toggle structure-go                                           |
| ```H```                  |  ```:lua require'structrue-go'.hide_others_methods_toggle()```         | Show or hidden the methods of struct whose not in current file|
| ```<CR>```               |  ```:lua require'structrue-go'.jump()```                               | Jump to the symbol file under cursor                          |
| ```R```                  |  ```:lua require'structrue-go'.refresh()```                            | Refresh symbols                                               |
| ```<leader>z```          |  ```:lua require'structrue-go'.fold_toggle()```                        | Toggle fold                                                   |
| ```P```                  |  ```:lua require'structrue-go'.preview_open()```                       | Preview symbol context                                        |
| ```\p```                 |  ```:lua require'structrue-go'.preview_close()```                      | Close preview symbol context                                  |

