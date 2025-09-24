Import-Module Helpers

if (Get-Command coreutils.exe -ErrorAction SilentlyContinue) {
    $coreutils = $(Get-Command coreutils.exe).Source
    $blocklist = @{"["="ignore"; "cp"="builtin"; "dir"="builtin"; "echo"="bultin"; "sleep"="builtin"; "sort"="prefix"; "tee"="prefix"; "tr"="skip-if-path"; "link"="ignore"; }
}
  
if ($null -ne $coreutils) {
    foreach ($a in $(coreutils.exe --list)) {
        $r = $a -Replace ("-", "Dash")
        $name = [String]::Format("Invoke-CoreUtilsCommand{0}",$r)
        $alias = $a
    
        if ($blocklist.ContainsKey($a)) {
            if ($blocklist[$a] -eq "prefix") {
                $alias = [String]::Format("core-{0}",$a)
            } elseif ($blocklist[$a] -eq "skip-if-path") {
                if (Get-Command $a -ErrorAction SilentlyContinue) {
                    continue
                }
            } else { # ignore or builtin
                continue
            }
        }
    
        $functionDefinition = @"
function $name {
    & $coreutils $a @args
}
"@
  
        Invoke-Expression $functionDefinition
  
        if (Get-Alias $alias -ErrorAction SilentlyContinue) {
            Remove-Item Alias:$alias
        }
        Set-Alias -Name $alias -Value $name
    }
}
  
if (Test-Path ~\.cargo\bin\find.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name find -Value ~\.cargo\bin\find.exe
}
elseif (Get-Command gfind.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name find -Value $(Get-Command gfind.exe).Source
}
    
if (Get-Command diffutils.exe -ErrorAction SilentlyContinue) {
    $diffutils = $(Get-Command diffutils.exe).Source
    Set-Alias -Name core-diff -Value $diffutils
}

Export-ModuleMember -Function Invoke-*
Export-ModuleMember -Alias *
