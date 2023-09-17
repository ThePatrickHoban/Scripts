# WARNING - This is not a "just run it" kind of file. Modify as needed for your situation. You really wanna know what you are doing.
# The usual disclaimer applies. USE AT YOUR OWN RISK. YOU HAVE BEEN WARNED. YOU BREAK IT, THAT'S ON YOU DUMMY.

# This script is to capture a ProcMon cature on a remote system.

function Get-ProcmonCapture {
    [CmdletBinding()]
    Param (
        # ComputerName
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Enter Computername",Position=0)]
            [String]$ComputerName = "localhost",
        # Duration
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Number of minutes to run capture",Position=1)]
            [string]$Duration
    )

    # Variables
    #$ComputerName = "Server1"
    $ProcmonSource = "C:\Temp\Procmon.exe"
    #$ProcmonConfig = "C:\Temp\ProcmonConfiguration.pmc"
    #$Duration = "2"

    # Copy Procmon to target
    Copy-Item -Path $ProcmonSource -Destination "\\$ComputerName\c$\Temp" -Force
    #Copy-Item -Path $ProcmonConfig -Destination "\\$ComputerName\c$\Temp" -Force

    # Create scheduled tasks
    [Scriptblock]$Setup = {
        Write-Host "Preparing capture..."
        # Create Scheduled Task to start Procmon immediatly
        [string]$FileName = (Get-Date -Format yyyyMMddhhmmss) + "_" + $env:COMPUTERNAME
        #$Action = New-ScheduledTaskAction -Execute "C:\Temp\Procmon.exe" -Argument "/accepteula /quiet /LoadConfig C:\Temp\ProcmonConfiguration.pmc /BackingFile C:\Temp\$FileName.pml"
        $Action = New-ScheduledTaskAction -Execute "C:\Temp\Procmon.exe" -Argument "/accepteula /quiet /BackingFile C:\Temp\$FileName.pml"
        $Trigger = Get-CimClass "MSFT_TaskRegistrationTrigger" -Namespace "Root/Microsoft/Windows/TaskScheduler"
        $Start = Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Procmon (Start)" -Description "Run Procmon" -User "System" -Force

        # Create Scheduled Task to stop Procmon
        $Action1 = New-ScheduledTaskAction -Execute "C:\Temp\Procmon.exe" -Argument "/Terminate"
        $StopTime = (Get-Date).AddMinutes($Using:Duration)
        $Trigger = New-ScheduledTaskTrigger -Once -At "$StopTime"
        $Stop = Register-ScheduledTask -Action $Action1 -Trigger $Trigger -TaskName "Procmon (Stop)" -Description "Stop running" -User "System" -Force
        Return $FileName
    }
    $Result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $Setup

    # Monitor the capture
    [scriptblock]$CaptureStatus = {
        # Check status of task
        #If ((Get-ScheduledTask -TaskName "Procmon (Start)").State -eq "Running") {
        #    Write-Host "Capture is running..."
        #}
        #$ScheduledTaskInfoStop = Get-ScheduledTaskInfo -TaskName "Procmon (Stop)"
        #[string]$StopTime = ($ScheduledTaskInfoStop.NextRunTime).ToString("M/d/yyyy h:mm:ss tt")
        #[string]$StopNextRunTime = ((Get-ScheduledTaskInfo -TaskName "Procmon (Stop)").NextRunTime).ToString("M/d/yyyy h:mm:ss tt")
        [string]$StopTrigger = ((Get-ScheduledTask -TaskName "Procmon (Stop)").Triggers[0]).StartBoundary | Get-Date -Format "M/d/yyyy h:mm:ss tt"
        $Counter = 0
        Do {
            Start-Sleep -Seconds 10
            If ($Counter -gt 0) {
                $Now = Get-Date -Format "M/d/yyyy h:mm:ss tt"
                Write-Host "Capture is running...Current time is $Now"
            } Else {
                Write-Host "Capture is running...Should finish around: $StopTrigger"
            }
            $Counter++
        } While ((Get-ScheduledTask -TaskName "Procmon (Start)").State -eq "Running")
        $Counter = 0
        Do {
            Start-Sleep -Seconds 10
            If ($Counter -gt 6) {
                Write-Host "Procmon (Stop) is running longer than expected." -ForegroundColor Red
            }
            $Counter++
        } While ((Get-ScheduledTask -TaskName "Procmon (Stop)").State -eq "Running")
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $CaptureStatus

    # Stop the scheduled task
    # Stop-ScheduledTask -TaskName "Procmon (Stop)"

    # Copy Procmon capture as needed
    Write-Host "Copying capture file to C:\Temp ..."
    $CheckLogFiles = Get-ChildItem -Path "\\Server1\c$\Temp\$Result*"
    If ($CheckLogFiles.Count -gt 1) {
        Write-Host "There are multiple log files. The first one will be copied." -ForegroundColor Green
    }
    Copy-Item -Path "\\$ComputerName\c$\Temp\$Result.pml" -Destination "C:\Temp"
    If (Test-Path -Path "C:\Temp\$Result.pml") {
        Write-Host "C:\Temp\$Result.pml is ready for analysis."
    } Else {
        Write-Host "File did not copy properly."
    }

    # Cleanup
    [Scriptblock]$Cleanup = {
        Write-Host "Cleaning up a few things..."
        # Remove Scheduled Tasks
        Unregister-ScheduledTask -TaskName "Procmon (Start)" -Confirm:$false
        Unregister-ScheduledTask -TaskName "Procmon (Stop)" -Confirm:$false
    
        # Delete Procmon
        Remove-Item -Path "C:\Temp\Procmon.exe"
        #Remove-Item -Path "C:\Temp\Config.pmc"
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $Cleanup

    # And finally
    Write-Host "IMPORTANT: Confirm copy of capture file is valid. Then manually remove it from \\$ComputerName\C$\Temp." -ForegroundColor Green
    # Remove-Item -Path "\\$ComputerName\C$\$Result"
} # End Get-ProcmonCapture function



#######
[scriptblock]$CaptureStatus = {
    # Check status of task
    Write-Host "Checking status of capture..."
    $ScheduledTaskInfo = Get-ScheduledTaskInfo -TaskName "Procmon (Stop)"
    [string]$StopTime = ($ScheduledTaskInfo.NextRunTime).ToString("M/d/yyyy h:m:s")
    $Counter = 0
    Do {
        $Counter++
        Start-Sleep -Seconds 10
        If ((Get-ScheduledTask -TaskName "Procmon (Start)").State -eq "Running") {
            If ($Counter -eq 1) {
                Write-Host "Capture is running...Should finish at: $StopTime"
            } Else {
                $Now = Get-Date -Format "M/d/yyyy h:m:ss"
                Write-Host "Capture is running...Current time is $Now ($Counter)"
            }
        } Else {
            Write-Host "Capture is not running."
        }
    } While ((Get-Date) -lt $ScheduledTaskInfo.NextRunTime)
    # Make sure both are stopped
    If ((Get-ScheduledTask -TaskName "Procmon (Start)").State -eq "Running") {
        Write-Host "Procmon (Start) is still running." -ForegroundColor Red
    }
    If ((Get-ScheduledTask -TaskName "Procmon (Stop)").State -eq "Running") {
        Write-Host "Procmon (Stop) is still running." -ForegroundColor Red
    }
}


    # Make sure both are stopped
    Write-Host "Checking a few things..."
    $StartState = (Get-ScheduledTask -TaskName "Procmon (Start)").State
    If ($StartState -eq "Ready") {
        $Now = Get-Date
        If (!((Get-ScheduledTaskInfo -TaskName "Procmon (Start)").LastRunTime -lt ($Now))) {
            Write-Host "Procmon (Start) error." -ForegroundColor Red
            Write-Host $Now
            Write-Host (Get-ScheduledTaskInfo -TaskName "Procmon (Start)").LastRunTime
        }
    } Else {
        Write-Host "Procmon (Start) is still running." -ForegroundColor Red
    }
    $StopState = (Get-ScheduledTask -TaskName "Procmon (Stop)").State
    If ($StopState -eq "Ready") {
        $Now = Get-Date
        If (!((Get-ScheduledTaskInfo -TaskName "Procmon (Stop)").LastRunTime -lt ($Now))) {
            Write-Host "Procmon (Stop) error." -ForegroundColor Red
            Write-Host "Now: $Now"
            Write-Host (Get-ScheduledTaskInfo -TaskName "Procmon (Stop)").LastRunTime
            #Exit
        }
    } Else {
        Write-Host "Procmon (Stop) is still running." -ForegroundColor Red
    }
