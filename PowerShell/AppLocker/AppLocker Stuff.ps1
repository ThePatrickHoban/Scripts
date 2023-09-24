# http://stackoverflow.com/questions/26680036/powershell-catch-get-winevent-no-events-were-found-get-winevent
# http://kevinmarquette.blogspot.com/2013/01/review-applocker-logs-with-powershell.html

$DateEnd = Get-Date
$DateStart = $DateEnd.AddHours(-48)
$EventID = "8003","8004"
$Computerlist=(Get-ADComputer -Filter "name -like 'TS*'").Name
$Log = "Microsoft-Windows-AppLocker/EXE and DLL"
ForEach ($Computer in $Computerlist)
    {
        if (Test-Connection -ComputerName $Computer -Count 1 -erroraction silentlyContinue)
            {
                Write-Host $Computer -ForegroundColor Green
                Try 
                    {
                        Get-WinEvent -ComputerName $Computer -FilterHashtable @{logname=$Log; id=$EventID; StartTime=$DateStart; EndTime=$DateEnd} -ErrorAction Stop | ft $Computer,UserId,TimeCreated,Message -AutoSize
                        Wevtutil.exe cl "Microsoft-Windows-AppLocker/EXE and DLL" /R:$Computer
                    }
                Catch [Exception]
                    {
                        if ($_.Exception -match "No events were found that match the specified selection criteria")
                            {
                                Write-Host "No events found for $Computer" -ForegroundColor DarkYellow;
                            }
                    }
            }
        else
            {
                Write-Host "$Computer appears to be offline" -ForegroundColor Red
            }
    }
