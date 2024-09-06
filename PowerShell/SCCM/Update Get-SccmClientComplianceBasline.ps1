function Get-SccmClientComplianceBasline {
<#
.SYNOPSIS
    Gets the SCCM compliance baselines on a computer.
.DESCRIPTION
    Gets the SCCM compliance baselines on a computer.
.PARAMETER ComputerName
    The Computer to connect to.
.INPUTS
    Accepts an array of computer names.
.OUTPUTS
    
.EXAMPLE
    Get-SccmClientComplianceBasline -ComputerName SERVER1
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
            $Return = @()
            $AllBaselines = Get-WmiObject -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration
            foreach ($Baseline in $AllBaselines) {
                #if (($Baseline.LastEvalTime.length -eq '0') -or ($Baseline.LastEvalTime -ne '00000000000000.000000+000') -or ($Baseline.LastEvalTime -ne $null)) {
                if (($Baseline.LastEvalTime.length -ne '0') -and ($Baseline.LastEvalTime -ne '00000000000000.000000+000') -and ($Baseline.LastEvalTime -ne $null)) {
                    $LastEvalTime = $Baseline.ConvertToDateTime($Baseline.LastEvalTime)
                } else {
                    $LastEvalTime = 'N/A'
                }
                switch ($Baseline.LastComplianceStatus) {
                    0 {$LastComplianceStatus = 'Non-Compliant'}
                    1 {$LastComplianceStatus = 'Compliant'}
                    2 {$LastComplianceStatus = 'Submitted'}
                    3 {$LastComplianceStatus = 'Unknown'}
                    4 {$LastComplianceStatus = 'Error'}
                    5 {$LastComplianceStatus = 'NotEvaluated'}
                    default {$LastComplianceStatus = 'Invalid'}
                }
                switch ($Baseline.Status) {
                    0 {$BaselineStatus = "Idle"}
                    1 {$BaselineStatus = "Evaluation Started"}
                    2 {$BaselineStatus = "Downloading Documents"}
                    3 {$BaselineStatus = "In Progress"}
                    4 {$BaselineStatus = "Failure"}
                    5 {$BaselineStatus = "Reporting"}
                    default {$BaselineStatus = 'Invalid'}
                }
                $Object = [pscustomobject]@{
                    Name = $Baseline.DisplayName
                    Revision = $Baseline.Version
                    'Last Evaluation' = $LastEvalTime
                    'Compliance State' = $LastComplianceStatus
                    'Evaluation State' = $BaselineStatus
                }
                $Return += $Object
            }
            $Return
        }
    }
    process {
        try {
            # Check to see if the local computername is in the $ComputerName array. This also in includes a wildcard check in case the local computername is an FQDN.
            if (@($ComputerName) -like "$env:COMPUTERNAME*") {
                Write-Host "Running local then remote if any"
                & $ScriptBlock
                # Remove local computer from array. If any are left, run remotly.
                $UpdatedComputerName = $ComputerName | Where-Object {$PSItem -notlike "$env:COMPUTERNAME*"}
                if ($UpdatedComputerName) {
                    Invoke-Command -ComputerName $UpdatedComputerName -ScriptBlock $ScriptBlock -ArgumentList $PSBoundParameters
                }
            } else {
                Write-Host "Running remote only"
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $PSBoundParameters
            }
        }
        catch {
            Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
    end {
    }
} # End of Get-SccmClientComplianceBasline function
