# luarocks-loader

A package loader for Lua modules.

See [luarocks/luarocks-loader](https://github.com/luarocks/luarocks-loader) for what this is supposed to do.

This was created despite the previously mentioned project's existence because I can't build it on Windows. `luarocks-build-cyan` does not work there because `cyan.bat` is not picked up as a tool by `require("luarocks.fs").is_tool_available("cyan")`. I should probably just file this as an issue on their side instead ([and I did](https://github.com/luarocks/luarocks/issues/1869)),  but I already did all this work, so I might as well publish it.

## License

LuaRocks is free software and uses the [MIT license](http://luarocks.org/en/License), the same as Lua 5.x.
