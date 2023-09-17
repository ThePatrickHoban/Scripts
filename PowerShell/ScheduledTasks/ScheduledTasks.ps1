# Create Scheduled Task to run a PowerShell script.
$TaskName = "Testing"
$Description = "Runs a test script."
$User = "System"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "C:\Temp\Testing.ps1"
$StartTimes = "10:00AM","10:30AM"
$Triggers = ForEach ($StartTime in $StartTimes) {
    New-ScheduledTaskTrigger -Daily -At $StartTime
}
Register-ScheduledTask -TaskName $TaskName -Description $Description -User $User -Action $Action -Trigger $Triggers -Force

# Replace all triggers on an existing Scheduled Task
$TaskName = "Testing"
$StartTimes = "10:40AM","10:45AM"
$Triggers = ForEach ($StartTime in $StartTimes) {
    New-ScheduledTaskTrigger -Daily -At $StartTime
}
Set-ScheduledTask -TaskName $TaskName -Trigger $Triggers

# Add trigger(s) to a scheduled task
$TaskName = "Testing"
$StartTimes = "11:00AM","11:30AM","12:00PM","12:30PM"
$CurrentTriggers = (Get-ScheduledTask -TaskName $TaskName).Triggers
$NewTriggers = ForEach ($StartTime in $StartTimes) {
    New-ScheduledTaskTrigger -Daily -At $StartTime
}
$Triggers = $CurrentTriggers + $NewTriggers
Set-ScheduledTask -TaskName $TaskName -Trigger $Triggers
(Get-ScheduledTask -TaskName $TaskName).Triggers | select Enabled,StartBoundary

# $Triggers = {$CurrentTriggers}.Invoke() (Works with next line but one less line of code using the combine arrays method)
# $Triggers.Add($NewTriggers)
# (NO) $ScheduledTask.Triggers = New-ScheduledTaskTrigger -Daily -At $StartTimes
# (NO) $ScheduledTask.Triggers.Add() = New-ScheduledTaskTrigger -Daily -At $StartTimes
# (NO) $ScheduledTask.Triggers.Add($NewTriggers)
# (NO) Set-ScheduledTask -TaskName $TaskName -Trigger $CurrentTriggers, $NewTriggers
# (NO) Set-ScheduledTask -TaskName $TaskName -Trigger $NewTriggers

# Add a startup trigger to a scheduled task
$TaskName = "Testing"
$CurrentTriggers = (Get-ScheduledTask -TaskName $TaskName).Triggers
$NewTrigger = New-ScheduledTaskTrigger -AtStartup
$Triggers = $CurrentTriggers + $NewTrigger
Set-ScheduledTask -TaskName $TaskName -Trigger $Triggers

# Remove a trigger from a scheduled task
# https://stackoverflow.com/questions/37864480/how-can-i-remove-a-trigger-from-a-scheduled-task
$TaskName = "Testing"
$ScheduledTask = Get-ScheduledTask -TaskName $TaskName
$ScheduledTask.Triggers | select Enabled,StartBoundary
$NewTriggers = $ScheduledTask.Triggers | where {$_.StartBoundary -notlike "*10:30:00*"}
Set-ScheduledTask -TaskName $TaskName -Trigger $NewTriggers
(Get-ScheduledTask -TaskName $TaskName).Triggers | select Enabled,StartBoundary

# Remove all of a specific trigger type (Startup, Once, etc.)
# Type 1 = Once
# Type 2 = Daily
# Type 3 = Weekly
    # -DayOfWeek: Sun=1,Mon=2,Tue=4,Wed=8,Thu=16,Fri=32,Sat=64
    # -Multi-day adds the values above together. Sun,Mon=3. Thu,Fri,Sat=112
# Type 4 = Monthly
    # -DaysOfMonth: This one is tricky
    # -MonthsOfYear: Every month=4095
# Type 8 = At Startup
$TaskName = "Testing"
$TypeToDelete = "8"
$ScheduleService = New-Object -ComObject("Schedule.Service")
$ScheduleService.Connect($env:COMPUTERNAME)
$ScheduleServiceFolder = $ScheduleService.GetFolder('\')
$ScheduleServiceTask = $ScheduleServiceFolder.GetTask($TaskName)
$ScheduleServiceTaskDefinition = $ScheduleServiceTask.Definition
$TriggerCount = $ScheduleServiceTaskDefinition.Triggers.Count
For($TriggerID=$TriggerCount; $TriggerID -gt 0; $TriggerID--) {
    If ($ScheduleServiceTaskDefinition.Triggers.Item($TriggerID).Type -eq $TypeToDelete) {
        $ScheduleServiceTaskDefinition.Triggers.Remove($TriggerID)
        #Write-Host "Remove $TriggerID"
    }
    #Write-Host $TriggerID
}
# 4 = Update
$ScheduleServiceFolder.RegisterTaskDefinition($ScheduleServiceTask.Name, $ScheduleServiceTaskDefinition, 4, $null, $null, $null)
# Check Item settings
$ScheduleServiceTaskDefinition.Triggers.Item(X)

# Remove all triggers from a scheduled task
# https://stackoverflow.com/questions/37864480/how-can-i-remove-a-trigger-from-a-scheduled-task
$TaskName = "Testing"
$ScheduleService = New-Object -ComObject("Schedule.Service")
$ScheduleService.Connect($env:COMPUTERNAME)
$ScheduleServiceFolder = $ScheduleService.GetFolder('\')
$ScheduleServiceTask = $ScheduleServiceFolder.GetTask($TaskName)
$ScheduleServiceTaskDefinition = $ScheduleServiceTask.Definition
#$ScheduleServiceTaskDefinition.Triggers.Remove('1') # Delete first one
$TriggerCount = $ScheduleServiceTaskDefinition.Triggers.Count
For($TriggerID=$TriggerCount; $TriggerID -gt 0; $TriggerID--) {
    $ScheduleServiceTaskDefinition.Triggers.Remove($TriggerID)
    #Write-Host $TriggerID
}
# 4 = Update
$ScheduleServiceFolder.RegisterTaskDefinition($ScheduleServiceTask.Name, $ScheduleServiceTaskDefinition, 4, $null, $null, $null)


# Scheduled Task info?
$TaskName = "Testing"
$ScheduledTask = Get-ScheduledTask -TaskName $TaskName
$ScheduledTask.Actions
$ScheduledTask.Description
$ScheduledTask.Author
$ScheduledTask.Principal
$ScheduledTask.Settings
# "Configure for" setting
$ScheduledTask.Settings.Compatibility
# Microsoft Vista, Windows Server 2008 = "Vista"
# Windows 7, Windows Server 2008 R2 = "Win7"
# Windows Server 2016 = "Win8"
$ScheduledTask.Settings.Compatibility="Win8" # Not working???
