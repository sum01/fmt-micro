VERSION = "1.2.1"

-- TODO: Add a command to show the supported filetypes & their respective formatter.

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

  insert("crystal", "crystal", "tool format")
  insert("fish", "fish_indent", "-w")
  insert("go", "gofmt", "-w")
  insert("lua", "luafmt", "-w replace") -- stdout is default, so set to replace
  insert("ruby", "rubocop", "-f quiet -o") -- Maybe switch to https://github.com/ruby-formatter/rufo ?
  insert("rust", "rustfmt", nil) -- no args, overwrite is default
  insert("shell", "shfmt", "-s -w")
  insert({"javascript", "jsx", "flow", "typescript", "css", "less", "scss", "json", "graphql", "markdown"}, "prettier", "--write") -- prettier supports a lot of filetypes
end

function create_options()
-- Declares the table & options to enable/disable formatter(s)
  -- Avoids manually defining commands twice by reading the table
  for _, value in pairs(fmt_table) do
    -- Creates the options to enable/disable formatters individually
    if GetOption(value[1]) == nil then
      -- Disabled by default, require user to enable for safety
      AddOption(value[1], false)
    end
  end
end

-- Only needs to run on the open of Micro
function onViewOpen(view)
  if fmt_table == nil then
    init_table()
    create_options()
  end
end

function list_supported()
  local supported = {}
  
  -- Declares the table & options to enable/disable formatter(s)
  -- Avoids manually defining commands twice by reading the table
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

function format()
  function get_filetype(cview)
    -- What we'll return (assuming all goes well)
    local type = ""

    -- Iterates through the path, and captures any letters after a period
    -- Since it's an iter, the last pass will be the extension (if it exists)
    for gstring in string.gmatch(cview.Buf.Path, "%.(%a*)") do
      type = gstring
    end

    messenger:AddLog("fmt: Micro failed to get filetype, but I detected: ", type)
    return type
  end
  
  -- Make sure everything deals with the same view, if somehow it changed mid-function.
  local cur_view = CurView()
  -- Prevent infinite loop of onSave()
  cur_view:Save(false)

  local file_type = cur_view.Buf:FileType()

  -- Returns "Unknown" when Micro can't file the type, so we just grab the extension
  if file_type == "Unknown" then
    file_type = get_filetype(cur_view)
  end

  -- The literal filetype name (`rust`, `shell`, etc.) is the table's key
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

      messenger:AddLog("fmt: Running \"" .. cmd .. "\" on \"" .. cur_view.Buf.Path .. "\"")
      
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
  format()
end

-- User command & help file
MakeCommand("fmt", "fmt.list_supported", 0)
AddRuntimeFile("fmt", "help", "help/fmt.md")
