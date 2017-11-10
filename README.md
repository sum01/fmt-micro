# fmt-micro
This is a multi-language formatting plugin for the [Micro text-editor.](https://github.com/zyedidia/micro)

Note that this plugin can only run installed/built-in formatters (such as `rustfmt` or `gofmt`).

## Supported formatters

|Formatter|Language(s)
|:---|:---
|[crystalfmt](https://github.com/crystal-lang/crystal)|`crystal`
|[fish_indent](https://fishshell.com/docs/current/commands.html#fish_indent)|`fish`
|[gofmt](https://golang.org/cmd/gofmt/)|`go`
|[luafmt](https://github.com/trixnz/lua-fmt)|`lua`
|[rubocop](https://github.com/bbatsov/rubocop)|`ruby`
|[rustfmt](https://github.com/rust-lang-nursery/rustfmt)|`rust`
|[shfmt](https://github.com/mvdan/sh)|`shell`
|[php-cs-fixer](https://github.com/friendsofphp/PHP-CS-Fixer)|`php`
|[prettier](https://github.com/prettier/prettier)|`javascript`, `jsx`, `flow`, `typescript`, `css`, `less`, `scss`, `json`, `graphql`, `markdown`
|[yapf](https://github.com/google/yapf)|`python`

Note that you can also get a list of formatters by running the `fmt` command.

### Installation
1. Open your config's `settings.json` (located in `~/.config/micro/settings.json` on Linux), and add `https://raw.githubusercontent.com/sum01/fmt-micro/master/repo.json` to `pluginrepos`, like so:
  ```json
  "pluginrepos": [
    "https://raw.githubusercontent.com/sum01/fmt-micro/master/repo.json"
  ],
  ```
2. Run `plugin install fmt`
3. Restart Micro & it should work.

If this plugin is added to the [official plugin channel](https://github.com/micro-editor/plugin-channel), you can skip step 1 of the installation.

### Usage
The formatter will run on-save (if enabled & exists).  
The only command is `fmt`, which lists all of the supported formatters.  
Run `help fmt` after installation to bring up a help file while in Micro.
