# zoxide-add.yazi

Automatically add visited directories to [zoxide](https://github.com/ajeetdsouza/zoxide) while navigating in [Yazi](https://github.com/sxyazi/yazi).

## Requirements

- [zoxide](https://github.com/ajeetdsouza/zoxide) installed and available in your `PATH`

## Installation

```sh
ya pkg add mihem/zoxide-add
```

Or manually clone this repo into your Yazi plugins directory:

```sh
git clone https://github.com/mihem/zoxide-add.yazi.git \
  ~/.config/yazi/plugins/zoxide-add.yazi
```

## Usage

Add the following to your `~/.config/yazi/init.lua`:

```lua
require("zoxide-add"):setup()
```

That's it. Every time you change directories in Yazi, the new path is silently added to your zoxide database, so it becomes available for `z` jumps from your shell.
