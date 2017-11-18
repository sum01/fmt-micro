# fmt-micro

This is a multi-language formatting plugin for the
[Micro text-editor.](https://github.com/zyedidia/micro)

This plugin does NOT bundle any formatters, so you must install whichever you
want to use.

## Supported formatters

| Formatter            | Language(s)                                                                                     |
| :------------------- | :---------------------------------------------------------------------------------------------- |
| [align-yaml]         | `YAML`                                                                                          |
| [clang-format]       | `C`, `C++`, `C#`                                                                                |
| [cljfmt]             | `Clojure`                                                                                       |
| [coffee-fmt]         | `CoffeeScript`                                                                                  |
| [crystal]            | `Crystal`                                                                                       |
| [CSScomb]            | `CSS`                                                                                           |
| [elm-format]         | `Elm`                                                                                           |
| [fish_indent]        | `Fish`                                                                                          |
| [goimports], [gofmt] | `Go`                                                                                            |
| [htmlbeautifier]     | `HTML`                                                                                          |
| [latexindent.pl]     | `LaTeX`                                                                                         |
| [luafmt]             | `Lua`                                                                                           |
| [marko-prettyprint]  | `Marko`                                                                                         |
| [ocp-indent]         | `OCaml`                                                                                         |
| [perltidy]           | `Perl`                                                                                          |
| [pug-beautifier-cli] | `Pug`                                                                                           |
| [rubocop]            | `Ruby`                                                                                          |
| [rustfmt]            | `Rust`                                                                                          |
| [shfmt]              | `Shell`                                                                                         |
| [php-cs-fixer]       | `PHP`                                                                                           |
| [prettier]           | `Javascript`, `JSX`, `Flow`, `TypeScript`, `CSS`, `Less`, `Sass`, `JSON`, `GraphQL`, `Markdown` |
| [uncrustify]         | `C`, `C++`, `C#`, `Objective-C`, `D`, `Java`, `Pawn`, `Vala`                                    |
| [yapf]               | `Python`                                                                                        |

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

<!-- Table links to make the table easier to read in source -->

[align-yaml]: https://github.com/jonschlinkert/align-yaml
[clang-format]: https://clang.llvm.org/docs/ClangFormat.html
[cljfmt]: https://github.com/snoe/node-cljfmt
[coffee-fmt]: https://github.com/sterpe/coffee-fmt
[crystal]: https://github.com/crystal-lang/crystal
[csscomb]: https://github.com/csscomb/csscomb.js
[elm-format]: https://github.com/avh4/elm-format
[fish_indent]: https://fishshell.com/docs/current/commands.html#fish_indent
[gofmt]: https://golang.org/cmd/gofmt/
[goimports]: https://godoc.org/golang.org/x/tools/cmd/goimports
[htmlbeautifier]: https://github.com/threedaymonk/htmlbeautifier
[latexindent.pl]: https://github.com/cmhughes/latexindent.pl
[luafmt]: https://github.com/trixnz/lua-fmt
[marko-prettyprint]: https://github.com/marko-js/marko-prettyprint
[ocp-indent]: https://www.typerex.org/ocp-indent.html
[perltidy]: http://perltidy.sourceforge.net/
[pug-beautifier-cli]: https://github.com/lgaticaq/pug-beautifier-cli
[rubocop]: https://github.com/bbatsov/rubocop
[rustfmt]: https://github.com/rust-lang-nursery/rustfmt
[shfmt]: https://github.com/mvdan/sh
[php-cs-fixer]: https://github.com/friendsofphp/PHP-CS-Fixer
[prettier]: https://github.com/prettier/prettier
[uncrustify]: https://github.com/uncrustify/uncrustify
[yapf]: https://github.com/google/yapf
