# use hardware clock with UTC, useful for dual booting Linux and Windows
New-ItemProperty -Type DWord -Path HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation -Name RealTimeIsUniversal -value "1"
