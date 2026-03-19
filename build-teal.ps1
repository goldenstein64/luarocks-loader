ls -recurse "src/**/*.tl" `
    | ? { -not $_.Name.EndsWith(".d.tl") } `
    | % { $_.FullName } `
    | % { cyan gen $_ --output $_.Replace(".tl", ".lua") }