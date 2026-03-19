--[[
   this uses the following command-line tools:
   - luarocks
   - lua54
   - 7z

   this also requires the `tl` rock to be installed for one of the unit tests;
   it's needed to build the .tl files anyway.
]]

local lfs = require("lfs")

assert(_VERSION == "Lua 5.4")

local function mode(name)
   return lfs.attributes(name, "mode")
end

local function ensure_dir(name)
   local cd = assert(lfs.currentdir())
   for dir in name:gmatch("(.-)%/") do
      if mode(dir) ~= "directory" then
         assert(lfs.mkdir(dir))
      end
      assert(lfs.chdir(dir))
   end
   assert(lfs.chdir(cd))
end

local function write_file(name, text)
   ensure_dir(name)
   local f = assert(io.open(name, "w"))
   assert(f:write(text))
   assert(f:close())
end

local DIR_SEP = package.config:sub(1, 1)

---@param args string[]
---@return string
local function path(args)
   return table.concat(args, DIR_SEP)
end

---@param args string[]
---@return string
local function rpath(args)
   table.insert(args, 1, ".")
   return path(args)
end

---@param args string[]
---@return string
local function rpathd(args)
   table.insert(args, 1, ".")
   table.insert(args, "")
   return path(args)
end

---@param args string[]
---@return string
local function pathd(args)
   table.insert(args, "")
   return path(args)
end

---@param args string[]
---@return string
local function cmd(args)
   return table.concat(args, " ")
end

---@param name string
---@param value string
---@return string
local function opt(name, value)
   if string.len(name) == 1 then
      return table.concat({ "-", name, " ", value })
   else
      return table.concat({ "--", name, " ", value })
   end
end

---@param name string
---@return string
local function flag(name)
   if string.len(name) == 1 then
      return "-" .. name
   else
      return "--" .. name
   end
end

---@param value string
---@return string
local function quote(value)
   return '"' .. value .. '"'
end

---@param cmds string[]
---@return string
local function cmds_to_string(cmds)
   return "(\n  " .. table.concat(cmds, "\n  ") .. "\n)"
end

---@param cmds string[]
---@param print_cmds? boolean
local function run_cmds(cmds, print_cmds)
   if print_cmds then
      print(cmds_to_string(cmds))
   else
      for i, c in ipairs(cmds) do
         cmds[i] = c .. " > NUL"
      end
   end

   local ok, err, status = os.execute(table.concat(cmds, " && "))
   if not ok then
      error(err .. " " .. tostring(status), 2)
   end
end

---@param name string
---@param version string
---@return string[]
local function add_rock_to_server_cmds(name, version)
   local zip_name = name .. "-" .. version .. ".zip"
   local rock_name = name .. "-" .. version .. ".src.rock"
   local src_name = name .. ".lua"
   local rockspec_name = name .. "-" .. version .. ".rockspec"
   return {
      cmd({ "cd", path({ "projects", name, version }) }),
      cmd({ "7z", "a", zip_name, path({ name, src_name }), path({ name, rockspec_name }) }),
      cmd({ "luarocks", "pack", path({ name, rockspec_name }) }),
      cmd({ "cd", path({ "..", "..", ".." }) }),
      cmd({ "copy", rpath({ "projects", name, version, name, rockspec_name }), rpathd({ "server" }) }),
      cmd({ "copy", rpath({ "projects", name, version, rock_name }), rpathd({ "server" }) }),
   }
end

---@param name string
---@param version? string
---@return string
local function install_rock_cmd(name, version)
   return cmd({
      "luarocks",
      "install",
      opt("only-server", rpathd({ "server" })),
      opt("tree", rpathd({ "lua_modules" })),
      flag("keep"),
      flag("force"),
      name,
      version,
   })
end

local make_manifest_cmd = cmd({ "luarocks-admin", "make-manifest", rpathd({ "server" }) })

describe("luarocks.loader", function()
   describe("#unit", function()
      it("starts", function()
         local test_script = {
            "package.path = package.path .. ';./src/?.lua'",
            "require('luarocks.loader')",
            "print(package.loaded['luarocks.loader'])",
         }

         run_cmds({
            cmd({ "lua54", opt("e", quote(table.concat(test_script, "; "))) }),
         })
      end)

      describe("which", function()
         it("finds modules using package.path", function()
            local test_script = {
               "package.path = package.path .. ';./src/?.lua'",
               "local loader = require('luarocks.loader')",
               "local x, y, z, p = loader.which('tl', 'p')",
               "assert(p == 'p')",
            }

            run_cmds({
               cmd({ "lua54", opt("e", quote(table.concat(test_script, "; "))) }),
            })
         end)
      end)
   end)

   describe("#integration", function()
      lazy_setup(function()
         assert(lfs.chdir("spec"))
      end)

      lazy_teardown(function()
         assert(lfs.chdir(".."))
      end)

      it("respects version constraints", function()
         local cd = lfs.currentdir():gsub("\\", "/")

         ensure_dir(pathd({ "server" }))

         write_file("projects/rock_b/0.1-1/rock_b/rock_b.lua", "return { version = '0.1' }")
         write_file("projects/rock_b/0.1-1/rock_b/rock_b-0.1-1.rockspec", [[
           rockspec_format = "3.0"
           package = "rock_b"
           version = "0.1-1"
           source = {
               url = "file://]] .. cd .. [[/projects/rock_b/0.1-1/rock_b-0.1-1.zip",
           }
           build = {
               type = "builtin",
               modules = {
                   ["rock_b"] = "rock_b.lua",
               },
           }
         ]])

         run_cmds(add_rock_to_server_cmds("rock_b", "0.1-1"))

         write_file("projects/rock_b/1.0-1/rock_b/rock_b.lua", "return { version = '1.0' }")
         write_file("projects/rock_b/1.0-1/rock_b/rock_b-1.0-1.rockspec", [[
           rockspec_format = "3.0"
           package = "rock_b"
           version = "1.0-1"
           source = {
               url = "file://]] .. cd .. [[/projects/rock_b/1.0-1/rock_b-1.0-1.zip"
           }
           build = {
               type = "builtin",
               modules = {
                   rock_b = "rock_b.lua"
               }
           }
         ]])

         run_cmds(add_rock_to_server_cmds("rock_b", "1.0-1"))

         write_file(
            "projects/rock_a/2.0-1/rock_a/rock_a.lua",
            "rock_b = require('rock_b'); assert(rock_b.version == '0.1')"
         )
         write_file("projects/rock_a/2.0-1/rock_a/rock_a-2.0-1.rockspec", [[
           rockspec_format = "3.0"
           package = "rock_a"
           version = "2.0-1"
           source = {
               url = "file://]] .. cd .. [[/projects/rock_a/2.0-1/rock_a-2.0-1.zip"
           }
           dependencies = {
               "rock_b < 1.0",
           }
           build = {
               type = "builtin",
               modules = {
                   rock_a = "rock_a.lua"
               }
           }
         ]])

         run_cmds(add_rock_to_server_cmds("rock_a", "2.0-1"))

         run_cmds({
            make_manifest_cmd,
            install_rock_cmd("rock_b", "0.1"),
            install_rock_cmd("rock_b", "1.0"),
            install_rock_cmd("rock_a", "2.0"),
         })

         -- `require('rock_a')` asserts that it loads the correct version of rock_b
         local test_script = {
            "package.path = package.path .. ';../src/?.lua;../lua_modules/share/lua/5.4/?.lua'",
            "local cfg = require('luarocks.core.cfg')",
            "local loader = require('luarocks.loader')",
            "cfg.init({ project_dir = '" .. cd .. "' })",
            "table.insert(cfg.rocks_trees, 1, { name = 'project', root = '" .. cd .. "/lua_modules'})",
            "require('rock_a')",
         }

         run_cmds({
            cmd({
               "lua54",
               opt("e", quote(table.concat(test_script, "; "))),
            }),
         })
      end)
   end)
end)
