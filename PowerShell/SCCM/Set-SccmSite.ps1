function Set-SccmSite {
<#
.SYNOPSIS
    Set the SCCM site on a computer.

.DESCRIPTION
    Set the SCCM site on a computer.

.PARAMETER Computername

.INPUTS

.OUTPUTS

.EXAMPLE
    Set-SccmSite -ComputerName server1 -Site Site1

.EXAMPLE
    Set-SccmSite -ComputerName $ArrayOfServers -Site Site2
	
.NOTES
    Create by: Patrick Hoban
#>
    [CmdletBinding(
        DefaultParameterSetName='Computername'
    )]
    Param (
	    [Parameter(ParameterSetName='Computername',Mandatory=$false,ValueFromPipeline=$true,Position=0)]
	    [String[]]$ComputerName  = $env:COMPUTERNAME,
        [Parameter(ParameterSetName='Computername',Mandatory=$true,ValueFromPipeline=$false,Position=1)]
        [ValidateSet(“Site1”,”Site2”,”Site3”)]
	    [String]$Site
    )

    process {
        try {
            $ScriptBlock = {
                if ($args) {
                    $args[0].GetEnumerator() | ForEach-Object {
        	            New-Variable -Name $_.Key -Value $_.Value
		            }
                }

                $SmsClient = New-Object –ComObject Microsoft.SMS.Client
                $CurrentSmsSite = $SmsClient.GetAssignedSite()

                if ($Site -ne $CurrentSmsSite) {
                    Write-Host "Setting SCCM site on $ComputerName to $Site."
	                $SmsClient.SetAssignedSite($Site)
                } else {
                    Write-Host "SCCM site on $ComputerName is already $Site."
                }
            } # End ScriptBlock

            if ($ComputerName -eq $env:COMPUTERNAME) {
                & $scriptBlock
            } else {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $PSBoundParameters #| select ComputerName,Site
            }
        } catch {
            Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
}
