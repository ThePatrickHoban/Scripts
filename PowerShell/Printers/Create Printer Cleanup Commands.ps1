Enter-PSSession -ComputerName TS1000
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\CSR|PS1' -Recurse
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\CSR|PS2' -Recurse
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\PS1' -Recurse
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\PS2' -Recurse
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers' -Recurse -Include Generic* | Remove-Item -Recurse
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\*' -Recurse
Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses\{28d78fad-5a12-11d1-ae5b-0000f803a8c2}\##?#Root#RDPBUS#0000#{28d78fad-5a12-11d1-ae5b-0000f803a8c2}' -Recurse -Include *TS* | Remove-Item -Recurse
Restart-Service spooler
Exit-PSSession
