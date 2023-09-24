# This quick code block will search through Active Directory at the SearchBase you specify & looks for
# any groups that have the "ManagedBy" attribute set for the User/Group specified in the SearchFor vairable.

# Variables
$SearchBase = "OU=Groups,OU=Lab,DC=domain,DC=net"
$SeachFor = "*PartOfGroupName*"

# Code
$Groups = Get-ADGroup -SearchBase $SearchBase -Filter * -Properties managedBy
ForEach ($Group in $Groups) {
    If ($Group.managedBy -like $SeachFor) {
        Write-Host $Group.Name -ForegroundColor Green
    }
}


# This is an alternate way to accomplish the same thing by getting the ACL on each group.
# Depending on the size of the environment, this method can be much slower.

# Variables
$SearchBase = "OU=Groups,OU=Lab,DC=domain,DC=net"
$SeachFor = "*PartOfGroupName*"

#Code
$Groups = Get-ADGroup -SearchBase $SearchBase -Filter *
ForEach ($Group in $Groups) {
    $Results = (Get-Acl "AD:\$($Group.DistinguishedName)").Access
    ForEach ($Result in $Results) {
        If ($Result.IdentityReference -like $SeachFor) {
            Write-Host $Group.Name -ForegroundColor Green
        }
    }
}
