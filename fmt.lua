VERSION = "2.3.0"

-- All questions about weird performance optimizations should be directed here: https://springrts.com/wiki/Lua_Performance

-- Lets the user disable the onSave() formatting
if GetOption("fmt-onsave") == nil then
  AddOption("fmt-onsave", true)
end

-- The "global" var (a dictionary) that holds all filetypes/commands/args
local fmt_table = {}
-- Hold the last used settings to be checked against later
local saved_setting = {["indent"] = nil, ["tabs"] = nil}

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

local function get_extension(x)
  local function get_gopath_ext(f_path)
    -- Grab the extension if Micro failed
    local golib_path = import("path")
    local f_type = golib_path.Ext(f_path)

    -- Returns an empty string if it doesn't find an extension
    if f_type == "" then
      -- Stop running if there's no extension
      return nil
    else
      -- Return the extension without the period from Go's path.Ext()
      return f_type:sub(2)
    end
  end

  local file_type = nil

  -- When passed a view, first try the built-in CurView().Buf:FileType()
  if x == CurView() then
    file_type = x.Buf:FileType()
    -- Returns "Unknown" when Micro can't file the type
    if file_type == "Unknown" then
      -- Fallback to the literal extension
      file_type = get_gopath_ext(x.Buf.Path)
    end
  else
    -- When passed a direct path, use Go's path lib
    file_type = get_gopath_ext(x)
  end

  return file_type
end

-- Returns a full path to either a config file in the directory, or our bundled one
-- extension should be a string of the file extension needed, sans period
-- name is the folder name in our bundled configs | ex: fmt-micro/configs/NAME
local function get_conf(name, extension)
  -- The current local dir
  local dir = WorkingDirectory()
  -- Go's ioutil library for scanning the current dir
  local go_ioutil = import("ioutil")
  -- Gets an array of all the files in the current dir
  local readout = go_ioutil.ReadDir(dir)

  if readout ~= nil then
    -- The current extension for comparison to what's valid
    local readout_extension
    -- The full path to the file
    local readout_path

    for i = 1, #readout do
      -- Save the current file's full path
      readout_path = JoinPaths(dir, readout[i]:Name())
      -- get extension of current file
      readout_extension = get_extension(readout_path)

      -- if extension matches, return path to the config file
      if readout_extension == extension then
        messenger:AddLog("fmt: Found " .. name .. '\'s config, using "' .. readout_path .. '"')
        -- Return the found local config
        return readout_path
      end
    end
  end

  -- Fallback onto our bundled config if no local one is found
  local bundled_conf = JoinPaths(configDir, "plugins", "fmt", "configs", name)
  messenger:AddLog("fmt: Didn't find " .. name .. '\'s config, using bundled "', bundled_conf .. '"')
  -- Return the bundled config path for the requested config
  return bundled_conf
end

-- Initializes the dictionary of languages, their formatters, and the corresponding arguments
local function init_table()
  -- Localize for speed (outside of insert function to reduce recursive memory usage)
  local type = type
  local table_insert = table.insert
  local table_remove = table.remove
  -- keep track of which index we're on in fmt_table
  local fmt_count = 1

  -- Makes inserting table values more flexible, and take less code per formatter
  local function insert(filetype, fmt, args)
    -- filetype should be passed as a table if the formatter supports more than 1 filetype.
    if type(filetype) == "table" then
      -- Split the table of types into a single value
      for i = 1, #filetype do
        -- Recursively insert the values into the table
        insert(filetype[i], fmt, args)
      end
    else
      if type(args) == "table" then
        local function unfold_args(nested_args, nest_args_index)
          -- Remove the current (nested) args
          table_remove(args, nest_args_index)

          -- loop through the nested args
          for index = 1, #nested_args do
            -- Insert the nested args one at a time at the position it was removed from
            table_insert(args, nest_args_index, nested_args[index])
            -- Keep moving back so that each insert doesn't put things out of order
            nest_args_index = nest_args_index + 1
          end
        end

        -- Loop through args to unfold nested args
        for i = 1, #args do
          -- This nested table check will happen on some unruly_args
          if type(args[i]) == "table" then
            -- Removes the nested args by placing them 1-by-1 into their own index
            unfold_args(args[i], i)
          end
        end
      else
        -- Just lets us not have to brace single/no-command formatters when doing insert()
        args = {args}
      end

      -- Actually insert the table into the table in the format shown:
      -- fmt_table[1] = filetype
      -- fmt_table[2] = formatter_cmd
      -- fmt_table[3] = {args}
      fmt_table[fmt_count] = {filetype, fmt, args}
      fmt_count = fmt_count + 1
    end -- end of if type(filetype) check
  end -- end of insert() function

  -- Save the used settings to be checked against later in the format() function
  saved_setting["indent"] = indent_size()
  saved_setting["tabs"] = using_tabs()

  -- Empty out the table before filling it
  -- Recommended over doing fmt_table = {} to avoid new pointer
  for i = 1, #fmt_table do
    fmt_table[i] = nil
  end

  -- The literal file extension (without period) can be used when Micro doesn't recognize the filetype

  insert("crystal", "crystal", {"tool", "format"})
  insert("fish", "fish_indent", "-w")
  -- Doesn't seem to have config options
  insert("ruby", "rufo")
  insert("ruby", "rubocop", {"-f", "quiet", "-o"})
  -- Doesn't have any configurable args, and forces tabs.
  insert("go", "gofmt", {"-s", "-w"})
  insert("go", "goimports", "-w")
  -- Doesn't seem to have an actual option for tabs/spaces. stdout is default.
  insert("lua", "luafmt", {"-i", saved_setting["indent"], "-w", "replace"})
  -- Supports config files as well as cli options, unsure if this'll cause a clash.
  insert(
    {"javascript", "jsx", "flow", "typescript", "css", "less", "scss", "json", "graphql", "markdown"},
    "prettier",
    {"--use-tabs", saved_setting["tabs"], "--tab-width", saved_setting["indent"], "--write"}
  )
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
    {"-c", get_conf("uncrustify", "cfg"), "--no-backup"}
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
  -- Overwrite is default if only source (-s) used
  insert("yaml", "align", {"-p", saved_setting["indent"], "-s"})
  insert("haskell", "stylish-haskell", "-i")
  insert("puppet", "puppet-lint", "--fix")
  -- The -a arg can be used multiple times to increase aggresiveness. Unsure of what people prefer, so doing 1.
  insert("python", "autopep8", {"-a", "-i"})
  insert("typescript", "tsfmt", "-r")

  -- Keep the more annoying args in a table
  local unruly_args = {
    ["htmlbeautifier"] = {"-t", saved_setting["indent"]},
    ["coffee-fmt"] = "space",
    ["pug-beautifier"] = nil,
    ["perltidy"] = {"-i=", saved_setting["indent"]},
    ["js-beautify"] = {"-s", saved_setting["indent"]},
    ["shfmt"] = saved_setting["indent"],
    ["beautysh"] = {"-i", saved_setting["indent"]},
    ["dfmt"] = {"space", "--indent_size"},
    -- Just used to convert tabs to spaces
    ["tidy"] = saved_setting["indent"]
  }
  -- Setting the non-flexible args | Seriously, why can't they be multi-purpose like these other formatters?..
  if saved_setting["tabs"] == "true" then
    unruly_args["htmlbeautifier"] = "-T"
    unruly_args["coffee-fmt"] = "tab"
    unruly_args["pug-beautifier"] = {"-t", saved_setting["indent"]}
    unruly_args["perltidy"] = {"-et=", saved_setting["indent"]}
    unruly_args["js-beautify"] = "-t"
    -- 0 signifies tabs
    unruly_args["shfmt"] = "0"
    unruly_args["beautysh"] = "-t"
    unruly_args["dfmt"] = {"tab", "--tab_width"}
    -- Tells it to retain tabs, instead of converting them to spaces
    unruly_args["tidy"] = "0"
  end

  insert("html", "htmlbeautifier", unruly_args["htmlbeautifier"])
  insert(
    "coffeescript",
    "coffee-fmt",
    {"--indent_style", unruly_args["coffee-fmt"], "--indent_size", saved_setting["indent"], "-i"}
  )
  insert("pug", "pug-beautifier", unruly_args["pug-beautifier"])
  insert("perl", "perltidy", unruly_args["perltidy"])
  insert({"css", "html", "javascript"}, "js-beautify", {unruly_args["js-beautify"], "-r", "-f"})
  insert("shell", "shfmt", {"-i", unruly_args["shfmt"], "-s", "-w"})
  insert("shell", "beautysh.py", {unruly_args["beautysh"], "-f"})
  insert("d", "dfmt", {"--indent_style", unruly_args["dfmt"], saved_setting["indent"], "-i"})
  -- drop-empty-elements is false because Bootstrap uses empty elements
  insert(
    {"html", "xml"},
    "tidy",
    {
      "--indent",
      "auto",
      "--indent-spaces",
      saved_setting["indent"],
      "--tab-size",
      unruly_args["tidy"],
      "--indent-with-tabs",
      saved_setting["tabs"],
      "--drop-empty-elements",
      "false",
      "-m"
    }
  )
end

-- Declares the options to enable/disable formatter(s)
local function create_options()
  local value
  -- Avoids manually defining commands twice by reading the table
  for i = 1, #fmt_table do
    value = fmt_table[i]
    -- Creates the options to enable/disable formatters individually
    if GetOption(value[2]) == nil then
      -- Disabled by default, require user to enable for safety
      AddOption(value[2], false)
    end
  end
end

-- Returns an iteration of the table passed
-- Just used to check if a table is nil or not basically
local function next_table(t)
  -- Storing this as local is supposedly faster
  local next = next
  return next(t)
end

-- Initialize the table & options when opening Micro
function onViewOpen(view)
  -- A quick check if the table is empty
  if next_table(fmt_table) == nil then
    -- Only needs to run on the open of Micro
    init_table()
    create_options()
  end
end

-- Read the table to get a list of formatters for display
local function list_supported()
  local function get_max_len()
    local value
    local max_len = 0
    local cur_len
    -- Get the biggest length formatter name for building a correctly-sized table for display
    for i = 1, #fmt_table do
      value = fmt_table[i]

      cur_len = value[2]:len()

      if cur_len > max_len then
        max_len = cur_len
      end
    end

    return max_len
  end

  -- Equal to the length of the longest formatter name
  local max_pad_len = get_max_len()

  -- Used to hold the current formatters length
  local pad_len
  -- Used to add padding for display output
  local pad_string

  local function get_padding(len, pad_char)
    -- Add vals into a table. Concat in a loop is laggy
    local padding = {}
    for i = 1, len do
      padding[i] = pad_char
    end
    -- Localize for speed
    local table_concat = table.concat
    return table_concat(padding)
  end

  -- index 1 is used to keep track of already-added formatters (to prevent duplicates)
  -- index 2 is actually displayed to the user
  local unique_formatters = {}

  local function check_contains(check_against)
    -- See if the value is already in the table
    for index = 1, #unique_formatters do
      if unique_formatters[index] == check_against then
        -- Found a match
        return true
      end
    end
    -- No match
    return false
  end

  local display_supported = {}
  -- Holds a single index of fmt_table in the loop
  local value
  -- Used to keep track of what index we're on in display_supported & unique_formatters
  local table_count = 1
  -- Equal to the current formaters GetOption() status, to show if it's on or off
  local on_off
  -- A bool to tell the loop if the current formatter was already found
  local already_contains

  -- Loop through the main fmt_table, adding un-added formatters to the display table
  for i = 1, #fmt_table do
    -- Hold the current index val for checking
    value = fmt_table[i]

    -- True/False if the current formatter cmd is already in the supported table
    already_contains = check_contains(value[2])

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

      -- Insert value[2] by itself to be checked against
      unique_formatters[table_count] = value[2]
      -- Purely for display to the user from inside of Micro's log
      display_supported[table_count] = "|" .. value[2] .. pad_string .. "|  " .. on_off .. "   |"
      -- Increment to not overwrite already added values
      table_count = table_count + 1
    end
  end

  -- Output the formatters supported to the log, seperated by newlines
  -- 11 is the length of "  Formatter"
  pad_len = max_pad_len - 11
  pad_string = get_padding(pad_len, " ")
  local table_top = "|  Formatter" .. pad_string .. "| Status |\n"
  -- Use dashes to make a pretty table
  pad_string = get_padding(max_pad_len, "-")
  local separator = "+" .. pad_string .. "+--------+\n"

  -- Localize for speed
  local table_sort = table.sort
  local table_concat = table.concat

  -- Sort alphabetically.
  table_sort(display_supported)

  -- Output the list (table) of formatters to the log
  messenger:AddLog(
    "\n" .. separator .. table_top .. separator .. table_concat(display_supported, "\n") .. "\n" .. separator
  )

  messenger:Message("fmt: Formatter list printed to the log.")
end

function onStdout(out)
  if out ~= nil and out ~= "" then
    messenger:AddLog("fmt info: ", out)
  end
end

function onExit()
  -- Refresh the CurView after the command finishes
  -- I've found .Buf:ReOpen() to be more smooth than just :ReOpen(), at least on crap machines
  CurView().Buf:ReOpen()
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
  if saved_setting["indent"] ~= indent_size() or saved_setting["tabs"] ~= using_tabs() then
    -- Reload the table (to get new args) if the user has changed their settings since opening Micro
    init_table()
  end

  -- Save filetype for checking
  local file_type = get_extension(CurView())
  -- Stop running if no extension/filetype
  if file_type == nil then
    do
      return
    end
  end

  local file_path = CurView().Buf.Path

  local function get_valid_fmt()
    -- localize for speed
    local type = type
    local setmetatable = setmetatable
    local getmetatable = getmetatable
    -- Needed to prevent table.insert from inserting into "fmt_table" when targetting "target_fmt"
    local function deepcopy(orig)
      local orig_type = type(orig)
      local copy
      if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
      else -- number, string, boolean, etc
        copy = orig
      end
      return copy
    end

    local values
    -- Parse the table, looking for a matching filetype
    -- Note that if there are multiples of the same filetype, only the first will get used
    for i = 1, #fmt_table do
      values = fmt_table[i]
      -- Check if the formatter supports the found filetype
      if values[1] == file_type then
        -- Only use the specified formatter if it's enabled
        if GetOption(values[2]) then
          -- Save the table's values of the desired index to use below..
          return deepcopy(values)
        end
      end
    end
    -- Return nil if there aren't matches
    return nil
  end

  local target_fmt = get_valid_fmt()

  -- target_fmt[1] is filetype
  -- target_fmt[2] is the literal command (rustfmt, gofmt, etc.)
  -- target_fmt[3] is the (optional) args

  -- Only do anything if the filetype has is a supported formatter
  if target_fmt ~= nil then
    -- Check for if any args (index 3 is a table of args)
    -- Formatters like `rustfmt` will have nil args
    if next_table(target_fmt[3]) ~= nil then
      -- Localize for speed
      local table_insert = table.insert
      -- Add the file to the end of args | table.insert to ensure order
      table_insert(target_fmt[3], file_path)
    else
      -- If there aren't args (such as for `rustfmt`) then just equal the filepath
      -- Has to be a table because JobSpawn requires the args as a table/array
      target_fmt[3] = {file_path}
    end

    -- Build the string to show the user what'll actually run
    local output_string = target_fmt[2]
    -- Localize for speed | ipairs to ensure order
    local ipairs = ipairs
    -- Add all the args/filepath to the display string
    for _, v in ipairs(target_fmt[3]) do
      output_string = output_string .. " " .. v
    end
    messenger:AddLog('fmt: Running "' .. output_string .. '"')

    -- Micro binding to Golang's exec.Command()
    JobSpawn(target_fmt[2], target_fmt[3], "fmt.onStdout", "fmt.onStderr", "fmt.onExit")
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
    list_supported()
  elseif input == "update" then
    -- Lets the user force an update to the table
    -- Mostly for if they added a conf file to the dir and didn't close Micro
    init_table()
  else
    messenger:Message("fmt: Unknown command! Run 'help fmt' for info.")
  end
end

-- User command & help file
MakeCommand("fmt", "fmt.fmt_usr_input", 0)
AddRuntimeFile("fmt", "help", "help/fmt.md")
