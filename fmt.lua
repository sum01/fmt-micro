VERSION = "1.3.0"

-- Lets the user disable the onSave() formatting
if GetOption("fmt-onsave") == nil then
  AddOption("fmt-onsave", true)
end

-- The "global" var (a dictionary) that holds all filetypes/commands/args
local fmt_table = {}
-- Hold the last used settings to be checked against later
local saved_settings = {}

local function indent_size()
  -- can't be 0
  return GetOption("tabsize")
end

local function using_tabs()
  -- We need to use this with concat in init_table, so use a string instead of bool
  local tabs = "false"
  -- returns a bool that tells whether the user is using spaces or not
  -- For our purposes, we reverse to an is_tabs for simplicity, instead of having to reverse every time
  if not GetOption("tabstospaces") then
    tabs = "true"
  end
  return tabs
end

local function compat_indent_size()
  -- Used for some args to signify tabs
  local compat = indent_size()

  if using_tabs() == "true" then
    -- shfmt uses this, as 0 signifies tabs
    compat = "0"
  end
  return compat
end

-- Initializes the dictionary of languages, their formatters, and the corresponding arguments
local function init_table()
  -- Makes inserting table values more flexible, and take less code per formatter
  local function insert(filetype, fmt, args)
    -- filetype should be passed as a table if the formatter supports more than 1 filetype.
    if type(filetype) == "table" then
      -- Split the table of types into a single value
      for _, val in pairs(filetype) do
        -- Recursively insert the values into the table
        insert(val, fmt, args)
      end
    else
      table.insert(fmt_table, {filetype, fmt, args})
    end
  end

  local indent = indent_size()
  local compat_indent = compat_indent_size()
  local uses_tabs = using_tabs()

  -- Save the used settings to be checked against later in the format() function
  -- Don't save compat, as there's no value to actually check it against in Micro
  saved_settings = {["indent"] = indent, ["tabs"] = uses_tabs}

  -- Saves the path to the current config dir for any config paths in the insert() commands below..
  -- Note: configDir and JoinPaths() are Micro-specific
  local conf_path = JoinPaths(configDir, "plugins", "fmt", "configs")
  messenger:AddLog("fmt: using config path '", conf_path .. "'")

  -- Empty out the table before filling it
  -- Recommended over doing fmt_table = {} to avoid new pointer
  for i in pairs(fmt_table) do
    fmt_table[i] = nil
  end

  -- The literal file extension can be used when Micro can't support the filetype

  insert("crystal", "crystal", "tool format")
  insert("fish", "fish_indent", "-w")
  -- Maybe switch to https://github.com/ruby-formatter/rufo
  insert("ruby", "rubocop", "-f quiet -o")
  -- Doesn't have any configurable args, and forces tabs.
  insert("go", "gofmt", "-s -w")
  insert("go", "goimports", "-w")
  -- Doesn't seem to have an actual option for tabs/spaces. stdout is default.
  insert("lua", "luafmt", "-i " .. indent .. " -w replace")
  -- Supports config files as well as cli options, unsure if this'll cause a clash.
  insert(
    {"javascript", "jsx", "flow", "typescript", "css", "less", "scss", "json", "graphql", "markdown"},
    "prettier",
    "--use-tabs " .. uses_tabs .. " --tab-width " .. indent .. " --write"
  )
  -- 0 signifies tabs, so we use compat
  insert("shell", "shfmt", "-i " .. compat_indent .. " -s -w")
  -- overwrite is default, and we can't pass config options
  insert("rust", "rustfmt")
  -- Doesn't support configurable args for tabs/spaces
  insert("python", "yapf", "-i")
  -- Does more than just format, but considering this is the best formatter for php, I'll allow it...
  insert("php", "php-cs-fixer", "fix")
  -- p is for the Pawn language (literal fallback)
  insert(
    {"c", "c++", "csharp", "objective-c", "d", "java", "p", "vala"},
    "uncrustify",
    "-c " .. JoinPaths(conf_path, "uncrustify") .. " --no-backup"
  )
  -- Options only available via a config file
  insert("clojure", "cljfmt")
  -- No args from what I've found | This might need "--yes" after the filepath, unsure
  insert("elm", "elm-format", "--yes")
  insert({"c", "c++", "objective-c"}, "clang-format", "-i")
  -- LaTeX
  insert("tex", "latexindent.pl", "-w")
  -- Unsure of the exact purpose of -t, but it's recommended when used as a tool
  -- https://github.com/csscomb/csscomb.js/blob/dev/doc/usage-cli.md#options
  insert("css", "csscomb", "-t")
  -- Seems to have some config options, but the ones we want aren't documented
  insert("marko", "marko-prettyprint")
  insert("ocaml", "ocp-indent")

  -- Keep the more annoying args in a table
  local unruly_args = {["htmlbeautifier"] = "-t " .. indent, ["coffee-fmt"] = "space", ["pug-beautifier"] = nil}
  -- Setting the non-flexible args | Seriously, why can't they be multi-purpose like these other formatters?..
  if uses_tabs == "true" then
    unruly_args["htmlbeautifier"] = "-T"
    unruly_args["coffee-fmt"] = "tab"
    unruly_args["pug-beautifier"] = "-t " .. indent
  end

  insert("html", "htmlbeautifier", unruly_args["htmlbeautifier"])
  insert(
    "coffeescript",
    "coffee-fmt",
    "--indent_style " .. unruly_args["coffee-fmt"] .. " --indent_size " .. indent .. " -i"
  )
  insert("pug", "pug-beautifier", unruly_args["pug-beautifier"])
end

-- Declares the options to enable/disable formatter(s)
local function create_options()
  -- Avoids manually defining commands twice by reading the table
  for _, value in pairs(fmt_table) do
    -- Creates the options to enable/disable formatters individually
    if GetOption(value[2]) == nil then
      -- Disabled by default, require user to enable for safety
      AddOption(value[2], false)
    end
  end
end

-- Initialize the table & options when opening Micro
function onViewOpen(view)
  -- A quick check if the table is empty
  if next(fmt_table) == nil then
    -- Only needs to run on the open of Micro
    init_table()
    create_options()
  end
end

-- Read the table to get a list of formatters for display
local function list_supported()
  -- index 1 is used to keep track of already-added formatters (to prevent duplicates)
  -- index 2 is actually displayed to the user
  local supported = {}
  -- Equal to the current formaters GetOption() status, to show if it's on or off
  local on_off
  -- A bool to tell the loop if the current formatter was already found
  local already_contains
  -- Equal to the length of the longest formatter name
  local max_pad_len = 0
  -- Used to hold the current formatters length
  local pad_len
  -- Just empty spaces to add padding for display
  local pad_string

  local function get_padding(len, pad_char)
    local padding = ""
    for _ = 0, len do
      padding = padding .. pad_char
    end
    return padding
  end

  -- Get the biggest length formatter name for building a correctly-sized table for display
  for _, value in pairs(fmt_table) do
    if value[2]:len() > max_pad_len then
      max_pad_len = value[2]:len()
    end
  end

  -- Loop through the main fmt_table, adding un-added formatters to the display table
  for _, value in pairs(fmt_table) do
    already_contains = false
    -- See if the value is already in the table
    for _, x in pairs(supported) do
      if x[1] == value[2] then
        -- Found a match, so break out
        already_contains = true
        break
      end
    end

    -- Don't duplicate inserts, such as "prettier", when they support multiple filetypes...
    -- since the fmt_table will technically contain lots of duplicate formatters on any multi-filetype formatters
    if not already_contains then
      -- Lets the user know what's enabled & what's not
      -- The weird spacing is to line up with "|Status|" correctly
      if GetOption(value[2]) then
        on_off = "on "
      else
        on_off = "off"
      end
      -- Fill a string with empty space equal to (longest formatter - current formatter)
      pad_len = max_pad_len - value[2]:len()
      pad_string = get_padding(pad_len, " ")
      -- Insert value[2] by itself in index 1 to be checked against, index 2 is for display only
      table.insert(supported, {value[2], "|" .. value[2] .. pad_string .. "|  " .. on_off .. "   |"})
    end
  end

  -- Output the formatters supported to the log, seperated by newlines
  -- 1 is the length of "  Formatter"
  pad_len = max_pad_len - 11
  pad_string = get_padding(pad_len, " ")
  local table_top = "|  Formatter" .. pad_string .. "| Status |\n"
  -- Use dashes to make a pretty table
  pad_string = get_padding(max_pad_len, "-")
  local separator = "+" .. pad_string .. "+--------+\n"

  local display_table = {}
  for _, val in pairs(supported) do
    -- index 2 is the display value
    table.insert(display_table, val[2])
  end
  -- Sort alphabetically.
  table.sort(display_table)

  -- Output the list (table) of formatters to the log
  messenger:AddLog(
    "\n" .. separator .. table_top .. separator .. table.concat(display_table, "\n") .. "\n" .. separator
  )

  messenger:Message("fmt: Supported formatters, and their status, were printed to the log.")
end

function onStdout(out)
  if out ~= nil and out ~= "" then
    messenger:AddLog("fmt info: ", out)
  end
end

function onExit()
  -- Refresh the CurView after the command finishes
  CurView():ReOpen()
end

function onStderr(err)
  if err ~= nil and err ~= "" then
    messenger:AddLog("fmt error: ", err)
  end
end

-- Find the correct formatter, its arguments, and then run on the current file
local function format()
  -- Prevent infinite loop of onSave()
  CurView():Save(false)

  -- Makes sure the table is using up-to-date settings in args
  if saved_settings["indent"] ~= indent_size() or saved_settings["tabs"] ~= using_tabs() then
    -- Reload the table (to get new args) if the user has changed their settings since opening Micro
    init_table()
  end

  -- Returns the literal file extension when called
  local function get_filetype()
    -- If there's no match, we return nil to fail format()
    local type = nil

    -- Iterates through the path, and captures any letters after a period
    -- Since it's an iter, the last pass will be the extension (if it exists)
    for gstring in string.gmatch(CurView().Buf.Path, "%.(%a*)") do
      type = gstring
    end

    return type
  end

  -- Save filetype for checking
  local file_type = CurView().Buf:FileType()

  -- Returns "Unknown" when Micro can't file the type, so we just grab the extension
  if file_type == "Unknown" then
    file_type = get_filetype()

    if file_type == nil then
      -- Stop running if unknown and unsupported filetype
      messenger:AddLog("fmt: Could not find a filetype, stopping early.")
      do
        return
      end
    else
      messenger:AddLog("fmt: Micro failed to get filetype, but I detected: ", file_type)
    end
  end

  local target_fmt = nil
  -- Parse the table, looking for a matching filetype
  -- Note that if there are multiples of the same filetype, only the first will get used
  for index, values in pairs(fmt_table) do
    -- Check if the formatter supports the found filetype
    if values[1] == file_type then
      -- Only use the specified formatter if it's enabled
      if GetOption(values[2]) then
        -- Save the table's values of the desired index to use below..
        target_fmt = fmt_table[index]
        -- Stop looking for more
        break
      end
    end
  end

  -- target_fmt[1] is filetype
  -- target_fmt[2] is the literal command (rustfmt, gofmt, etc.)
  -- target_fmt[3] is the (optional) args

  -- Only do anything if the filetype has is a supported formatter
  if target_fmt ~= nil then
    local file = CurView().Buf.Path
    local args = ""

    -- Check for args
    if target_fmt[3] ~= nil then
      args = target_fmt[3]
    end

    local command = target_fmt[2] .. " " .. args .. " " .. file
    -- Inform the user of exactly what will be ran
    messenger:AddLog('fmt: Running "' .. command .. '"')
    -- Actually run the formatter via Micro's "safe" JobSpawn
    JobStart(command, "fmt.onStdout", "fmt.onStderr", "fmt.onExit")
  end
end

function onSave(view)
  -- Allows for enable/disable on-save formatting via the option
  if GetOption("fmt-onsave") then
    format()
  end
end

-- A meta-command that triggers appropriate functions based on input
function fmt_usr_input(input)
  -- nil means they only typed "fmt"
  if input == nil then
    format()
  elseif input == "list" then
    -- "list" is the only other supported command at the moment
    list_supported()
  else
    -- This should probably never actually run...
    messenger:Message("fmt: Unknown command! Run 'help fmt' for info.")
  end
end

-- User command & help file
MakeCommand("fmt", "fmt.fmt_usr_input", 0)
AddRuntimeFile("fmt", "help", "help/fmt.md")
