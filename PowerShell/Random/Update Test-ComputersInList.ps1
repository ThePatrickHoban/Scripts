function Test-ComputersInList {
<#
.SYNOPSIS
    
.DESCRIPTION
    
.PARAMETER ComputerName

.PARAMETER Chatty
    
.EXAMPLE
    
.EXAMPLE
     
.EXAMPLE
    
.NOTES
    
.LINK

#>
    
    [CmdletBinding(
        DefaultParameterSetName="Default"
    )]
    Param (
        [Parameter(ParameterSetName="Default",Mandatory=$false,ValueFromPipeline=$false,Position=0)]
            [String[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(ParameterSetName="Default",Mandatory=$false,ValueFromPipeLine=$false)]
            [switch]$Chatty
    )
    
    begin {
        $ScriptBlock =  {
            Write-Host $env:COMPUTERNAME
        } # End of Scriptblock
    }
    process {
        try {
            # Check to see if the local computername is in the $ComputerName array. This also includes a wildcard check in case the local computername is an FQDN.
            if (@($ComputerName) -like "$env:COMPUTERNAME*") {
                Write-Host "Running local then remote"
                & $ScriptBlock
                # Remove local computer from array
                $UpdatedComputerName = $ComputerName | Where-Object {$PSItem -notlike "$env:COMPUTERNAME*"}
                Invoke-Command -ComputerName $UpdatedComputerName -ScriptBlock $ScriptBlock -ArgumentList $PSBoundParameters
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
        if ($Chatty) {
            $Message = "All Done"
            Write-Host "[$env:COMPUTERNAME] $Message" -ForegroundColor Green
        }
    }
    
} # End of Test-ComputersInList function

<#
Test Code

SERVER01
SERVER02.domain.com
SERVER03

$Servers = Get-Clipboard
Test-ComputersInList -ComputerName $Servers


$Servers.Contains($env:COMPUTERNAME)


# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/determine-if-array-contains-value-using-wildcards
# is the exact phrase present in array?
$Servers -contains 'SERVER02.domain.com'
# is ANY phrase present in array that matches the wildcard expression?
(@($Servers) -like "$env:COMPUTERNAME*").Count -gt 0

# list all phrases from array that match the wildcard expressions
@($Servers) -like "$env:COMPUTERNAME*"

$ComputerName = Get-Clipboard
$UpdatedComputerName = $ComputerName | Where-Object {$PSItem -notlike "$env:COMPUTERNAME*"}

#>
