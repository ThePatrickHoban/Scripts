$Arguments = @(
    "/i"
    '"c:\setup.msi"'
    "/qb!"
    "/norestart"
    "/l*v"
    '"C:\Logs\ApplicationName.log"'
)
Start-Process "msiexec.exe" -ArgumentList $Arguments -Wait -NoNewWindow 


$Arguments = @(
    "/x"
    "{4AED748-B396-3E87-B885-7F20EDC6A0A8}"
    "/qb!"
    "/norestart"
    "/l*v"
    '"C:\Logs\ApplicationName.log"'
)
Start-Process "msiexec.exe" -ArgumentList $Arguments -Wait -NoNewWindow
