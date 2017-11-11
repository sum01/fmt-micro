# fmt plugin
To get a list of supported formatters, run the `fmt` command, or read the `README.md`

To enable the individual formatters, run `set FormatterName true`.  
When saving a supported file-type, the plugin will automatically run on the file & save any changes.

Please note that all formatters are disabled by default, as to not accidentally format your files. You must enable them individually for this plugin to do anything.

## Notes for Uncrustify
Because Uncrustify requires a config file to run, I had to bundle it with the plugin, but the name/path isn't hard-coded.

If you wish to edit its config, delete `defaults.cfg` in `configs/uncrustify` and replace it with your desired `.cfg` file. The name doesn't matter.  
Optionally, you could make a symlink to your preffered file, then any time you change your preferred config, the edits will take effect.
