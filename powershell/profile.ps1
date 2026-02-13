if ($IsLinux) {
    if ($env:USERPROFILE.Length -le 0) {
        $env:USERPROFILE = $profile
    }
}
$localprofilePre = [String]::Format("{0}\profile.local.pre.ps1",$env:USERPROFILE)
if ([System.IO.File]::Exists($localprofilePre)) {
    . $localprofilePre
}

if ([System.IO.Directory]::Exists($ProfileRoot)) {
    $env:path += ";$ProfileRoot"
}

if ($IsLinux) {
    # plenty of motds on Linux, shouldn't be needed here ;)
    $env:_RO_PS_NO_MOTD=1
    $env:repos="$HOME/Workdir"

    # for the prompt function
    $env:USERNAME = $env:LOGNAME
    $env:COMPUTERNAME = $(hostname)

} else {
    $env:repos="$HOME\Repos"
    $env:1imhelp="c:\OneIM\DocHTML"

    # ensure that Windows own ssh is used, the one that works with ssh-agent
    $env:GIT_SSH_COMMAND="c:\\windows\\system32\\openssh\\ssh.exe"
}

$env:dotfiles = Join-Path $env:repos "Config-Dotfiles"
$env:dotfilespwsh = Join-Path $env:dotfiles "Powershell"

$env:PSModulePath += $(if ($env:PSModulePath.Length -gt 0) {[IO.Path]::PathSeparator}) + $(Join-Path -Path $env:dotfiles -ChildPath "Powershell" -AdditionalChildPath "Modules")
$env:DOTNET_CLI_TELEMETRY_OPTOUT=1

Import-Module Helpers
Import-Module Adm
Import-Module OneIM
if (!$isLinux) {
    Import-Module MOTD
    Import-Module CoreUtils
}

Set-Location ~

if (!$isLinux) {
    Function Start-VimAsView { & ${env:ProgramFiles}\vim\vim91\vim.exe -R $args }
    Set-Alias -Name vi -Value ${env:ProgramFiles}\vim\vim91\vim.exe
    Set-Alias -Name vim -Value ${env:ProgramFiles}\vim\vim91\vim.exe
    Set-Alias -Name view -Value Start-VimAsView
    Set-Alias -Name less -Value ${env:ProgramFiles}\Git\usr\bin\less.exe

    function Start-Rainmeter {
        param(
            [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
            [string[]]$Args
        )
    
        $rainmeterPath = "${env:ProgramFiles}\Rainmeter\Rainmeter.exe"
    
        if (-not (Test-Path $rainmeterPath)) {
            Write-Error "Rainmeter.exe not found at '$rainmeterPath'"
            return
        }
    
        $cmdLine = $Args -join ' '
    
        # Optional: Basic safety check
        if ($cmdLine -match '^\s*$') {
            Write-Warning "No arguments provided. Rainmeter not launched."
            return
        }
    
        Start-Process -FilePath $rainmeterPath -ArgumentList $cmdLine
    }
    
    Set-Alias -Name rainmeter -Value Start-Rainmeter
}

$null = Register-NamedColors

$userNameColor = $global:NamedColors["Green"]
$hostNameColor = $global:NamedColors["White"]
$pathColor = $global:NamedColors["Green"]
$symbolColor = $global:NamedColors["Yellow"]
$errorColor = $global:NamedColors["BrightRed"]
$resetColor = $global:NamedColors["ResetAll"]
$timestampColor = [string]::Format($global:NamedColors["FGRGB"], 100, 100, 100)

if ($isLinux) {
    $psPrefix="[PS]"
}

function prompt {
    $_lastExitStatus = $?
    $_lastExitCode = $global:LASTEXITCODE

    $userName = $env:USERNAME
    $hostName = $env:COMPUTERNAME
    $path = Get-FormattedPath
    $gitBranch = Get-GitBranch
    $debugPrefix = Get-DebugPrefix
    $errorLevel = Format-ErrorLevel $_lastExitStatus $_lastExitCode
    $time = (Get-Date).ToString("HH:mm:ss")
    $consoleWidth = [Console]::WindowWidth

    $mainPrompt = "${psPrefix}${debugPrefix}${errorColor}${errorLevel}${resetColor}${userNameColor}${userName}${resetColor}@${hostNameColor}${hostName}${resetColor} ${pathColor}${path}${resetColor} ${gitBranch}${symbolColor}>${resetColor} "
    # Achtung, sehr fehleranfällig
    $mainPromptLength = "${psPrefix}${debugPrefix}${errorLevel}${userName}@${hostName} ${path} ${gitBranch}> ".Length

    $timePrompt = "${timestampColor}[$time]${resetColor}"
    $timePromptLength = "[00:00:00]".Length
 
    $padding = $consoleWidth - ($mainPromptLength + $timePromptLength)
    # willkürliche Länge, aber ein bisschen Platz sollte schon sein ;)
    if ($padding -gt 20) {
        # why the -1? no idea, math doesn't math
        $mainPrompt + (" " * $padding) + $timePrompt + "`e[$($padding + $timePromptLength - 1)D"
    } else {
        # Fallback: Zeitstempel wird vorm Prompt angezeigt
        (" " * ($consoleWidth - $timePromptLength)) + $timePrompt + "`n" + $mainPrompt
    }

    $global:LASTEXITCODE = $_lastExitCode
}


if (!$isLinux) {
    # Ctrl+d to exit
    Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
    #FIXME
    New-CacheDirs | Out-Null
}


$MOTDS = @("user"; $env:COMPUTERNAME)
if (-Not ([string]::IsNullOrWhiteSpace($lmotd))) {
    $MOTDS += $lmotd
}

if ($null -eq $env:_RO_PS_NO_MOTD) {
    Show-Motd $MOTDS
    Show-WatchData
}

$localprofilePost = [String]::Format("{0}\profile.local.post.ps1",$env:USERPROFILE)
if ([System.IO.File]::Exists($localprofilePost)) {
    . $localprofilePost
}
