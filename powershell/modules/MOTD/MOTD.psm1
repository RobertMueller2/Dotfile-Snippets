Import-Module Helpers

Function Show-Motd {
    param(
        [Parameter(mandatory=$true, Position=0)]
        [AllowEmptyCollection()]
        [string[]]$MOTDS
    )

    foreach ($m in $MOTDS) {
        $m = [String]::Format("{0}\MOTD.{1}.md",$env:USERPROFILE,$m)

        if (-Not [String]::IsNullOrWhiteSpace($m) -And $(Test-FileNotEmpty $m)) {
            Show-Markdown2 $m
        }
    }

}

Export-ModuleMember -Function Show-Motd
