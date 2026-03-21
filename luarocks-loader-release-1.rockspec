rockspec_format = "3.0"
package = "luarocks-loader"
version = "release-1"
source = {
   url = "git+https://github.com/goldenstein64/luarocks-loader",
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