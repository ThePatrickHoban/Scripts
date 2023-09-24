$DateEnd = Get-Date
$DateStart = $DateEnd.AddHours(-48)
$EventID = "8003","8004"
$EventIDWIN10 = "5973"
$Computerlist=Read-Host 'Enter the computername'
$Log = "Microsoft-Windows-AppLocker/EXE and DLL"
$LogWIN10 = "Application"
ForEach ($Computer in $Computerlist)
    {
        if (Test-Connection -ComputerName $Computer -Count 1 -erroraction silentlyContinue)
            {
                Write-Host $Computer -ForegroundColor Green
                Try 
                    {
                        Get-WinEvent -ComputerName $Computer -FilterHashtable @{logname=$Log; id=$EventID; StartTime=$DateStart; EndTime=$DateEnd} -ErrorAction Stop | ft $Computer,UserId,TimeCreated,id,Message -AutoSize
                        #Get-WinEvent -ComputerName $Computer -FilterHashtable @{logname=$LogWIN10; id=$EventIDWIN10; StartTime=$DateStart; EndTime=$DateEnd} -ErrorAction Stop | ft $Computer,TimeCreated,id,Message -AutoSize
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
