function Update-SccmClientComplianceBasline {
<#
.SYNOPSIS
    Update the SCCM compliance baselines on a computer.
.DESCRIPTION
    Updates the SCCM compliance baselines on a computer.
.PARAMETER ComputerName
    The Computer to connect to.
.INPUTS
    Accepts an array of computer names.
.OUTPUTS
    
.EXAMPLE
    Update-SccmClientComplianceBasline -ComputerName SERVER1
.NOTES
    Create by: Patrick Hoban
#>

    [CmdletBinding(
        DefaultParameterSetName="Default"
    )]
    Param (
        [Parameter(ParameterSetName="Default",Mandatory=$false,ValueFromPipeline=$false,Position=0)]
            [String[]]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        $ScriptBlock = {
            # Refresh Machine Policy Retrieval & Evaluation Cycle
            $SCCMClient = [wmiclass] "\\.\root\ccm:SMS_Client"
            $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000021}") | Out-Null
            $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000022}") | Out-Null
 
            # Refresh Software Update Deployment Evaluation Cycle
            $SCCMClient = [wmiclass] "\\.\root\ccm:SMS_Client"
            $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000108}") | Out-Null

            # Refresh Software Update Scan Cycle
            $SCCMClient = [wmiclass] "\\.\root\ccm:SMS_Client"
            $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000113}") | Out-Null
        }
    }
    process {
        try {
            # Check to see if the local computername is in the $ComputerName array. This also in includes a wildcard check in case the local computername is an FQDN.
            if (@($ComputerName) -like "$env:COMPUTERNAME*") {
                #Write-Host "Running local then remote if any"
                & $ScriptBlock
                # Remove local computer from array. If any are left, run remotly.
                $UpdatedComputerName = $ComputerName | Where-Object {$PSItem -notlike "$env:COMPUTERNAME*"}
                if ($UpdatedComputerName) {
                    Invoke-Command -ComputerName $UpdatedComputerName -ScriptBlock $ScriptBlock -ArgumentList $PSBoundParameters
                }
            } else {
                #Write-Host "Running remote only"
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $PSBoundParameters
            }
        }
        catch {
            Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
    end{
    }

} # End of function
