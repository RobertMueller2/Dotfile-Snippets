param (
    [switch]$Fallback
)

$env:PSModulepath+=";$env:USERPROFILE\Dotfile-Snippets\Powershell\modules"
Import-Module Adm -Force

if ($Fallback) {
    $staticImage = "$env:USERPROFILE\Dotfile-Snippets\20161104_142024g.png"
}

Set-NextWallpaper $staticImage
