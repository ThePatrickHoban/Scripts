function Get-SccmSite {
<#
.SYNOPSIS
    Gets the SCCM site a computer belongs to.

.DESCRIPTION
    Gets the SCCM site a computer belongs to.

.PARAMETER ComputerName
    The Computer to connect to.

.INPUTS
    Accepts an array of computer names.

.OUTPUTS
    Custom object with ComputerName, Site, & Service.

.EXAMPLE
    Get-SccmSite -ComputerName server1

.EXAMPLE
    Get-SccmSite -ComputerName $ArrayOfServers

.NOTES
    Create by: Patrick Hoban
#>

    [CmdletBinding(
        DefaultParameterSetName='Computername'
    )]
    Param (
	    [Parameter(ParameterSetName='Computername',Mandatory=$false,ValueFromPipeline=$true,Position=0)]
	    [String[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        try {
            $ScriptBlock = {
                $Object = [pscustomobject]@{
                    ComputerName = $env:COMPUTERNAME
                    Site = (New-Object -ComObject Microsoft.SMS.Client).GetAssignedSite()
                    CcmExec = (Get-Service -Name CcmExec).Status.ToString()
                }
                Return $Object
            } # End ScriptBlock
			
            if ($ComputerName -eq $env:COMPUTERNAME) {
                & $ScriptBlock
            } else {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock | select ComputerName,Site,CcmExec
            }
        } catch {
            Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
}
