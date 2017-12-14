VERSION = "2.4.0"

-- Lets the user disable the onSave() formatting
if GetOption("fmt-onsave") == nil then
  AddOption("fmt-onsave", true)
end

-- The table that holds all the formatter objects for access from other functions
local formatters = {}
-- Hold the last used settings to be checked against later
local saved_setting = {["indent"] = nil, ["tabs"] = nil}

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

local function get_filetype(x)
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
    -- The full path to the file
    local readout_path

    for i = 1, #readout do
      -- Save the current file's full path
      readout_path = JoinPaths(dir, readout[i]:Name())

      -- if extension matches, return path to the config file
      if get_filetype(readout_path) == extension then
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

-- Make sure the input is a table
local function to_t(input)
  -- Check if it's a table or not
  if type(input) ~= "table" then
    -- Return it as a table if its not already one
    return {input}
  else
    return input
  end
end

-- Initializes the dictionary of languages, their formatters, and the corresponding arguments
local function init_table()
  -- Save the used settings to be checked against later in the format() function
  saved_setting["indent"] = GetOption("tabsize")
  saved_setting["tabs"] = using_tabs()

  -- Hold the results of creating our formatter objects
  -- Eventually fed into formatters
  local temp_table = {}

  -- Cuts down on cruft when inserting a new formatter
  local function insert(supported, cli, args)
    -- Convert them to a table, if they aren't already
    supported = to_t(supported)
    args = to_t(args)

    -- Save the formatter as an object in the temporary table
    temp_table[#temp_table + 1] = {
      -- Its supported filetypes, as a table
      ["supported"] = supported,
      -- The cli command used to run it in JobSpawn
      ["cli"] = cli,
      -- The arguments, if any, as a table
      ["args"] = args,
      -- Returns a true/false if the formatters supports the filetype
      ["supports_type"] = function(self, target)
        for i = 1, #self.supported do
          if self.supported[i] == target then
            return true
          end
        end
        return false
      end
    }
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
  insert("lua", "luafmt", {"-i", saved_setting["indent"], "--use-tabs", saved_setting["tabs"], "-w", "replace"})
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
  -- Not configurable by design
  insert("dart", "dartfmt", "-w")
  -- For editor integration, it recommends --silent. It also seems to default to overwrite
  insert("fortran", "fprettify", {"--indent", saved_setting["indent"], "--silent"})

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

  -- Put the table into our permanent/global table
  formatters = temp_table
end

-- Declares the options to enable/disable formatter(s)
local function create_options()
  -- only concat once per loop by using a var
  local current_option
  -- Read each formatter in the table
  for i = 1, #formatters do
    -- Go through each language of the formatter
    for inner_i = 1, #formatters[i].supported do
      -- Creates the options to set languages to individual formatters
      current_option = formatters[i].supported[inner_i] .. "-formatter"
      -- Don't create/overwrite if it already exists
      if GetOption(current_option) == nil then
        -- Disabled by default, require user to enable for safety
        -- settings.json example "css-formatter": ""
        AddOption(current_option, "")
      end
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
  local function get_pad(len, pad_char)
    -- Remove any negative sign and round up, since we don't want negatives or decimals
    len = math.floor(math.abs(len))
    -- Add vals into a table. Concat in a loop is laggy
    local padding = {}
    for i = 1, len do
      padding[i] = pad_char
    end
    return table.concat(padding)
  end

  -- Used to hold the display output
  local display_list = {}

  -- Returns the index of the language if already saved
  local function contains_lang(self, lang)
    for i = 1, #self do
      if self[i].language == lang then
        return i
      end
    end
    -- Return nil if it doesn't contain it yet
    return nil
  end

  local found_index, cur_len
  -- The length of the longest language and cli
  local max_lang_len, max_cli_len, max_validcli_len = 0, 0, 0
  -- Builds the display_list off of the things in the formatters table
  -- For efficiency, we also get max len's in this instead of running another for loop
  for i = 1, #formatters do
    -- Get the max cli len
    cur_len = formatters[i].cli:len()
    if cur_len > max_cli_len then
      max_cli_len = cur_len
    end

    for inner_i = 1, #formatters[i].supported do
      -- Get max lang len
      cur_len = formatters[i].supported[inner_i]:len()
      if cur_len > max_lang_len then
        max_lang_len = cur_len
      end

      -- Check if we already added the language to display_list
      found_index = contains_lang(display_list, formatters[i].supported[inner_i])
      if found_index ~= nil then
        -- Append the cli command into its valid formatters table
        display_list[found_index]:set_valid_cli(formatters[i].cli)
        -- Find the longest valid_cli for padding
        cur_len = display_list[found_index]:get_valid_cli():len()
      else
        -- Doesn't contain, so add it in
        display_list[#display_list + 1] = {
          -- The language type
          ["language"] = formatters[i].supported[inner_i],
          -- The option used in AddOption()
          ["option"] = formatters[i].supported[inner_i] .. "-formatter",
          -- Holds a list of valid formatters (cli cmd) for the language
          ["valid_cli"] = {formatters[i].cli},
          -- Set/append a cli command into the display_list
          ["set_valid_cli"] = function(self, new_cli)
            -- Append on the new cli cmd to the table
            self.valid_cli[#self.valid_cli + 1] = new_cli
          end,
          -- Get what the option is set to
          ["get_status"] = function(self)
            -- Get the lang-formatter, then check what it's set to
            return GetOption(self.option)
          end,
          -- Get the sorted formatters for prettyness
          ["get_valid_cli"] = function(self)
            -- Sort alphabetically
            table.sort(self.valid_cli)
            -- Return with commas and a space between each
            return table.concat(self.valid_cli, ", ")
          end
        }
        -- Find the longest valid_cli for padding
        cur_len = display_list[#display_list]:get_valid_cli():len()
      end
      -- cur_len is set to the current cli len above
      if cur_len > max_validcli_len then
        max_validcli_len = cur_len
      end
    end
  end

  -- -formatter adds 10 chars
  local max_opt_len = max_lang_len + 10

  -- Output the formatters supported to the log, seperated by newlines
  -- Minus 1 less than we normally would because of the spaces we use in "| "
  local table_top =
    "| " ..
    "Language" ..
      get_pad(max_lang_len - 8, " ") ..
        " | " ..
          "Option" ..
            get_pad(max_opt_len - 6, " ") ..
              " | " ..
                "Status" ..
                  get_pad(max_cli_len - 6, " ") ..
                    " | " .. "Valid Formatter(s)" .. get_pad(max_validcli_len - 18, " ") .. " |\n"
  -- Use dashes to make a pretty table
  -- Add 2 because of the spaces used in "| " and " |"
  local separator =
    "+" ..
    get_pad(max_lang_len + 2, "-") ..
      "+" ..
        get_pad(max_opt_len + 2, "-") ..
          "+" .. get_pad(max_cli_len + 2, "-") .. "+" .. get_pad(max_validcli_len + 2, "-") .. "+\n"

  -- Add elements to a table, instead of concatenating in a loop (for speed)
  local table_to_concat = {}

  local cur_cli_setting, cur_lang_len, cur_cli_len, cur_validcli
  for i = 1, #display_list do
    cur_lang_len = display_list[i].language:len()
    -- Returns the GetOption()
    cur_cli_setting = display_list[i]:get_status()
    -- The :len() of display_list[i]:get_status()
    cur_cli_len = cur_cli_setting:len()
    -- A sorted and concatenated string of all the valid cli commands, separated by ", "
    cur_validcli = display_list[i]:get_valid_cli()

    -- What we'll actually display into the log
    table_to_concat[i] =
      "| " ..
      display_list[i].language ..
        get_pad(max_lang_len - cur_lang_len, " ") ..
          " | " ..
            display_list[i].option ..
              get_pad(max_opt_len - display_list[i].option:len(), " ") ..
                " | " ..
                  cur_cli_setting ..
                    get_pad(max_cli_len - cur_cli_len, " ") ..
                      " | " .. cur_validcli .. get_pad(max_validcli_len - cur_validcli:len(), " ") .. " |"
  end

  -- Sort the display list stuff
  table.sort(table_to_concat)

  -- Output the list of languages/options/status/valid formatters to the log
  messenger:AddLog(
    "\n" .. separator .. table_top .. separator .. table.concat(table_to_concat, "\n") .. "\n" .. separator
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

local function find_cli_index(fmt_name)
  for i = 1, #formatters do
    if formatters[i].cli == fmt_name then
      return i
    end
  end
  return nil
end

-- Find the correct formatter, its arguments, and then run on the current file
local function format(tar_index)
  -- Prevent infinite loop of onSave()
  CurView():Save(false)

  -- Makes sure the table is using up-to-date settings in args
  if saved_setting["indent"] ~= GetOption("tabsize") or saved_setting["tabs"] ~= using_tabs() then
    messenger:AddLog("fmt: Re-initializing formatters because settings don't match")
    -- Reload the table (to get new args) if the user has changed their settings since opening Micro
    init_table()
  end

  -- Save filetype for checking
  local file_type = get_filetype(CurView())
  -- Stop running if no extension/filetype
  if file_type == nil then
    messenger:AddLog("fmt: Exiting early since the filetype couldn't be identified")
    do
      return
    end
  end

  -- tar_index is nil when run on auto-save, or when using the "fmt" command (without a specified formatter)
  if tar_index == nil then
    -- If no optional passed target index, try to get corresponding formatter for the filetype
    local lang_setting = GetOption(file_type .. "-formatter")
    -- lang_setting will be "" if nothing is set to it
    if lang_setting ~= "" then
      -- Try to find the index of the formatter set to the option
      tar_index = find_cli_index(lang_setting)
      -- nil if the thing in the setting isn't a supported formatter
      if tar_index ~= nil then
        -- Check if the formatter supports the filetype
        if not formatters[tar_index]:supports_type(file_type) then
          -- Tell the user that the formatter in their option setting doesn't support the filetype
          messenger:Error(
            'fmt: Not formatting "' ..
              CurView().Buf.Path ..
                '" because "' .. lang_setting .. '" doesn\'t support the file-type "' .. file_type .. '"'
          )
          -- Exit because the formatter in their option setting doesn't support the filetype
          do
            return
          end
        end
      else
        -- Exit because it couldn't find a formatter that matches the option setting
        do
          return
        end
      end
    else
      -- Exit because the current option setting is empty
      do
        return
      end
    end
  elseif not formatters[tar_index]:supports_type(file_type) then
    -- This only runs if the user manually ran "fmt formattername" and the specified formatter doesn't support the filetype
    messenger:Error('fmt: "' .. formatters[tar_index].cli .. '" doesn\'t support the file-type "' .. file_type .. '"')
    -- Exit because it doesn't support the filetype
    do
      return
    end
  end

  -- Get a valid table for JobSpawn's arguments
  local job_args = {}
  if next(formatters[tar_index].args) == nil then
    -- If empty args, use the path by itself
    job_args = {CurView().Buf.Path}
  else
    -- Build up the args
    for index = 1, #formatters[tar_index].args do
      -- Add in the current args
      job_args[index] = formatters[tar_index].args[index]
    end
    -- Append the path to the end
    job_args[#job_args + 1] = CurView().Buf.Path
  end
  -- Get the job_args as a string for the log
  local display_args = table.concat(job_args, " ")
  -- Log exactly what will run and on what file
  messenger:AddLog('fmt: Running "' .. formatters[tar_index].cli .. " " .. display_args .. '"')

  -- Actually run the command with Micro's binding to the Go exec.Command()
  JobSpawn(formatters[tar_index].cli, job_args, "fmt.onStdout", "fmt.onStderr", "fmt.onExit")
end

function onSave(view)
  -- Allows for enable/disable on-save formatting via the option
  if GetOption("fmt-onsave") then
    format()
  end
end

-- A meta-command that triggers appropriate functions based on input
function fmt_usr_input(input, ex_input)
  -- nil means they only typed "fmt"
  if input == nil then
    format()
  elseif input == "list" then
    list_supported()
  elseif input == "update" then
    -- Lets the user force an update to the table
    -- Mostly for if they added a conf file to the dir and didn't close Micro
    -- Also good for if the user changed Micro's settings without relaunching
    init_table()
  else
    -- Check if the passed input == an existing formatter cli command
    local index = find_cli_index(input)
    if index ~= nil then
      -- Runs the formatter manually with a specific formatter against the current file
      format(index)
    else
      messenger:Message("fmt: Unknown command! Run 'help fmt' for info.")
    end
  end
end

-- User command & help file
MakeCommand("fmt", "fmt.fmt_usr_input", 0)
AddRuntimeFile("fmt", "help", "help/fmt.md")
