Function Get-MigrationStatus {
<#
.SYNOPSIS
    Gets the status of Hyper-V Live Migration jobs.

.DESCRIPTION
    Gets the status of Hyper-V Live Migration jobs.

.PARAMETER ComputerName
    Single or array of Hyper-V hostnames.

.EXAMPLE
    Get-MigrationStatus -ComputerName Host01

.NOTES
    Author: Patrick Hoban
#>
    [CmdletBinding()]
    Param (
        [Parameter(mandatory=$true,Valuefrompipeline=$true)]
        [string[]]$ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $VMs = Get-VM
        $Return = @()
        ForEach ($VM in $VMs) {
            $Msvm_ComputerSystem = Get-CimInstance -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "ElementName='$($VM.Name)'"
            $Msvm_MigrationJobs = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_MigrationJob | where {$_.VirtualSystemName -eq $Msvm_ComputerSystem.Name}
            ForEach ($Msvm_MigrationJob in $Msvm_MigrationJobs) {
                If ($Msvm_MigrationJob) {
                    $Object = [pscustomobject]@{
                        Host = $env:COMPUTERNAME
                        VMName = $VM.Name
                        Name = $Msvm_MigrationJob.Name
                        Percent = $Msvm_MigrationJob.PercentComplete
                        JobStatus = $Msvm_MigrationJob.JobStatus
                    }
                    $Return += $Object
                }
            }
        }
        Return $Return
    }
}
