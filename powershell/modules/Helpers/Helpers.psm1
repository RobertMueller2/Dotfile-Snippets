function Get-GitBranch {
    if (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
        return ""
    }

    if (-Not $(git rev-parse --is-inside-work-tree 2>$null) -eq "true") {
        return ""
    }

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($branch) {
        return "($branch)"
    }
    return ""
}

function Format-ErrorLevel {
    param(
        [bool]$status,
        [int]$code
    )
    if ($status -And $code -eq 0) {
        return ""
    } else {
        return "[$code] "
    }
}

function Get-FormattedPath {
    $path = $PWD.Path -replace [regex]::Escape($env:USERPROFILE), '~'
    $parts = $path -split [regex]::Escape("\")
    if ($parts.Count -gt 1) {
        $shortenedPath = ($parts[0..($parts.Count - 2)] | ForEach-Object {
            if ($_.Length -le 2) {
                $_ + '\'
            } else {
                $_[0] + '…\'
            }
        }) -join ''
        return $shortenedPath + $parts[-1]
    }
    return $path
}

function Get-DebugPrefix {
    if ($Host.PrivateData.DebugMode) {
        return "[DBG] "
    }
    return ""
}

# TODO: does this even work?
function Set-CustomPrompt {
    function Get-GitBranch {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($branch) {
                return "[$branch]"
            }
        }
        return ""
    }

    function Get-ErrorLevel {
        if ($?) {
            return ""
        } else {
            return "[ERROR:$LastExitCode] "
        }
    }

    function Get-FormattedPath {
        $path = $PWD.Path -replace [regex]::Escape($env:USERPROFILE), '~'
        return $path
    }

    function Get-DebugPrefix {
        if ($Host.PrivateData.DebugMode) {
            return "[DBG] "
        }
        return ""
    }

    $userName = "$(whoami)"
    $path = Get-FormattedPath
    $gitBranch = Get-GitBranch
    $debugPrefix = Get-DebugPrefix
    $errorLevel = Get-ErrorLevel

    $userNameColor = "[33m"  # Yellow
    $pathColor = "[34m"      # Blue
    $symbolColor = "[32m"    # Green
    $resetColor = "[0m"

    function prompt {
        $time = (Get-Date).ToString("HH:mm:ss")
        $consoleWidth = [Console]::WindowWidth
        $mainPrompt = "${debugPrefix}${errorLevel}${userNameColor}${userName}${resetColor} ${pathColor}${path}${resetColor} ${gitBranch} ${symbolColor}>${resetColor} "
        $timePrompt = "[$time]"

        # Calculate padding for the timestamp
        $padding = $consoleWidth - ($mainPrompt.Length + $timePrompt.Length)
        if ($padding -gt 0) {
            $mainPrompt + (" " * $padding) + $timePrompt
        } else {
            # Fallback: show timestamp on right, then new line, then main prompt
            $timePrompt + "`n" + $mainPrompt
        }
    }
}

function Register-NamedColors {
    $global:NamedColors = @{
        "ResetAll"     = "`e[0m"
        "Bold"         = "`e[1m"
        "ResetBold"    = "`e[22m"
        "Underline"    = "`e[4m"
        "NoUnderline"  = "`e[24m"
        "Negative"     = "`e[7m"
        "NoNegative"   = "`e[27m"
        "Black"        = "`e[30m"
        "Red"          = "`e[31m"
        "Green"        = "`e[32m"
        "Yellow"       = "`e[33m"
        "Blue"         = "`e[34m"
        "Magenta"      = "`e[35m"
        "Cyan"         = "`e[36m"
        "White"        = "`e[37m"
        "FGDefault"    = "`e[39m"
        "BrightBlack"  = "`e[90m"
        "BrightRed"    = "`e[91m"
        "BrightGreen"  = "`e[92m"
        "BrightYellow" = "`e[93m"
        "BrightBlue"   = "`e[94m"
        "BrightMagenta"= "`e[95m"
        "BrightCyan"   = "`e[96m"
        "BrightWhite"  = "`e[97m"
        "BGBlack"      = "`e[40m"
        "BGRed"        = "`e[41m"
        "BGGreen"      = "`e[42m"
        "BGYellow"     = "`e[43m"
        "BGBlue"       = "`e[44m"
        "BGMagenta"    = "`e[45m"
        "BGCyan"       = "`e[46m"
        "BGWhite"      = "`e[47m"
        "BGDefault"    = "`e[49m"
        "BGBrightBlack" = "`e[100m"
        "BGBrightRed"  = "`e[101m"
        "BGBrightGreen" = "`e[102m"
        "BGBrightYellow" = "`e[103m"
        "BGBrightBlue" = "`e[104m"
        "BGBrightMagenta" = "`e[105m"
        "BGBrightCyan" = "`e[106m"
        "BGBrightWhite" = "`e[107m"
        "BGRGB"        = "`e[48;2;{0};{1};{2}m"
        "BGIndex"     = "`e[48;5;{0}m"
        "FGRGB"        = "`e[38;2;{0};{1};{2}m"
        "FGIndex"     = "`e[38;5;{0}m"
    }

    return $global:NamedColors
}

Function Show-Markdown2 {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Filename,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Content
    )

    if ($null -eq $Content) {
        $Content = ""
    }

    if ($Filename -And (Test-FileNotEmpty $Filename)) {
        $fc = (Get-Content $Filename) -join "`n"
        $Content += $fc
    }

    if (Get-Command mdcat -ErrorAction SilentlyContinue) {
        "$Content" | mdcat
    } elseif (Get-Command Show-Markdown -ErrorAction SilentlyContinue) {
        "$Content" | Show-Markdown
    } else {
        "$Content"
    }
}

Function Test-ReparsePoint {
    param(
        [Parameter(mandatory=$true)]
        [string]$path
    )

    $file = Get-Item $path -Force -ea SilentlyContinue
    return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

Function Test-FileNotEmpty {
    param(
        [Parameter(mandatory=$true)]
        [string]$filename
    )

    if (![System.IO.File]::Exists($filename)) {
        return $false
    }

    if (Test-ReparsePoint($filename)) {
        $filename = Get-Item $filename | Select-Object -ExpandProperty Target
        if (![System.IO.File]::Exists($filename)) {
            return $false
        }
    }

    if (!([String]::IsNullOrWhiteSpace((Get-Content $filename)))) {
        return $true
    }
    
    return $false
}

Export-ModuleMember -Function Format-*
Export-ModuleMember -Function Get-*
Export-ModuleMember -Function Register-*
Export-ModuleMember -Function Show-Markdown2
Export-ModuleMember -Function Set-CustomPrompt
Export-ModuleMember -Function Test-*
