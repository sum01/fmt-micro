# fmt-micro

[![GitHub tag](https://img.shields.io/github/tag/sum01/fmt-micro.svg)](https://github.com/sum01/fmt-micro/releases)

This is a multi-language formatting plugin for the
[Micro text-editor.](https://github.com/zyedidia/micro)

This plugin does NOT bundle any formatters, so you must install whichever you
want to use.

**Installation:** Just run `plugin install fmt` and restart Micro :+1:

## Language Support

| Language     | Supported Formatter(s)      |
| :----------- | :-------------------------- |
| C            | [clangformat], [uncrustify] |
| C#           | [uncrustify]                |
| C++          | [clangformat], [uncrustify] |
| CSS          | [csscomb], [prettier]       |
| Clojure      | [cljfmt]                    |
| CoffeeScript | [coffee-fmt]                |
| Crystal      | [crystal]                   |
| D            | [dfmt], [uncrustify]        |
| Elm          | [elm-format]                |
| Fish         | [fish_indent]               |
| Flow         | [prettier]                  |
| Go           | [gofmt], [goimports]        |
| GraphQL      | [prettier]                  |
| HTML         | [htmlbeautifier]            |
| Haskell      | [stylish-haskell]           |
| JSON         | [prettier]                  |
| JSX          | [prettier]                  |
| Java         | [uncrustify]                |
| JavaScript   | [js-beautify], [prettier]   |
| LaTeX        | [latexindent]               |
| Less         | [prettier]                  |
| Lua          | [luafmt]                    |
| Markdown     | [prettier]                  |
| Marko        | [marko-prettyprint]         |
| OCaml        | [ocp-indent]                |
| Objective-C  | [clangformat], [uncrustify] |
| PHP          | [php-cs-fixer]              |
| Pawn         | [uncrustify]                |
| Perl         | [perltidy]                  |
| Pug          | [pug-beautifier-cli]        |
| Puppet       | [puppet-lint]               |
| Python       | [autopep8], [yapf]          |
| Ruby         | [rubocop], [rufo]           |
| Rust         | [rustfmt]                   |
| Sass         | [prettier]                  |
| Shell        | [beautysh], [sh]            |
| TypeScript   | [prettier], [tsfmt]         |
| Vala         | [uncrustify]                |
| YAML         | [align-yaml]                |

### Usage

The formatter will run on-save, unless `fmt-onsave` is set to false.

**Commands:**

* `fmt` to run the formatter on the current file.
* `fmt list` to output the supported formatters to Micro's log.
* `fmt update` to force an update of the in-memory formatter settings. Useful
  for after adding a config file, or changing editor settings.

Run `help fmt` to bring up a help file while in Micro.

<!-- Table links to make the table easier to read in source -->

[align-yaml]: https://github.com/jonschlinkert/align-yaml
[autopep8]: https://github.com/hhatto/autopep8
[beautysh]: https://github.com/bemeurer/beautysh
[clangformat]: https://clang.llvm.org/docs/ClangFormat.html
[cljfmt]: https://github.com/snoe/node-cljfmt
[coffee-fmt]: https://github.com/sterpe/coffee-fmt
[crystal]: https://github.com/crystal-lang/crystal
[csscomb]: https://github.com/csscomb/csscomb.js
[dfmt]: https://github.com/dlang-community/dfmt
[elm-format]: https://github.com/avh4/elm-format
[fish_indent]: https://fishshell.com/docs/current/commands.html#fish_indent
[gofmt]: https://golang.org/cmd/gofmt/
[goimports]: https://godoc.org/golang.org/x/tools/cmd/goimports
[htmlbeautifier]: https://github.com/threedaymonk/htmlbeautifier
[js-beautify]: https://github.com/beautify-web/js-beautify
[latexindent]: https://github.com/cmhughes/latexindent.pl
[luafmt]: https://github.com/trixnz/lua-fmt
[marko-prettyprint]: https://github.com/marko-js/marko-prettyprint
[ocp-indent]: https://www.typerex.org/ocp-indent.html
[perltidy]: http://perltidy.sourceforge.net/
[pug-beautifier-cli]: https://github.com/lgaticaq/pug-beautifier-cli
[rubocop]: https://github.com/bbatsov/rubocop
[rufo]: https://github.com/ruby-formatter/rufo
[rustfmt]: https://github.com/rust-lang-nursery/rustfmt
[sh]: https://github.com/mvdan/sh
[stylish-haskell]: https://github.com/jaspervdj/stylish-haskell
[tsfmt]: https://github.com/vvakame/typescript-formatter
[php-cs-fixer]: https://github.com/friendsofphp/PHP-CS-Fixer
[prettier]: https://github.com/prettier/prettier
[puppet-lint]: http://puppet-lint.com/
[uncrustify]: https://github.com/uncrustify/uncrustify
[yapf]: https://github.com/google/yapf
