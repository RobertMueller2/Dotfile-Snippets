Import-Module Helpers
New-Variable -Name DirFormat -Value "{0}\{1}" -Scope Script -Option ReadOnly

Function Invoke-HomeChecks {
    param(
        [switch]$ToCache = $false,
        [switch]$Flat = $false,
        [switch]$Git = $false,
        [switch]$WT = $false
    )

    if ($Flat) {
        Invoke-HomeFlatChecks -ToCache:$ToCache
    }

    if ($Git) {
        Invoke-HomeGitChecks -ToCache:$ToCache
    }

    if ($WT) {
        Invoke-WTDiff -ToCache:$ToCache
    }
}

Function Invoke-HomeFlatChecks {
    param(
        [switch]$ToCache = $false
    )

    $settings = Initialize-Settings
    $outputDone = $False
    $outputfile = [String]::Format($DirFormat, $env:USERPROFILE, "cache\homewatch\flat.txt")
    
    if ($ToCache) {
        Clear-Content -Path $outputfile -Force
    }

    ForEach ($d in $settings.Keys) {
        if ($settings.$d.type -ne "flat") { Continue }
        if ($ToCache) {
            #FIXME: Variable command to remove redundancy
            &{ Invoke-FlatCheck -key $d -Ignore $($settings.$d.ignore) -IgnoreIfEmpty $($settings.$d.ignore_if_empty) `
                -IgnoreIfLink $($settings.$d.ignore_if_link) -OutputDone ([ref]$outputDone) } *>> $outputfile
        }
        else {
            Invoke-FlatCheck -key $d -Ignore $($settings.$d.ignore) -IgnoreIfEmpty $($settings.$d.ignore_if_empty) `
                -IgnoreIfLink $($settings.$d.ignore_if_link) -OutputDone ([ref]$outputDone)
        }
    }

    if ($ToCache -and [String]::IsNullOrWhiteSpace([System.IO.File]::ReadAllLines($outputfile))) {
        Clear-Content -Path $outputfile -Force
    }
}

Function Invoke-FlatCheck {
    param(
        [string]$Key,
        [string[]]$Ignore,
        [string[]]$IgnoreIfEmpty,
        [string[]]$IgnoreIfLink,
        [ref]$OutputDone
    )

    $dir = [String]::Format($DirFormat, $env:USERPROFILE, $key)
    if (-not [System.IO.Directory]::Exists($dir)) {
        # FIXME: error output
        Write-Warning "Warning: $dir does not exist"
        return
    }

    $ci = $(Get-ChildItem -Path $dir -Exclude $ignore)
    $dir_output = $false
    if ($ci.Length -gt 0) {
        ForEach ($c in $ci) {
            if ($IgnoreIfLink -contains $c.Name -and [bool]($c.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                Continue
            }
            if ($IgnoreIfEmpty -contains $c.Name) {
                $hasChildItems = $null -ne (Get-ChildItem -Path $c.FullName -File -Exclude "desktop.ini" -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1)

                if (-not $hasChildItems) {
                    Continue
                }
            }
            if (-not $OutputDone.Value) {
                Write-Host "Files or dirs outside of backed up locations"
                Write-Host "--"
                $OutputDone.Value = $true
            }
            if (-not $dir_output) {
                Write-Host "### ${dir}"
                $dir_output = $true
            }
            Write-Host "- "$c.Name 
        }
    }
    if ($dir_output) {
        Write-Host ""
    }
}

Function Invoke-HomeGitChecks {
    param(
        [switch]$ToCache = $false
    )

    $settings = Initialize-Settings
    $OverallDone = $False 
    $outputfile = [String]::Format($DirFormat, $env:USERPROFILE, "cache\homewatch\git.txt")
    if ($ToCache) {
        Clear-Content -Path $outputfile -Force
    }

    ForEach ($d in $settings.Keys) {
        if ($settings.$d.type -ne "git") { Continue }
        If ($ToCache) {
            #FIXME: Variable command to remove redundancy
            &{ Invoke-GitCheck  -key $d -ignore $($settings.$d.ignore) -OverallOutputDone ([ref]$OverallDone) } *>> $outputfile
        }
        else {
            Invoke-GitCheck -key $d -ignore $($settings.$d.ignore) ([ref]$OverallDone)
        }
    }
}

Function Invoke-GitCheck {
    param(
        [string]$key,
        [string[]]$ignore,
        [ref]$OverallOutputDone
    )

    $dir = [String]::Format("{0}\{1}", $env:USERPROFILE, $key)

    $subdirs = $(Get-ChildItem -Path $dir -Directory -Exclude $ignore)

    Function Write-OverallHeader {
        Param(
            [ref]$OverallDone
        )
        if (-not $OverallDone.Value) {
            Write-Host "Git Repository Report"
            Write-Host "--"
            $OverallDone.Value = $True
        }
    }

    Function Write-GitDirHeader {
        Param(
            [ref]$DirDone,
            [string]$Dirname
        )

        if (-not $DirDone.Value) {
            Write-Host "### $dirname"
            $DirDone.Value = $True
        }
    }

    ForEach ($s in $subdirs) {
        $outputDone = $False

        if (-not [System.IO.Directory]::Exists([String]::Format("{0}\{1}", $s, ".git"))) {
            Write-OverallHeader $OverallOutputDone
            Write-GitDirHeader -DirDone ([ref]$outputDone) -Dirname $s
            Write-Host
            Write-Warning "Not a git repository"
            Write-Host
            Continue
        }

        Set-Location $s

        $uncommitted = @(git status --porcelain=v1)
        if ($uncommitted.Length -gt 0) {
            Write-OverallHeader $OverallOutputDone
            Write-GitDirHeader -DirDone ([ref]$outputDone) -Dirname $s
            Write-Host
            Write-Host "#### Uncommitted files"
            foreach ($f in $uncommitted) {
                Write-Output $f"  "
            }
            Write-Host
        }

        #FIXME: very basic check that at least an origin is present
        $originset = git branch -vv | Select-String "\[[^]]+\]"
        if ($originset.Length -eq 0) {
            Write-OverallHeader $OverallOutputDone
            Write-GitDirHeader -DirDone ([ref]$outputDone) -Dirname $s
            Write-Host
            Write-Host "#### No origin found."
            Write-Host

            # in that case, it makes no sense to stick around for unpushed commits
            Set-Location -
            Continue
        }

        $lonelycommits = @(git log --oneline --branches --not --remotes)
        if ($lonelycommits.Length -gt 0) {
            Write-OverallHeader $OverallOutputDone
            Write-GitDirHeader -DirDone ([ref]$outputDone) -Dirname $s
            Write-Host
            Write-Host "#### Commits not pushed to origin"
            foreach ($c in $lonelycommits) {
                Write-Output $c"  "
            }
            Write-Host
        }
        
        Set-Location -
    }
}

Function Initialize-Settings {
    param(
        [String]$type
    )

    $settingsfile = [String]::Format($DirFormat, $env:USERPROFILE, "homewatch.ini")
    if (-not [System.IO.File]::Exists($settingsfile)) {
        throw "$settingsfile does not exist"
    }

    $settingsfc = Get-Content $settingsfile
    $settings = @{}
    $section = "root"

    # FIXME: place ini stuff in its own function
    ForEach($line in $settingsfc) {
        $line = $line -replace '\s*;.+$', ''

        if ($line -match '^\s*$') {
            Continue
        }

        if ($line -match '^\[([ \w\\]+)\]$') {
            $section = $Matches[1]
            $settings[$section] = @{}
            $settings[$section]["ignore"] = @()
            $settings[$section]["ignore_if_empty"] = @()
            $settings[$section]["ignore_if_link"] = @()
        }
        elseif ($line -match '^(\w+)="([^"]*)"$') {
            $_k = $Matches[1]
            $_v = $Matches[2]

            switch ($_k) {
                type {
                    if (-not ("flat", "git" -contains $_v)) {
                        throw "invalid type $_v"
                    }

                    $settings[$section]["type"] = $_v
                }
                ignore {
                    $settings[$section]["ignore"] += $_v
                }
                ignore_if_empty {
                    $settings[$section]["ignore_if_empty"] += $_v
                }
               ignore_if_link {
                    $settings[$section]["ignore_if_link"] += $_v
                }
                ignore_if_link_or_empty {
                    $settings[$section]["ignore_if_empty"] += $_v
                    $settings[$section]["ignore_if_link"] += $_v
                }
                 default {
                    Write-Host "Warning: Ignoring unknown key $_k"
                }
            }

        }
        else {
            throw "malformed line $line"
        }

    }

    return $settings
}

Function New-CacheDirs {
    $target = [String]::Format($DirFormat, $env:USERPROFILE, "cache\homewatch") 
    New-Item -Path $target -ItemType Directory -Force
}

Function New-FirefoxProfileIcon {
    $ShortcutPath = "$([Environment]::GetFolderPath('Desktop'))\FirefoxProfileDialog.lnk"
    # FIXME
    $TargetPath = [String]::Format("{0}\{1}", $env:ProgramFiles, "Mozilla Firefox\firefox.exe")
    $Arguments = "-ProfileManager -no-remote"

    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)

    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Arguments = $Arguments
    $Shortcut.IconLocation = $TargetPath
    $Shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($TargetPath)
    $Shortcut.Save()
}

Function Show-WatchData {
    $hc_flat = [String]::Format("{0}\{1}",$env:USERPROFILE, "cache\homewatch\flat.txt")
    $hc_git = [String]::Format("{0}\{1}",$env:USERPROFILE, "cache\homewatch\git.txt")
    $hc_wt = [String]::Format("{0}\{1}",$env:USERPROFILE, "cache\homewatch\wt_settings.txt")
    $filesToShow = @()

    if (Test-FileNotEmpty $hc_flat) {
        $filesToShow += $hc_flat
    }

    if (Test-FileNotEmpty $hc_git) {
        $filesToShow += $hc_git
    }

    if (Test-FileNotEmpty $hc_wt) {
        $filesToShow += $hc_wt
    }

    if ($filesToShow.Length -ge 0) {
        "# Watch Data" | Show-Markdown2
        ""
    }

    foreach ($f in $filesToShow) {
        Show-Markdown2 $f
    }
}

Function Start-RcloneCopy {
    $sourceInstallers = "C:\OneIM\InstallerArchives"
    $sourceDoc = "C:\OneIM\doc"
    # FIXME: join instead
    $conf = [String]::Format("{0}\{1}", $Env:UserProfile, "Repos\Config-Dotfiles\dotconfig\rclone.nas.conf")

    Write-Host "InstallerArchives:" -ForegroundColor Cyan
    rclone copy --config $conf --ignore-existing --progress $sourceInstallers nas:Repos/OneIM/InstallerArchives
    Write-Host
    Write-Host
    Write-Host "Doc:" -ForegroundColor Cyan
    rclone copy --config $conf --ignore-existing --progress $sourceDoc nas:Repos/OneIM/Doc

    Write-Host
    Write-Host
    Write-Host "add+commit, falls nötig" -ForegroundColor Cyan
    ssh nas "cd Repos/OneIM; git annex add . ; git commit -m `"Automatic update`""

}

Export-ModuleMember -Function Invoke-HomeChecks
Export-ModuleMember -Function Invoke-HomeFlatChecks
Export-ModuleMember -Function Invoke-HomeGitChecks
Export-ModuleMember -Function New-CacheDirs
Export-ModuleMember -Function New-FirefoxProfileIcon
Export-ModuleMember -Function Show-WatchData
Export-ModuleMember -Function Start-RcloneCopy
