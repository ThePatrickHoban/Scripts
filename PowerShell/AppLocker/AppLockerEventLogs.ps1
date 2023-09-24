Get-Help Clear-EventLog -Examples
Clear-EventLog -ComputerName SERVER01 -LogName "Microsoft-Windows-AppLocker"
Clear-EventLog -ComputerName SERVER01 -LogName

Wevtutil.exe cl "Microsoft-Windows-AppLocker/EXE and DLL" /R:SERVER01
Wevtutil.exe /?

Get-Help Get-AppLockerFileInformation -Path C:\Tools\procexp.exe
Get-FileHash -Path C:\Tools\procexp.exe

# https://technet.microsoft.com/en-us/library/ee460961.aspx
Get-AppLockerFileInformation -EventLog -LogPath "Microsoft-Windows-AppLocker/EXE and DLL" -EventType Allowed -Statistics
