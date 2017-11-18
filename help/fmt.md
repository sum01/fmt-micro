# fmt plugin

To manually run formatting on the current file, use the `fmt` command. You can
also just save the file, assuming you have `fmt-onsave` set to true.

To get a list of supported formatters, run the `fmt list` command. A table of
supported formatters will be printed to Micro's log.

To enable the individual formatters, run `set FormatterName true`.\
When saving a supported file-type, the plugin will automatically run on the file
& save any changes, unless you set `fmt-onsave` to false.

Please note that all formatters are disabled by default, as to not accidentally
format your files. You must enable them individually for this plugin to do
anything.

No formatters are bundled with this plugin. You must install the formatter you
want or it won't work.

## Notes for Uncrustify

Because Uncrustify requires a config file to run, I had to bundle it with the
plugin, but the name/path isn't hard-coded.

If you wish to edit its config, delete `defaults.cfg` in `configs/uncrustify`
and replace it with your desired `.cfg` file. The name doesn't matter.\
Optionally, you could make a symlink to your preffered file, then any time you change
your preferred config, the edits will take effect.
