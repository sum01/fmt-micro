# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1] - 2017-11-18

### Changed

* The two python formatters into one line like the `go` formatters.

### Fixes

* A whitespace error in the command.

## [2.0.0] - 2017-11-18

### Added

* The ability to have duplicate supported languages from formatters, which makes
  adding new formatters even safer/easier.
* This changelog :smile:
* The `fmt-onsave` option, to disable formatting on-save (on by default).
* A new `fmt list` command, which prints the supported formatters (and their
  on/off status) to Micro's log in a pretty table.
* Any output from the formatter is printed to Micro's log for easier debugging.
* `goimports` formatter for alternative `Go` support
* `htmlbeautifier` formatter for `HTML` support
* `coffee-fmt` formatter for `CoffeeScript` support
* `cljfmt` formatter for `Clojure` support
* `elm-format` formatter for `Elm` support
* `clang-format` formatter for alternative `C`, `C++`, and `Objective-C` support
* `pug-beautifier-cli` formatter for `Pug` (previously `Jade`) support
* `latexindent.pl` formatter for `LaTeX` support
* `CSScomb` formatter for alternative `CSS` support
* `marko-prettyprint` formatter for `Marko` support
* `ocp-indent` formatter for `OCaml` support
* `align-yaml` formatter for `YAML` support
* `perltidy` formatter for `Perl` support
* `stylish-haskell` formatter for `Haskell` support
* `puppet-lint` formatter for `Puppet` support
* `js-beautify` formatter for alternative `Javascript` support
* `autopep8` formatter for alternative `Python` support
* Some more info to `CONTRIBUTING.md`

### Changed

* The execution of the actual command, from Lua's `io.popen()`, to Micro's
  `JobStart()`, which should improve cross-platform support.
* The `fmt` command now runs the formatter on the current file.
* Applied as many [luacheck](https://github.com/mpeterv/luacheck)
  recommendations as possible, aka change stuff to `local`
* Formatted all the markdown files with the Prettier formatter

## [1.3.0] - 2017-11-11

### Added

* The full command to Micro's log.
* Users settings in the formatter arguments, where possible.
* Python support via the `yapf` formatter.
* PHP support via the `php-cs-fixer` formatter.
* A link to `CONTRIBUTING.md` in the pull request template.
* A `.gitignore` to hide a simple script I use for testing.
* All the languages supported by `uncrustify`, and its `defaults.cfg` config
  file.

### Changed

* The "how to add a formatter" comments got moved from the code to
  [CONTRIBUTING.md](./CONTRIBUTING.md)
* To using the `CurView()` passed from onSave instead of manually calling
  `CurView()`
* `fmt.lua` formatted with luafmt.
* The name of Crystal's formatter in the README.
* Capitalized the languages in the README.

### Fixed

* The `if` check to see if the current settings match the ones used by the fmt
  args.

### Removed

* The redundant psudo-contributing guide in the pull request template.

## [1.2.1] - 2017-11-09

### Added

* The fact that markdown works with Prettier to the README.
* A literal file extension detection fallback for when Micro returns `Unknown`
  on the filetype.

## [1.2.0] - 2017-11-07

### Added

* Markdown to Prettier's file-type support.

## [1.1.1] - 2017-11-07

### Added

* Pull request template for Github.
* Issue template for Github.

### Fixed

* Crystal actually uses the correct command now..

## [1.1.0] - 2017-11-07

### Added

* Crystal formatting.

### Changed

* Flipped the table to hopefully look better.

## [1.0.1] - 2017-11-07

### Fixed

* Rubocop
* Luafmt

## 1.0.0 - 2017-11-06

First release

[unreleased]: https://github.com/sum01/fmt-micro/compare/v2.0.1...HEAD
[2.0.1]: https://github.com/sum01/fmt-micro/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/sum01/fmt-micro/compare/v1.3.0...v2.0.0
[1.3.0]: https://github.com/sum01/fmt-micro/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/sum01/fmt-micro/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/sum01/fmt-micro/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/sum01/fmt-micro/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sum01/fmt-micro/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/sum01/fmt-micro/compare/v1.0.0...v1.0.1
