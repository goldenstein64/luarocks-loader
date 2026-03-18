ls -recurse "src/**/*.tl" `
    | ? { -not $_.Name.EndsWith(".d.tl") } `
    | % { $_.FullName } `
    | % { tl --gen-target 5.4 --gen-compat off gen $_ --output $_.Replace(".tl", ".lua") }