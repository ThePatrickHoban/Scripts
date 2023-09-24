# Get Sub-OUs based off of array or root OUs
$OUs = "OU=Groups,OU=Lab,DC=laptoplab,DC=net",
        "OU=Users,OU=Lab,DC=laptoplab,DC=net"
$Results = ForEach ($OU in $OUs) {
    Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter *
}
$Results | Select-Object DistinguishedName, Name
