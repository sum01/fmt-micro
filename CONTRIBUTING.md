# Contributing
To contribute, make sure you use the [editorconfig](http://editorconfig.org/) and [luafmt](https://github.com/trixnz/lua-fmt) plugin's to keep everything uniform.

To get something merged, first fork the repo, create a branch from `master`, push your changes, then submit a PR.  
Don't commit tons of changes in one big commit. Instead, use `git commit -p` to selectively add lines, then commit relevant changes.

## Adding another formatter:
- Do NOT add a formatter for an already supported filetype. There must not be dulplicate keys!
- Be careful with spaces when using `insert()` to add the formatter. Spaces get added between the command & args, and between args & the file.
- Using insert: `insert("filetype", "formattercommand", "args")` 
  - `filetype` should be from `CurView().Buf:FileType()`
    - If 2+ filetype's are supported, add them as a table (see how `prettier` was done).
  - `formattercommand` is the literal cli command to run the formatter (sans args)
  - If no args are needed, pass a `nil` value. Do NOT leave it empty!
- PS: Alphabetical order doesn't matter in relation to the order of `insert()` commands. The `fmt` command has a sort in it.
