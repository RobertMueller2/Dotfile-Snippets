function Copy-DocumentationFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Switch]$ReleaseNotesOnly = $false
    )

    $pdfTargetPath = "C:\oneim\doc\documentation\$Version"
    $chmTargetPath = "C:\oneim\doc\help\$Version"
    $releaseNotesTargetPath = "C:\oneim\doc\Release Notes\$Version"

    $targetPaths = @($releaseNotesTargetPath)

    if (-Not $ReleaseNotesOnly) {
        $targetPaths += $pdfTargetPath
        $targetPaths += $chmTargetPath
    }

    foreach ($path in $targetPaths) {
        if (-not (Test-Path -Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }

    if (-Not $ReleaseNotesOnly) {
        Get-ChildItem -Path $SourceDirectory -Recurse -Filter "*.pdf" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $pdfTargetPath -Force
        }

        Get-ChildItem -Path $SourceDirectory -Recurse -Filter "*.chm" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $chmTargetPath -Force
        }
    }

    Get-ChildItem -Path $SourceDirectory -Recurse -Filter "*.pdf" | Where-Object {
        $_.Name -match "ReleaseNotes" -or $_.Name -match "Release Notes"
    } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $releaseNotesTargetPath -Force
    }

    Write-Host "Files have been successfully copied to their respective directories."
}

function Start-1IMFrontend {

    Param(
        [parameter(Position=0, Mandatory=$true)]
        [String]
        $Version,

        [parameter(position=1, Mandatory=$true)]
        [String]
        $Frontend,

        [parameter(position=2, Mandatory=$false)]
        [switch]$HDB,

	[parameter(position=3, Mandatory=$false)]
	[switch]$FakeNPM
    )

    switch ($Frontend) {
        "Synceditor"  {
            $Frontend = "SynchronizationEditor"
            $arguments = "-D"    
        }
        "JQI" {
            $Frontend = "JobQueueInfo"
        }
        "APIDesigner" {
            $Frontend = "ApiDesigner.Editor"
        }
        default {}        
    }

    $HDBStr = ""
    if ($HDB) {
        $HDBStr = " HDB"
    }
    $executable = [string]::Format("C:\OneIM\Frontends\fe{0}{2}\{1}.exe", $Version, $Frontend,$HDBStr)
    $executable2 = [string]::Format("C:\OneIM\Frontends\fe{0} RTM{2}\{1}.exe", $Version, $Frontend,$HDBStr)


    if (! [System.IO.File]::Exists($executable)) {
        
        if (! [System.IO.File]::Exists($executable2)) {
            throw "$executable or $executable2 not found"
        }
        $executable=$executable2
    }

    if ($FakeNPM) {
      $temppath = $env:path

      #FIXME: hardcoded path is a bit lame... also npm.cmd in here is not really covered by git.
      $env:Path = "c:\users\rdo\bin;" + $env:Path
    }

    if (!$arguments) {
        Start-Process -FilePath $executable
    } else {
        Start-Process -FilePath $executable -ArgumentList $arguments
    }

    if ($FakeNPM) {
      $env:Path = $temppath
    }
}

function Start-1IMJobservice {

    Param(
        [parameter(Position=0, Mandatory=$true)]
        [String]
        $Version,

        [parameter(position=1, Mandatory=$false)]
        [switch]$Config,

        [parameter(position=2, Mandatory=$false)]
        [switch]$HDB

    )

    if ($Config) {
        $Frontend="JobserviceConfigurator"
    } else {
        $Frontend="jobservicecmd"
    }

    $HDBStr = ""
    if ($HDB) {
        $HDBStr = "HDB"
    }
    $executable = [string]::Format("C:\OneIM\Jobservices\js{0}{2}\{1}.exe", $Version, $Frontend,$HDBStr)

    if (! [System.IO.File]::Exists($executable)) {
        
        throw "$executable or $executable2 not found"
    }

    Start-Process -FilePath $executable

}


#FIXME: skip HDB or only use HDB
Function Get-1IMModules {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [String]
        $InstallsetPath
    )

    $modulepath = [string]::Format("{0}\{1}",$InstallsetPath,"Modules")
    if (! [System.IO.Directory]::Exists($modulepath)) {
        throw "$InstallsetPath is not a valid OneIM installset path"
    }

    return Get-ChildItem -Path $modulepath -Directory | Select-Object -Property "Name" | ForEach-Object {$_.Name}
}

Function Install-1IMBinaries {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [String]
        $InstallsetPath,

        [parameter(Position=1, Mandatory=$true)]
        [String]
        $version,

        [parameter(Position=2, Mandatory=$false)]
        [String]
        $installtype="frontend",

        [parameter(Position=3, Mandatory=$false)]
        [switch]$dryrun
    )

    $targets=""
    $targetpath=""
    if ("frontend" -eq $installtype) {
        $targets = 'Client\Configuration Client\Administration Client\Monitoring Client\DevelopmentAndTesting'
        $targetpath = [string]::Format("C:\OneIM\Frontends\fe{0}",$version)
    }
    elseif ("jobservice" -eq $installtype) {
        $targets = 'Server\Jobserver\Configurationtool Server\Jobserver Server\Jobserver\ADS Server\Jobserver\LDAP Server\Jobserver\SAP Server\Jobserver\ADS\Exchange Server\Jobserver\Sharepoint Server'
        $targetpath = [string]::Format("C:\OneIM\jobservices\js{0}",$version)
    }
    else {
      Throw("Installtype must be Jobservice or Frontend")
    }

    $imcli = [String]::Format("{0}\Setup\InstallManager.Cli.exe", $InstallsetPath)
    $log = "C:\temp\InstallManager.CLI.log"
    $moduleselection = [String]::Join(" ", @(Get-1IMModules -InstallsetPath $InstallsetPath))

    $cmdinstall = [String]::Format("""{0}"" --mode install --rootpath ""{2}"" --installpath ""{3}"" --module {4} --deploymenttarget {5} --logfile {1} --filesonly",$imcli,$log, $InstallsetPath, $targetpath, $moduleselection,$targets)
    "Running $cmdinstall"

    if (! $dryrun) {
        & $env:SystemRoot\system32\cmd.exe /k "$cmdinstall"
    }
    
}


Function VersionToVersionString {
    Param(
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $version -replace '^81$', '8.1.1' `
		-replace '^82$', '8.2' `
		-replace '^90$', '9.0' `
		-replace '^91$', '9.1' `
		-replace '^92$', '9.2' `
		-replace '^93$', '9.3' `
		-replace '^100$', '10.0'
}

# Unterstützt jeweils die letzte installierte Version
Function VersionToVersionPath {
    Param(
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $version -replace '^81$', '815' `
        -replace '^82$', '821' `
        -replace '^90$', '900' `
        -replace '^91$', '913' `
        -replace '^92$', '921' `
        -replace '^93$', '930'
}


# x: 81, 82, 90, 101, etc
# DB: sql-<x> Port 14<x>
# jobservice: Port 18<x>
# web 16<x>
# app 17<x>
# api 19<x>

Function Start-DockerDatabase {

    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version,
        [parameter(Position=1, Mandatory=$true)]
        [String]
        $dbversion
    )

    docker --context linux run --rm --name sql-$version --hostname sql-$version `
        --add-host=OneIMDB-${version}:127.0.0.1 `
        -e 'ACCEPT_EULA=Y' `
        -e 'SA_PASSWORD=Pass_word1' `
        -e 'MSSQL_PID=Developer'  `
        -e 'MSSQL_AGENT_ENABLED=True' `
        -v c:/OneIM/Containers/DB-${version}/data:/var/opt/mssql/data `
        -v c:/OneIM/Containers/DB-${version}/log:/var/opt/mssql/log `
        -v c:/OneIM/Containers/DB-${version}/secrets:/var/opt/mssql/secrets `
        -v c:/OneIM/Containers/DB-${version}/backups:/var/opt/mssql/backup `
        -p 14${version}:1433 -d mcr.microsoft.com/mssql/server:${dbversion}-latest
}

Function Start-DockerAppserver {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version
    $port=80
    #meh...
    if ($version -ge 93) {
      $port=8080
    }

    docker -c linux run --rm --name appserver-${version} --hostname appserver-${version} `
        --add-host=OneIMDB-${version}:host-gateway `
        --add-host=OneIMDB:host-gateway `
        -p 17${version}:$port `
        -e "DBSYSTEM=MSSQL" `
        -e "CONNSTRING=Data Source=OneIMDB-${version},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -v c:/OneIM/Containers/appserver-${version}/secrets:/run/secrets `
        -v c:/OneIM/Containers/appserver-${version}/search:/var/search `
        -v c:/OneIM/Containers/appserver-${version}/cache:/var/www/App_Data/Cache `
        -d oneidentity/oneim-appserver:$oiversion
}

Function Start-DockerWebportal {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version
    if ($version -ge 93) {
      throw "Webdesigner portal not available in this version"
    }

    docker -c linux run --rm --name webportal-${version} --hostname webportal-${version} `
        --add-host=OneIMDB-${version}:host-gateway `
        --add-host=OneIMDB:host-gateway `
        -p 16${version}:80 `
        -p 28${version}:2881 `
        -e "DBSYSTEM=MSSQL" `
        -e "DEBUG=1" `
        -e "CONNSTRING=Data Source=OneIMDB-${version},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -e "UPDATEUSER=Module=DialogUser;User=viadmin;password=Pass_word1" `
        -e "APPSERVERCONNSTRING=URL=http://OneIMDB-${version}:17${version}/" `
        -e "TRUSTEDSOURCEKEY=D34db33F!" `
        -e "BASEURL=http://OneIMDB-${version}:16${version}/" `
        -v c:/OneIM/Containers/web-${version}/secrets:/run/secrets `
	-v c:/OneIM/Containers/web-${version}/ca-certificates:/run/ca-certificates `
        -d oneidentity/oneim-web:$oiversion
}

Function Start-DockerApiserver {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version

    $port=80
    if ($version -ge 93) {
      $port=8080
    }


    docker -c linux run --rm --name apiserver-${version} --hostname apiserver-${version} `
        --add-host=OneIMDB-${version}:host-gateway `
        --add-host=OneIMDB:host-gateway `
        -p 19${version}:$port `
        -e "DBSYSTEM=MSSQL" `
        -e "DEBUG=1" `
        -e "CONNSTRING=Data Source=OneIMDB-${version},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -e "UPDATEUSER=Module=DialogUser;User=viadmin;password=Pass_word1" `
        -e "APPSERVERCONNSTRING=URL=http://OneIMDB-${version}:17${version}/" `
        -e "TRUSTEDSOURCEKEY=D34db33F!" `
        -e "BASEURL=http://OneIMDB-${version}:19${version}/" `
        -e "APPLICATIONTOKEN=applicationtoken" `
        -v c:/OneIM/Containers/api-${version}/secrets:/run/secrets `
        -d oneidentity/oneim-api:$oiversion
}

Function Start-DockerJobservice {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version

    docker -c linux run --rm --name job-${version} --hostname job-${version} `
        --add-host=OneIMDB-${version}:host-gateway `
        --add-host=OneIMDB:host-gateway `
        -p 18${version}:1880 `
        -e "DBSYSTEM=MSSQL" `
        -e "CONNSTRING=Data Source=OneIMDB-${version},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -e "SERVERNAME=OneIMDB-${version}" `
        -e "HTTP_USER=admin" `
        -e "HTTP_PWD=Pass_word1" `
        -e "REQUESTINTERVAL=30" `
        -e "QUEUE=\OneIMDB-${version}" `
        -e "DEBUGMODE=True" `
        -e "BASEURL=http://OneIMDB-${version}:17${version}/" `
        -v c:/OneIM/Containers/job-${version}/logs:/var/log/jobservice `
        -d oneidentity/oneim-job:$oiversion
}

Function Start-DockerCleanupJobservice {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version

    docker -c linux run --rm --name jobcl-${version} --hostname jobcl-${version} `
        --add-host=OneIMDB-${version}:host-gateway `
        --add-host=OneIMDB:host-gateway `
        -p 27${version}:1880 `
        -e "DBSYSTEM=MSSQL" `
        -e "CONNSTRING=Data Source=OneIMDB-${version},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -e "SERVERNAME=OneIMDB-${version}" `
        -e "HTTP_USER=admin" `
        -e "HTTP_PWD=Pass_word1" `
        -e "REQUESTINTERVAL=30" `
        -e "QUEUE=\sql-${version}" `
        -e "DEBUGMODE=True" `
        -e "BASEURL=http://OneIMDB-${version}:27${version}/" `
        -v c:/OneIM/Containers/jobcl-${version}/logs:/var/log/jobservice `
        -d oneidentity/oneim-job:$oiversion
}


Function Start-Docker1IMDBAgent {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version

    docker -c linux run --rm --name dbagent-${version} --hostname dbagent-${version} `
        --add-host=OneIMDB-${version}:host-gateway `
        --add-host=OneIMDB:host-gateway `
        -e "DBSYSTEM=MSSQL" `
        -e "CONNSTRING=Data Source=OneIMDB-${version},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -d oneidentity/oneim-dbagent:$oiversion
}

# *shakes fist*
# as of 2024-12-17, neither --add-host nor host.docker.internal work on windows containers
Function Get-WDockerHostAddress {
    docker -c windows network inspect nat  --format "{{ (index .IPAM.Config 0).Gateway }}"
}

Function Start-WDocker1IMWebportal {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version
    $hostadx = Get-WDockerHostAddress

    docker --context windows run --rm --name wwebportal-${version} --hostname wwebportal-${version} `
        -p 26${version}:80 `
        -p 38${version}:2881 `
        -e "DBSYSTEM=MSSQL" `
        -e "DEBUG=1" `
        -e "CONNSTRING=Data Source=${hostadx},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -e "UPDATEUSER=Module=DialogUser;User=viadmin;password=Pass_word1" `
        -e "APPSERVERCONNSTRING=URL=http://${hostadx}:17${version}/" `
        -e "TRUSTEDSOURCEKEY=D34db33F!" `
        -e "BASEURL=http://OneIMDB-${version}:26${version}/" `
        -v c:/OneIM/Containers/wweb-${version}/secrets:c:/ProgramData/Docker/secrets `
	-v c:/OneIM/Containers/wweb-${version}/ca-certificates:c:/ca-certificates `
        -d oneidentity/oneim-web:$oiversion
}

Function Start-WDockerApiserver {
    Param (
        [parameter(Position=0, Mandatory=$true)]
        [Int]
        $version
    )

    $oiversion = VersionToVersionString $version
    $hostadx = Get-WDockerHostAddress

    docker --context windows run --rm --name wapiserver-${version} --hostname wapiserver-${version} `
        -p 29${version}:80 `
        -e "DBSYSTEM=MSSQL" `
        -e "DEBUG=1" `
        -e "CONNSTRING=Data Source=${hostadx},14${version};Initial Catalog=OneIM;User ID=OneIM_Admin;Password=Pass_word1"  `
        -e "UPDATEUSER=Module=DialogUser;User=viadmin;password=Pass_word1" `
        -e "APPSERVERCONNSTRING=URL=http://${hostadx}:17${version}/" `
        -e "TRUSTEDSOURCEKEY=D34db33F!" `
        -e "BASEURL=http://OneIMDB-${version}:29${version}/" `
        -v c:/OneIM/Containers/wapi-${version}/secrets:c:/ProgramData/Docker/secrets `
        -d oneidentity/oneim-api:$oiversion
}

Export-ModuleMember -Function Start-DockerDatabase
Export-ModuleMember -Function Start-DockerAppserver
Export-ModuleMember -Function Start-DockerApiserver
Export-ModuleMember -Function Start-DockerWebportal
Export-ModuleMember -Function Start-DockerJobservice
Export-ModuleMember -Function Start-DockerCleanupJobservice
Export-ModuleMember -Function Start-Docker1IMDBAgent
Export-ModuleMember -Function Get-1IMModules
Export-ModuleMember -Function Install-1IMBinaries
Export-ModuleMember -Function Start-1IMJobservice
Export-ModuleMember -Function Start-1IMFrontend
Export-ModuleMember -Function Start-WDocker1IMWebportal
Export-ModuleMember -Function Start-WDockerApiserver
Export-ModuleMember -Function Copy-DocumentationFiles
Export-ModuleMember -Function Get-WDockerHostAddress
