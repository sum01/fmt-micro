# fmt plugin

To manually run formatting on the current file, use the `fmt` command.

When saving a supported file-type, the plugin will automatically run on the file
& save any changes, unless you set `fmt-onsave` to false.

To get the list of supported formatters, run the `fmt list` command. A table of
supported formatters will be printed to Micro's log.

To enable the individual formatters, run `set FormatterName true`. The specific
names can be found in the list from `fmt list`

Please note that all formatters are disabled by default, as to not accidentally
format your files. You must enable them individually for this plugin to do
anything.

## What's Bundled?

No formatters are bundled with this plugin. You must install the formatter you
want or it won't work.

Some config files are bundled with this plugin, but are only used when one can't
be found in your dir.

## Config Files

If you added a config file and want to update settings, run `fmt update` to
force settings to refresh.

The fallback paths to the bundled config files don't have hard-coded names, so
you can delete/edit the one in the relevant folder, and it should still work.
