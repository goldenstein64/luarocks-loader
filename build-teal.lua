local DIR_SEP = package.config:sub(1, 1)

---@param args string[]
---@return string
local function cmd(args)
   return table.concat(args, " ")
end

---@type fun(location: string): (fun(): string)
local get_files
local redirect_null
if DIR_SEP == "\\" then
   redirect_null = "> NUL"
   ---@param name string
   ---@param value? string
   ---@return string
   local function opt(name, value)
      if value then
         return "/" .. name .. ":" .. value
      else
         return "/" .. name
      end
   end

   function get_files(location)
      local dir_process = assert(io.popen(cmd({ "dir", opt("A", "-D"), opt("B"), opt("S"), location })))
      return coroutine.wrap(function()
         for file in dir_process:lines() do
            coroutine.yield(file)
         end
         assert(dir_process:close())
      end)
   end
else
   redirect_null = "> /dev/null"

   ---@param command string
   ---@return string
   local function quote(command)
      return '"' .. command .. '"'
   end

   function get_files(location)
      local dir_process = assert(io.popen(cmd({
         "find",
         quote("$(pwd)/" .. location),
         "-type",
         "f",
      })))
      return coroutine.wrap(function()
         local dir ---@type string
         for file in dir_process:lines() do
            coroutine.yield(file)
         end
         assert(dir_process:close())
      end)
   end
end

local cyan_cmd = { "cyan", "gen" }
for file in get_files("src") do
   if file:sub(-3, -1) == ".tl" and file:sub(-5, -4) ~= ".d" then
      table.insert(cyan_cmd, file)
   end
end

table.insert(cyan_cmd, redirect_null)
table.insert(cyan_cmd, "2" .. redirect_null)
print(cmd(cyan_cmd))
assert(os.execute(cmd(cyan_cmd)))
