# fmt-micro

This is a multi-language formatting plugin for the
[Micro text-editor.](https://github.com/zyedidia/micro)

This plugin does NOT bundle any formatters, so you must install whichever you
want to use.

## Supported formatters

| Formatter                                                                                                   | Language(s)                                                                                     |
| :---------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- |
| [crystal](https://github.com/crystal-lang/crystal)                                                          | `Crystal`                                                                                       |
| [fish_indent](https://fishshell.com/docs/current/commands.html#fish_indent)                                 | `Fish`                                                                                          |
| **[goimports](https://godoc.org/golang.org/x/tools/cmd/goimports)**, [gofmt](https://golang.org/cmd/gofmt/) | `Go`                                                                                            |
| [luafmt](https://github.com/trixnz/lua-fmt)                                                                 | `Lua`                                                                                           |
| [rubocop](https://github.com/bbatsov/rubocop)                                                               | `Ruby`                                                                                          |
| [rustfmt](https://github.com/rust-lang-nursery/rustfmt)                                                     | `Rust`                                                                                          |
| [shfmt](https://github.com/mvdan/sh)                                                                        | `Shell`                                                                                         |
| [php-cs-fixer](https://github.com/friendsofphp/PHP-CS-Fixer)                                                | `PHP`                                                                                           |
| [prettier](https://github.com/prettier/prettier)                                                            | `Javascript`, `JSX`, `Flow`, `TypeScript`, `CSS`, `Less`, `Sass`, `JSON`, `GraphQL`, `Markdown` |
| [uncrustify](https://github.com/uncrustify/uncrustify)                                                      | `C`, `C++`, `C#`, `Objective-C`, `D`, `Java`, `Pawn`, `Vala`                                    |
| [yapf](https://github.com/google/yapf)                                                                      | `Python`                                                                                        |

Note that you can also get a list of formatters by running the `fmt` command.

### Installation

To find your config's path, run `eval messenger:Message(configDir)`

1. Open your config's `settings.json`, and add
   `https://raw.githubusercontent.com/sum01/fmt-micro/master/repo.json` to
   `pluginrepos`, like so:

```json
"pluginrepos": [
  "https://raw.githubusercontent.com/sum01/fmt-micro/master/repo.json"
],
```

2. Run `plugin install fmt`
3. Restart Micro & it should work.

If this plugin is added to the
[official plugin channel](https://github.com/micro-editor/plugin-channel), you
can skip step 1 of the installation.

### Usage

The formatter will run on-save, unless `fmt-onsave` is false.

**Commands:**

* `fmt` to run the formatter on the current file.
* `fmt list` to output the supported formatters to Micro's log.

Run `help fmt` to bring up a help file while in Micro.
