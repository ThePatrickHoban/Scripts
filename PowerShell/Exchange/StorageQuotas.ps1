<#
.SYNOPSIS
StorageQuotas.ps1 - Exchange Database Storage Quota Report Script

.DESCRIPTION 
Generates a report of the storage quota configurations for Exchange Server mailbox databases

.OUTPUTS
Outputs to CSV files

.EXAMPLE
.\StorageQuotas.ps1
Reports storage quota configuration for all Exchange mailbox 
and public folder databases and outputs to CSV files.

.LINK
http://exchangeserverpro.com/powershell-script-audit-exchange-server-database-storage-quotas/

.NOTES
Written By: Paul Cunningham
Website:	http://exchangeserverpro.com
Twitter:	http://twitter.com/exchservpro

Change Log
V1.00, 11/03/2014 - Initial Version

#>

$mbxreport = @()
$pfreport = @()

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$mbxreportfile = "$myDir\StorageQuotas-MailboxDB.csv"
$pfreportfile = "$myDir\StorageQuotas-PublicFolderDB.csv"

$mbxquotas = @("IssueWarningQuota",
            "ProhibitSendQuota",
            "ProhibitSendReceiveQuota",
            "RecoverableItemsQuota",
            "RecoverableItemsWarningQuota"
            )

$pfquotas = @("ProhibitPostQuota",
            "IssueWarningQuota"
            )

$mbxdatabases = @(Get-MailboxDatabase | select MasterServerOrAvailabilityGroup,Name,IssueWarningQuota,ProhibitSendQuota,ProhibitSendReceiveQuota,RecoverableItemsQuota,RecoverableItemsWarningQuota)
$pfdatabases = @(Get-PublicFolderDatabase | select Server,Name,IssueWarningQuota,ProhibitPostQuota)


if ($mbxdatabases)
{
    foreach ($database in $mbxdatabases)
    {
        Write-Host "Processing $($database.Name)"
        $mbxreportObj = New-Object PSObject
	    $mbxreportObj | Add-Member NoteProperty -Name "DAG/Server" -Value $database.MasterServerOrAvailabilityGroup
	    $mbxreportObj | Add-Member NoteProperty -Name "Database" -Value $database.Name
 
        foreach ($quota in $mbxquotas)
        {
            if (($database."$quota").IsUnlimited -eq $true)
            {
                $mbxreportObj | Add-Member NoteProperty -Name "$quota (GB)" -Value "Unlimited"
            }
            else
            {
                $mbxreportObj | Add-Member NoteProperty -Name "$quota (GB)" -Value $($database."$quota").Value.ToGB()
            }
        }
    
        $mbxreport += $mbxreportObj
    }

$mbxreport | Export-CSV -NoTypeInformation -Path $mbxreportfile -Encoding UTF8
Write-Host "Mailbox database storage quota report saved as $mbxreportfile"
}



if ($pfdatabases)
{
    foreach ($database in $pfdatabases)
    {
        Write-Host "Processing $($database.Name)"
        $pfreportObj = New-Object PSObject
	    $pfreportObj | Add-Member NoteProperty -Name "Database" -Value $database.Name
 
        foreach ($quota in $pfquotas)
        {
            if (($database."$quota").IsUnlimited -eq $true)
            {
                $pfreportObj | Add-Member NoteProperty -Name "$quota (GB)" -Value "Unlimited"
            }
            else
            {
                $pfreportObj | Add-Member NoteProperty -Name "$quota (GB)" -Value $($database."$quota").Value.ToGB()
            }
        }
    
        $pfreport += $pfreportObj
    }

$pfreport | Export-CSV -NoTypeInformation -Path $pfreportfile -Encoding UTF8
Write-Host "Public folder database storage quota report saved as $pfreportfile"
}
