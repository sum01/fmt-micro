# fmt-micro
This is a multi-language formatting plugin for the [Micro text-editor.](https://github.com/zyedidia/micro)

Note that this plugin can only run installed/built-in formatters (such as `rustfmt` or `gofmt`).

## Supported formatters

|Formatter|Language(s)
|:---|:---
|[crystal tool format](https://github.com/crystal-lang/crystal)|`Crystal`
|[fish_indent](https://fishshell.com/docs/current/commands.html#fish_indent)|`Fish`
|[gofmt](https://golang.org/cmd/gofmt/)|`Go`
|[luafmt](https://github.com/trixnz/lua-fmt)|`Lua`
|[rubocop](https://github.com/bbatsov/rubocop)|`Ruby`
|[rustfmt](https://github.com/rust-lang-nursery/rustfmt)|`Rust`
|[shfmt](https://github.com/mvdan/sh)|`Shell`
|[php-cs-fixer](https://github.com/friendsofphp/PHP-CS-Fixer)|`PHP`
|[prettier](https://github.com/prettier/prettier)|`Javascript`, `JSX`, `Flow`, `TypeScript`, `CSS`, `Less`, `Sass`, `JSON`, `GraphQL`, `Markdown`
|[yapf](https://github.com/google/yapf)|`Python`

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
