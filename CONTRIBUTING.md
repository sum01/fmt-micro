# Contributing

Everything below assumes you're using
[the Micro text-editor](https://github.com/zyedidia/micro) and this `fmt`
plugin.

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

* Be careful with spaces when using `insert()` to add the formatter. Spaces get
  added between the command & args, and between args & the file.
* Using insert: `insert("filetype", "formattercommand", {"args1", "arg2"})`
  * `filetype` should be from `CurView().Buf:FileType()`
    * If 2+ filetype's are supported, add them as a table (see how `prettier`
      was done).
    * To see if Micro supports the filetype, run `show filetype`. If the
      filetype is not known by Micro (displayed as `Unknown`), then use the
      literal file extension (without the period)
  * `formattercommand` is the literal command to run the formatter
  * `args` can be left empty, like `insert("filetype", "formattercommand")` if
    there aren't any, or at least any relevant ones.
    * If multiple are needed, add them as a table, like above.
    * If an arg depends on another, such as `--uses-tabs` and the `uses_tabs`
      var, put them in order of eachother, like this: `insert("filetype",
      "formattercommand", {"--uses-tabs", uses_tabs})`
      * Do NOT concat these together, as `JobSpawn` requires them seperate.
* PS: Alphabetical order doesn't matter in relation to the order of `insert()`
  commands. The `fmt list` command has a sort in it.

Note that regardless of how you structure the `insert()` code, the filepath is
always added to the end of the `args`, if there are any. Also, a space is added
between the `formattercommand`, `args`, and the filepath.

**Example:**\
`insert("python", "autopep8", "-i")`\
turns into the command..\
`autopep8 -i path/to/filename`
