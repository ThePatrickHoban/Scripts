Function Get-ReplicationStatus {
<#
.SYNOPSIS
    Gets the status (including percentage) of Hyper-V replication related jobs.

.DESCRIPTION
    Gets the status (including percentage) of Hyper-V replication related jobs.

.PARAMETER ComputerName
    Single or array of Hyper-V hostnames.

.EXAMPLE
    Get-ReplicationStatus -ComputerName Host01

.NOTES
    Author: Patrick Hoban
#>
    [CmdletBinding()]
    Param (
    [Parameter(mandatory=$true,Valuefrompipeline=$true)]
    [string[]]$ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $ReplicationEnabled = Get-VMReplication
        $Return = @()
        ForEach ($VM in $ReplicationEnabled) {
            $Msvm_ComputerSystem = Get-CimInstance -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "ElementName='$($VM.Name)'"
            # Get list of VM's jobs
            $Msvm_AffectedJobElements = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_AffectedJobElement | where {$_.AffectedElement.Name -eq $Msvm_ComputerSystem.Name}
            # Get each job
            ForEach ($Msvm_AffectedJobElement in $Msvm_AffectedJobElements) {
                $Msvm_ConcreteJobs = Get-CimInstance -Namespace root\virtualization\v2 -Class Msvm_ConcreteJob | where {($_.InstanceID -eq $Msvm_AffectedJobElement.AffectingElement.InstanceID) -and ($_.JobState -eq '4')}
                If ($Msvm_ConcreteJobs) {
                    $Object = [pscustomobject]@{
                        Host = $env:COMPUTERNAME
                        VMName = $VM.Name
                        Name = $Msvm_ConcreteJobs.Name
                        Percent = $Msvm_ConcreteJobs.PercentComplete
                        JobStatus = $Msvm_ConcreteJobs.JobStatus
                        Owner = $Msvm_ConcreteJobs.Owner
                        StartTime = $Msvm_ConcreteJobs.StartTime
                    }
                    $Return += $Object
                }
            }
        }
        Return $Return
    }
}
