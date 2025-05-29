# registers home checks (see Adm powershell module) as a schedule
# using a vbs script was necessary to work around a briefly opening and closing window
$Taskname = "Run Homedir checks"
$ScriptPath = [String]::Format("{0}\{1}", $env:USERPROFILE, "Repos\Config-Dotfiles\Windows-Basics\run-homechecks.vbs")

$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) #-RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserID "$env:USERDOMAIN\$env:USERNAME"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

Register-ScheduledTask -TaskName $Taskname -Action $action -Trigger $trigger -Principal $principal -Settings $settings
