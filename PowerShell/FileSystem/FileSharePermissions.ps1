# Folder
$Source = "C:\Test"
$Destination = "C:\Test2"
$ACLFile = "C:\Temp\ACLFile.xml"
Get-Acl -Path $Source | Export-Clixml -Path $ACLFile
$ACL = Import-Clixml -Path $ACLFile
$ACL| select *
New-Item -Path $Destination -ItemType Directory
Set-Acl -Path $Destination -AclObject $ACL

# Share
#Get-SmbShare
#Get-Command -Module SmbShare -Noun SmbShareAccess
$SourceShare = "Test"
$DestinationShare = "Test2"
$DestinationSharePath = "C:\Test2"
$ACLShare = "C:\Temp\ACLShare.xml"
# Create destination share
New-SmbShare -Name $DestinationShare -Path $DestinationSharePath
# Remove all share permissions
Get-SmbShareAccess -Name $DestinationShare
$ShareACLs = Get-SmbShareAccess -Name $DestinationShare
ForEach ($ShareACL in $ShareACLs) {
    Revoke-SmbShareAccess -Name $DestinationShare -AccountName $ShareACL.AccountName -Force
}
Get-SmbShareAccess -Name $DestinationShare
# Get source SMB share permissions & export to XML file
Get-SmbShareAccess -Name $SourceShare | Export-Clixml -Path $ACLShare
# Set permissions on destination share
$SMBACLs = Import-Clixml $ACLShare
ForEach ($SMBACL in $SMBACLs) {
    Grant-SmbShareAccess -Name $DestinationShare -AccountName $SMBACL.AccountName -AccessRight $SMBACL.AccessRight -Force
}
Get-SmbShareAccess -Name $DestinationShare
