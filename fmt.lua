VERSION = "1.3.0"

-- Get user settings to use in formatter args
function get_settings()
  local indent_size = GetOption("tabsize") -- can't be 0
  local is_tabs = ""
  -- returns a bool
  if GetOption("tabstospaces") then
    -- We need to use this with concat in init_table, so use a string instead of bool
    is_tabs = "false"
  else
    is_tabs = "true"
  end
  -- Used for some args to signify tabs
  local compat_indent_size = indent_size

  if is_tabs == "true" then
    -- shfmt uses this, as 0 signifies tabs
    compat_indent_size = "0"
  end

  return {["indent_size"] = indent_size, ["is_tabs"] = is_tabs, ["compat_indent_size"] = compat_indent_size}
end

-- Initializes the dictionary of languages, their formatters, and the corresponding arguments
function init_table()
  -- Dictionary of commands for easy lookup & manipulation.
  fmt_table = {}

  -- Shorthand function to reduce cruft & enhance readability...
  function insert(filetype, fmt, args)
    -- filetype is expected to be passed as a table if the formatter supports more than 1 filetype.
    if type(filetype) == "table" then
      for _, val in pairs(filetype) do
        -- Recursively insert the values into the table
        insert(val, fmt, args)
      end
    else
      -- Can't use table.insert here as we're using strings for the key values.
      fmt_table[filetype] = {fmt, args}
    end
  end

  -- Get the user's settings to be used in args
  local usr_settings = get_settings()

  local indent_size = usr_settings["indent_size"]
  local is_tabs = usr_settings["is_tabs"]
  local compat_indent_size = usr_settings["compat_indent_size"]

  -- nil to trigger garbage collection
  usr_settings = nil

  -- Use os-specific slash for paths
  local os_slash = "/"
  if OS == "windows" then
    os_slash = "\\"
  end
  -- Bulds the path to the current config dir. configDir is a Micro-specific var that returns the path to Micro's config dir.
  local fmt_conf_path = configDir .. os_slash .. "plugins" .. os_slash .. "fmt" .. os_slash .. "configs"
  -- Saves the path to uncrustify's config file (which is required to run), but don't hard-code a name to allow for user replacement.
  local uncrustify_confpath = fmt_conf_path .. os_slash .. "uncrustify"
  messenger:AddLog('fmt: configs loaded from path "', fmt_conf_path .. '"')

  insert("crystal", "crystal", "tool format")
  insert("fish", "fish_indent", "-w")
  -- Maybe switch to https://github.com/ruby-formatter/rufo
  insert("ruby", "rubocop", "-f quiet -o")
  -- Doesn't have any configurable args, and forces tabs.
  insert("go", "gofmt", "-w")
  -- Doesn't seem to have an actual option for tabs/spaces. stdout is default.
  insert("lua", "luafmt", "-i " .. indent_size .. " -w replace")
  -- Supports config files as well as cli options, unsure if this'll cause a clash.
  insert(
    {"javascript", "jsx", "flow", "typescript", "css", "less", "scss", "json", "graphql", "markdown"},
    "prettier",
    "--use-tabs " .. is_tabs .. " --tab-width " .. indent_size .. " --write"
  )
  -- 0 signifies tabs, so we use compat
  insert("shell", "shfmt", "-i " .. compat_indent_size .. " -s -w")
  -- overwrite is default. Can't pass config options, configured via rustfmt.toml
  insert("rust", "rustfmt", nil)
  -- Doesn't support configurable args for tabs/spaces
  insert("python", "yapf", "-i")
  -- Does more than just format, but considering this is the best formatter for php, I'll allow it...
  insert("php", "php-cs-fixer", "fix")
  -- p is for the Pawn language. Micro can't detect it, so we're using the literal extension fallback.
  insert(
    {"c", "c++", "csharp", "objective-c", "d", "java", "p", "vala"},
    "uncrustify",
    "-c " .. uncrustify_confpath .. " --no-backup"
  )
end

-- Declares the options to enable/disable formatter(s)
function create_options()
  -- Avoids manually defining commands twice by reading the table
  for _, value in pairs(fmt_table) do
    -- Creates the options to enable/disable formatters individually
    if GetOption(value[1]) == nil then
      -- Disabled by default, require user to enable for safety
      AddOption(value[1], false)
    end
  end
end

-- Initialize the table & options when opening Micro
function onViewOpen(view)
  -- Only needs to run on the open of Micro
  if fmt_table == nil then
    init_table()
    create_options()
  end
end

-- Read the table to get a list of formatters for display
function list_supported()
  local supported = {}

  for _, value in pairs(fmt_table) do
    -- Don't duplicate inserts, such as "prettier", when they support multiple filetypes.
    -- Credit to https://stackoverflow.com/a/20067270
    if (not supported[value[1]]) then
      table.insert(supported, value[1])
      supported[value[1]] = true
    end
  end

  -- Sort alphabetically.
  table.sort(supported)

  -- Output the list of accepted formatters, delimited by commas
  messenger:Message("fmt's supported formatters: " .. table.concat(supported, ", ") .. ".")
end

-- Find the correct formatter, its arguments, and then run on the current file
function format(cur_view)
  -- Returns the literal file extension when called
  local function get_filetype()
    -- What we'll return
    local type = ""

    -- Iterates through the path, and captures any letters after a period
    -- Since it's an iter, the last pass will be the extension (if it exists)
    for gstring in string.gmatch(cur_view.Buf.Path, "%.(%a*)") do
      type = gstring
    end

    messenger:AddLog("fmt: Micro failed to get filetype, but I detected: ", type)
    return type
  end

  -- Prevent infinite loop of onSave()
  cur_view:Save(false)

  -- Save filetype for checking
  local file_type = cur_view.Buf:FileType()

  -- Returns "Unknown" when Micro can't file the type, so we just grab the extension
  if file_type == "Unknown" then
    file_type = get_filetype()
  end

  -- The filetype name (`rust`, `shell`, etc.) is the table's key
  -- The literal file extension can be used when Micro can't support the filetype
  -- [1] is the cmd, [2] is args
  local target_fmt = fmt_table[file_type]

  -- Only do anything if the filetype has is a supported formatter
  if target_fmt ~= nil then
    -- Only do anything if the specified formatter is enabled
    if GetOption(target_fmt[1]) then
      -- Load in the 'base' command (ex: `rustfmt`, `gofmt`, etc.)
      local cmd = target_fmt[1]
      -- Check for args
      if target_fmt[2] ~= nil then
        -- Add a space between cmd & args
        cmd = cmd .. " " .. target_fmt[2]
      end

      messenger:AddLog('fmt: Running "' .. cmd .. '" on "' .. cur_view.Buf.Path .. '"')

      -- Actually run the format command
      local handle = io.popen(cmd .. " " .. cur_view.Buf.Path)
      local result = handle:read("*a")
      handle:close()
      -- Reload
      cur_view:ReOpen()
    end
  end
end

function onSave(view)
  local settings = get_settings()
  -- is_tabs uses == because it'll be the opposite of tabstospaces if it's correct
  if settings["indent_size"] ~= GetOption("tabsize") or settings["is_tabs"] == GetOption("tabstospaces") then
    -- Reload the table (to get new args) if the user has changed their settings since opening Micro
    init_table()
  end
  -- nil to trigger garbage collection
  settings = nil

  format(view)
end

-- User command & help file
MakeCommand("fmt", "fmt.list_supported", 0)
AddRuntimeFile("fmt", "help", "help/fmt.md")
