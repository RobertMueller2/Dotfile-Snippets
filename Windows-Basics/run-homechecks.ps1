$env:PSModulePath+=[string]::Format(";{0}\Repos\Config-Dotfiles\Powershell\Modules", $env:USERPROFILE)
Import-Module -Name Adm
#Invoke-HomeChecks -Git -Flat -WT -ToCache
Invoke-HomeChecks -Git -Flat -ToCache
