# Get
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters"
$ACL = Get-Acl $RegistryKey -Audit
$ACL.GetAuditRules($true,$true, [System.Security.Principal.SecurityIdentifier])
$ACL.GetAuditRules($true,$true, [System.Security.Principal.NTAccount])

# Set audit rule
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters"
$AuditIdentityReference = "Everyone"
$AuditRegistryRights = "FullControl"
$AuditInheritanceFlags = "ContainerInherit"
$AuditPropagationFlags = "None"
$AuditFlags = "Success"
$AuditRule = New-Object System.Security.AccessControl.RegistryAuditRule ($AuditIdentityReference,$AuditRegistryRights,$AuditInheritanceFlags,$AuditPropagationFlags,$AuditFlags)
$ACL = Get-Acl $RegistryKey
$ACL.AddAuditRule($AuditRule)
$ACL | Set-Acl -Path $RegistryKey
Get-Acl $RegistryKey -Audit | Select Path -ExpandProperty Audit | fl *

# Remove (Mine)
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters"
$ACL = Get-Acl $RegistryKey -Audit
$ACLAuditRule = $ACL.GetAuditRules($true,$true, [System.Security.Principal.NTAccount])
$AuditRule = New-Object System.Security.AccessControl.RegistryAuditRule ($ACLAuditRule.IdentityReference,$ACLAuditRule.RegistryRights,$ACLAuditRule.InheritanceFlags,$ACLAuditRule.PropagationFlags,$ACLAuditRule.AuditFlags)
$ACL.RemoveAuditRule($AuditRule)
$ACL | Set-Acl -Path $RegistryKey

# Remove
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters"
$AuditIdentityReference = "Everyone"
$AuditRegistryRights = "SetValue,Delete"
$AuditInheritanceFlags = "ContainerInherit,ObjectInherit"
$AuditPropagationFlags = "None"
$AuditFlags = "success"
$AuditRule = New-Object System.Security.AccessControl.RegistryAuditRule ($AuditIdentityReference,$AuditRegistryRights,$AuditInheritanceFlags,$AuditPropagationFlags,$AuditFlags)
$ACL = Get-Acl $RegistryKey -Audit
$ACL.RemoveAuditRule($AuditRule)
$ACL | Set-Acl -Path $RegistryKey
Get-Acl $RegistryKey -Audit | Select Path -ExpandProperty Audit | fl *
