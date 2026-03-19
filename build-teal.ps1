
$files = @(
    Get-ChildItem -Recurse -Path "src/**/*.tl"
        | Where-Object { -not $_.Name.EndsWith(".d.tl") }
        | ForEach-Object { $_.FullName }
)
cyan gen @files