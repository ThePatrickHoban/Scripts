# v1.3
# Fixed code to lookup manager. No longer using split. CN can be passed to the Identity paramter.
# Adding Output parameter
function Get-UserManager {
<#
.SYNOPSIS
    Gets the manager information for a user or users.

.DESCRIPTION
    Gets the manager information for a user or users.

.PARAMETER Identity
    The Identity/username of the account(s) you are searching for.
    
.PARAMETER Path
    The full path to a text file containing a list of usernames on seperate lines.
    
.PARAMETER Output
    An optional parameter to specify a path that the results of the query should output to.
    (e.g. C:\Temp)

.EXAMPLE
    Get-UserManager -Identity patrick

    UserID       : patrick
    Name         : Patrick Hoban
    Email        : phoban@laptoplab.net
    ManagerID    : ESwarts
    ManagerName  : Ethan Swarts
    ManagerEmail : ethan@laptoplab.net

.EXAMPLE
    Get-UserManager -Path C:\temp\UserIds.txt

    UserID       : patrick
    Name         : Patrick Hoban
    Email        : phoban@laptoplab.net
    ManagerID    : ESwarts
    ManagerName  : Ethan Swarts
    ManagerEmail : ethan@laptoplab.net

    UserID       : TViolette
    Name         : Telma Violette
    Email        : TViolette@laptoplab.net
    ManagerID    : BCaston
    ManagerName  : Burton Caston
    ManagerEmail : BCaston@laptoplab.net

.EXAMPLE
    Get-UserManager -Identity AJones -Output C:\Temp

    C:\Temp\20210318105448_UsersManagers.csv

.NOTES
    Author: Patrick Hoban
    Version: 1.0.3
    -Published
    -Fixed code to lookup manager. No longer using split. CN can be passed to the Identity paramter.
    -Adding Output parameter

.LINK
   https://patrickhoban.wordpress.com
   https://github.com/PonchoHobono/Scripts/blob/master/PowerShell/ActiveDirectory/Get-UserManager.ps1
#>

    [CmdletBinding(
        DefaultParameterSetName='Identity'
    )]
    Param (
        [Parameter(
            ParameterSetName='Identity',Mandatory=$true,ValueFromPipeline=$true,Position=0)]
                [String[]]$Identity,
        [Parameter(
            ParameterSetName='File',Mandatory=$true,ValueFromPipeline=$false,Position=0)]
                [String]$Path,
        [Parameter(
            ParameterSetName='Identity',Mandatory=$false,ValueFromPipeline=$false,Position=1)]
        [Parameter(
            ParameterSetName='File',Mandatory=$false,ValueFromPipeline=$false,Position=1)]
                [String]$Output
    )

    if ($Path) {
        $Identity = Get-Content -Path $Path
    }

    $Return = @()
    foreach ($User in $Identity) {
        $Object = @()
        try {
            $UserInfo = Get-ADUser -Identity $User -Properties EmailAddress,Manager -ErrorAction Stop
        }
        catch {
            Continue
        }
        if ($UserInfo) {
            if ($UserInfo.Manager) {
                $ManagerInfo = Get-ADUser -Identity $UserInfo.Manager -Properties EmailAddress
            } else {
               # No Manager attribute set.
               $ManagerInfo = ""
            }
            $Object = [pscustomobject]@{
                UserID = $UserInfo.SamAccountName
                #Name = $UserInfo.Name
                Name = $UserInfo.GivenName + " " + $UserInfo.Surname
                Email = $UserInfo.EmailAddress
                ManagerID = $ManagerInfo.SamAccountName
                ManagerName = $ManagerInfo.GivenName + " " + $ManagerInfo.Surname
                ManagerEmail = $ManagerInfo.EmailAddress
            }
            $Return += $Object
        }
    }

    if ($Output) {
        if (Test-Path -Path $Output) {
            [string]$Date = Get-Date -Format yyyyMMddhhmmss
            $File = "$Output\$Date`_UsersManagers.csv"
            Write-Host $File
            $Return | Export-Csv -Path $File -NoTypeInformation
        } else {
            Write-Host "$Output does not exists." -ForegroundColor Red
            Return $Return
        }
    } else {
        $Return
    }
}
