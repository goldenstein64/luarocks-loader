rockspec_format = "3.0"
package = "luarocks-loader"
version = "dev-1"
source = {
   url = "git+https://github.com/goldenstein64/luarocks-loader",
}
description = {
   summary = "A LuaRocks loader derived from LuaRocks source",
}

dependencies = {
   "lua >= 5.1",
}

test_dependencies = {
   "tl ~> 0.24",
   "cyan ~> 0.4",
}

test = {
   type = "busted",
}
