# Contributing

Everything below assumes you're using
[the Micro text-editor](https://github.com/zyedidia/micro) and this `fmt`
plugin...

**Tooling for contributions:**

* Use the [editorconfig](http://editorconfig.org/) plugin to keep everything
  uniform, which can be installed by doing `plugin install editorconfig`
* Use [luafmt](https://github.com/trixnz/lua-fmt) if you're editing a `.lua`
  file, which can be enabled with `set luafmt true`
* Use [prettier](https://github.com/prettier/prettier) if you're editing a `.md`
  file, which can be enabled with `set prettier true`

## Git workflow

First fork the repo, create a branch from `master`, push your changes to your
repo, then submit a PR onto `master`.\
Please don't commit tons of changes in one big commit. Instead, use `git commit -p`
to selectively add lines.

## Adding another formatter:

* Do NOT add a formatter for an already supported filetype. There must not be
  dulplicate keys!
* Be careful with spaces when using `insert()` to add the formatter. Spaces get
  added between the command & args, and between args & the file.
* Using insert: `insert("filetype", "formattercommand", "args")`
  * `filetype` should be from `CurView().Buf:FileType()`
    * If 2+ filetype's are supported, add them as a table (see how `prettier`
      was done).
  * `formattercommand` is the literal cli command to run the formatter (sans
    args)
  * If no args are needed, pass a `nil` value. Do NOT leave it empty!
* PS: Alphabetical order doesn't matter in relation to the order of `insert()`
  commands. The `fmt` command has a sort in it.
