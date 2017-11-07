VERSION = "1.1.1"

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

  -- How to add another formatter:
    -- Do NOT add a formatter for an already supported filetype. There must not be dulplicate keys!
    -- No spaces anywhere, except when using multiple flags/args, and only between them.
    -- the literal filetype, returned by CurView().Buf:FileType(), goes on the left (as a string). If 2+ supported, add them as a table (see prettier below).
    -- the middle command is the literal command to run the formatter via cli.
    -- The right is the flags, if any. If none needed, pass a `nil` value. Do NOT leave it empty!
    -- PS: Alphabetical order doesn't matter here.
  insert("crystal", "crystal", "tool format")
  insert("fish", "fish_indent", "-w")
  insert("go", "gofmt", "-w")
  insert("lua", "luafmt", "-w replace") -- stdout is default, so set to replace
  insert("ruby", "rubocop", "-f quiet -o") -- Maybe switch to https://github.com/ruby-formatter/rufo ?
  insert("rust", "rustfmt", nil) -- no args, overwrite is default
  insert("shell", "shfmt", "-s -w")
  insert({"javascript", "jsx", "flow", "typescript", "css", "less", "scss", "json", "graphql"}, "prettier", "--write") -- prettier supports a lot of filetypes
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
  -- Prevent infinite loop of onSave()
  CurView():Save(false)

  local file_type = CurView().Buf:FileType()
  -- The literal filetype name (`rust`, `shell`, etc.) is the table's key
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
      
      -- Actually run the format command
      local handle = io.popen(cmd .. " " .. CurView().Buf.Path)
      local result = handle:read("*a")
      handle:close()
      -- Reload
      CurView():ReOpen()
    end
  end
end

function onSave(view)
  format()
end

-- User command & help file
MakeCommand("fmt", "fmt.list_supported", 0)
AddRuntimeFile("fmt", "help", "help/fmt.md")
