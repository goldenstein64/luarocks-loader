rockspec_format = "3.0"
package = "luarocks-loader"
version = "{RELEASE}-1"
source = {
   url = "https://github.com/goldenstein64/luarocks-loader/archive/refs/tags/v{RELEASE}.zip",
}
description = {
   summary = "A LuaRocks loader derived from LuaRocks source",
}

test_dependencies = {
   "tl ~> 0.24",
   "cyan ~> 0.4",
}

test = {
   type = "busted",
}
