local DIR_SEP = package.config:sub(1, 1)

---@param args string[]
---@return string
local function cmd(args)
   return table.concat(args, " ")
end

---@type fun(location: string): (fun(): string)
local dir
if DIR_SEP == "\\" then
   ---@param name string
   ---@param value string
   ---@return string
   local function opt(name, value)
      return "/" .. name .. ":" .. value
   end

   ---@param name string
   ---@return string
   local function flag(name)
      return "/" .. name
   end

   function dir(location)
      local dir_cmd = assert(io.popen(cmd({ "dir", opt("A", "-D"), flag("B"), flag("S"), location })))
      return coroutine.wrap(function()
         for file in dir_cmd:lines() do
            coroutine.yield(file)
         end
         assert(dir_cmd:close())
      end)
   end
else
   error("linux build not set up")
end

local cyan_cmd = { "cyan", "gen" }
for file in dir("src") do
   if file:sub(-3, -1) == ".tl" and file:sub(-5, -4) ~= ".d" then
      table.insert(cyan_cmd, file)
   end
end

assert(os.execute(cmd(cyan_cmd)))
