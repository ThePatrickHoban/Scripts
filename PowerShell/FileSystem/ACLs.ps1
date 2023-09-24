# https://blue42.net/windows/changing-ntfs-security-permissions-using-powershell/
# https://www.vgemba.net/microsoft/NTFS-Permissions-PowerShell/

# Disable folder permission inheritance. Copy permissions.
    # https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setaccessruleprotection?view=dotnet-plat-ext-3.1
    # SetAccessRuleProtection($true,$true)
    # First parameter is whether inheritance is disabled ($true) or enabled ($false).
    # Second parameter is to copy ($true) or remove ($false) inherited permissions.
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$ACL.Access
$ACL.SetAccessRuleProtection($true,$true)
Set-Acl -Path $Folder -AclObject $ACL


# Disable folder permission inheritance. Remove inherited permissions. Careful with this one.
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$ACL.Access
$ACL.SetAccessRuleProtection($true,$false)
Set-Acl -Path $Folder -AclObject $ACL


# Enable folder permission inheritance.
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$ACL.Access
$ACL.SetAccessRuleProtection($false,$true)
Set-Acl -Path $Folder -AclObject $ACL


# Add a user's permission to a folder
# To see a list of all types of permissions run:
    [system.enum]::getnames([System.Security.AccessControl.FileSystemRights])
# Arguements:
    # IdentityReference, FileSystemRights, InheritanceFlags, PropagationFlags, AccessControlType
# Options for InheritanceFlags & PropagationFlags (e.g. "Applies To"):
############################################################################################
# Apply To                          # InheritanceFlags                  # PropagationFlags #
############################################################################################
# This folder only                  # 'None'                            # 'None'           #
# This folder, subfolders and files # 'ContainerInherit, ObjectInherit' # 'None'           #
# This folder and subfolders        # 'ContainerInherit'                # 'None'           #
# This folder and files             # 'ObjectInherit'                   # 'None'           #
# Subfolder and files only          # 'ContainerInherit, ObjectInherit' # 'InheritOnly'    #
# Subfolder only                    # 'ContainerInherit'                # 'InheritOnly'    #
# Files only                        # 'ObjectInherit'                   # 'InheritOnly'    #
############################################################################################
	
# Another flag that can show up for 'PropagationFlags' is 'NoPropagateInherit'. This flag is added by selecting
# "Only apply these permissions to objects and/or containers within this container". This option can be set for
# any right but the "This folder only" option. For example, here are two of them:
# Files only
# Propagation: InheritOnly, NoPropagateInherit
# -Inheritance: ObjectInherit
# -Sub folders and files only
# Propagation: InheritOnly, NoPropagateInherit
# -Inheritance: ObjectInherit, ContainerInherit
	
# If you were to apply an access control entry to C:\Something using that flag the right would apply to C:\Something\Else,
# but it would not be carried down to C:\Something\Else\Entirely.
	
###########################################################################################
# Result	                                      # isProtected # preserveInheritance #
###########################################################################################
# Enables inheritance and replaces all permissions    # false       # false               #
# Adds inherited permissions to existing permissions  # false       # true                #
# Disables inheritance, removes inherited permissions #	true        # false               #
# Disables inheritance, copies inherited permissions  # true        # true                #
###########################################################################################

# PropagationFlags
# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags?view=net-5.0
# InheritOnly	2	
# Specifies that the ACE is propagated only to child objects. This includes both container and leaf child objects.
# None	0	
# Specifies that no inheritance flags are set.
# NoPropagateInherit	1	
# Specifies that the ACE is not propagated to child objects.

# https://serverfault.com/questions/794849/system-security-accesscontrol-propagationflags-powershell-equivalent-gui-use
# https://bamcisnetworks.wordpress.com/2016/11/13/windows-acls-inheritanceflags-propogationflags

$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$IdentityReference = "LAPTOPLAB\AdminPatrick"
$FileSystemRights = "FullControl"
$InheritanceFlags = "ContainerInherit, ObjectInherit"
$PropagationFlags = "None"
$AccessControlType = "Allow"
$Permission = $IdentityReference,$FileSystemRights,$InheritanceFlags,$PropagationFlags,$AccessControlType
$AccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $Permission
$ACL.SetAccessRule($AccessRule)
Set-Acl -Path $Folder -AclObject $ACL


# Remove a user's permission to a folder
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$IdentityReference = "LAPTOPLAB\AdminPatrick"
$FileSystemRights = "FullControl"
$InheritanceFlags = "ContainerInherit, ObjectInherit"
$PropagationFlags = "None"
$AccessControlType = "Allow"
$Permission = $IdentityReference,$FileSystemRights,$InheritanceFlags,$PropagationFlags,$AccessControlType
$AccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $Permission
$ACL.RemoveAccessRule($AccessRule) | Out-Null
Set-Acl -Path $Folder -AclObject $ACL


# Remove all non-inherited permissions
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$NonInherited = $ACL.Access | where {$_.IsInherited -eq $false}
foreach ($Entry in $NonInherited) {
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Entry.IdentityReference,$Entry.FileSystemRights,$Entry.InheritanceFlags,$Entry.PropagationFlags,$Entry.AccessControlType)
    $ACL.RemoveAccessRule($AccessRule)
    Set-Acl -Path $Folder -AclObject $ACL
}


# Change folder owner
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$Owner = New-Object System.Security.Principal.Ntaccount("SYSTEM")
$ACL.SetOwner($Owner)
Set-Acl -Path $Folder -AclObject $ACL


# Scenario 1 - You want to remove all explicit & inherited permissions on a folder then set specific permissions. Do them in this order.
# Clear current explicit permissions
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$NonInherited = $ACL.Access | where {$_.IsInherited -eq $false}
foreach ($Entry in $NonInherited) {
   $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Entry.IdentityReference,$Entry.FileSystemRights,$Entry.InheritanceFlags,$Entry.PropagationFlags,$Entry.AccessControlType)
   $ACL.RemoveAccessRule($AccessRule) | Out-Null
   Set-Acl -Path $Folder -AclObject $ACL
}
# Set desired permissions. Repeat this section as needed.
$ACL = Get-Acl -Path $Folder
$IdentityReference = "LAPTOPLAB\AdminPatrick"
$FileSystemRights = "FullControl"
$InheritanceFlags = "ContainerInherit, ObjectInherit"
$PropagationFlags = "None"
$AccessControlType = "Allow"
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($IdentityReference,$FileSystemRights,$InheritanceFlags,$PropagationFlags,$AccessControlType)
$ACL.SetAccessRule($AccessRule)
Set-Acl -Path $Folder -AclObject $ACL

# Remove Inheritance, do not copy permissions.
$Folder = "C:\Test"
$ACL = Get-Acl -Path $Folder
$ACL.SetAccessRuleProtection($true,$false)
Set-Acl -Path $Folder -AclObject $ACL


# Scenario 2 - Same as before but using a file that contains the permissions.
#              You want to remove all explicit & inherited permissions on a folder then set specific permissions. Do them in this order.
# CSV Contents (minus the #)
    #IdentityReference,FileSystemRights,InheritanceFlags,PropagationFlags,AccessControlType
    #BUILTIN\SYSTEM,FullControl,"ContainerInherit, ObjectInherit",None,Allow
    #BUILTINAdministrators,FullControl,"ContainerInherit, ObjectInherit",None,Allow
    #BUILTIN\Users,Read,"ContainerInherit, ObjectInherit",None,Allow
# Clear current static permissions
    $Folder = "C:\Test\Target"
    $ACL = Get-Acl -Path $Folder
    $ACL.Access | ft
    $NonInherited = $ACL.Access | where {$_.IsInherited -eq $false}
    $NonInherited | ft
    foreach ($Entry in $NonInherited) {
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Entry.IdentityReference,$Entry.FileSystemRights,$Entry.InheritanceFlags,$Entry.PropagationFlags,$Entry.AccessControlType)
        $ACL.RemoveAccessRule($AccessRule) | Out-Null
        Set-Acl -Path $Folder -AclObject $ACL
    }
# Set desired permissions.
    $NewACLs = Import-Csv -Path C:\Temp\ACL.txt
    # or if CSV doesn't have headers.
    $NewACLs = Import-Csv -Path C:\Temp\ACL_No_Header.txt -Header IdentityReference,FileSystemRights,InheritanceFlags,PropagationFlags,AccessControlType
    $Folder = "C:\Test\Target"
    $ACL = Get-Acl -Path $Folder
    $ACL.Access | ft
    foreach ($NewACL in $NewACLs) {
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($NewACL.IdentityReference,$NewACL.FileSystemRights,$NewACL.InheritanceFlags,$NewACL.PropagationFlags,$NewACL.AccessControlType)
        $ACL.SetAccessRule($AccessRule)
        Set-Acl -Path $Folder -AclObject $ACL
    }
# Remove Inheritance, do not copy permissions.
    $Folder = "C:\Test\Target"
    $ACL = Get-Acl -Path $Folder
    $ACL.SetAccessRuleProtection($true,$false)
    Set-Acl -Path $Folder -AclObject $ACL


# Copy permissions from one folder to another
Get-Acl -Path C:\Test\Target | Set-Acl -Path C:\Test\Target2


# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-5.0
# https://www.codeproject.com/reference/871338/accesscontrol-filesystemrights-permissions-table
# Individual FileSystemRights values
[int]([System.Security.AccessControl.FileSystemRights]::Write)
278
[int]([System.Security.AccessControl.FileSystemRights]::Read)
131209

# FileSystemRights
[System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights])
ListDirectory
ReadData
WriteData
CreateFiles
CreateDirectories
AppendData
ReadExtendedAttributes
WriteExtendedAttributes
Traverse
ExecuteFile
DeleteSubdirectoriesAndFiles
ReadAttributes
WriteAttributes
Write
Delete
ReadPermissions
Read
ReadAndExecute
Modify
ChangePermissions
TakeOwnership
Synchronize
FullControl

# All FileSystemRights Names
foreach ($i in [System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights])) {
    $i.ToString()
}
ListDirectory
ReadData
WriteData
CreateFiles
CreateDirectories
AppendData
ReadExtendedAttributes
WriteExtendedAttributes
Traverse
ExecuteFile
DeleteSubdirectoriesAndFiles
ReadAttributes
WriteAttributes
Write
Delete
ReadPermissions
Read
ReadAndExecute
Modify
ChangePermissions
TakeOwnership
Synchronize
FullControl

# All FileSystemRights Vales
foreach ($i in [System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights])) {
    ([int]([System.Security.AccessControl.FileSystemRights])::$i)
}
1
1
2
2
4
4
8
16
32
32
64
128
256
278
65536
131072
131209
131241
197055
262144
524288
1048576
2032127

# FileSystemRights Names & Their Values
foreach ($i in [System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights])) {
    Write-Host $i.ToString().PadLeft(28),([int]([System.Security.AccessControl.FileSystemRights])::$i)
}
               ListDirectory 1
                    ReadData 1
                   WriteData 2
                 CreateFiles 2
           CreateDirectories 4
                  AppendData 4
      ReadExtendedAttributes 8
     WriteExtendedAttributes 16
                    Traverse 32
                 ExecuteFile 32
DeleteSubdirectoriesAndFiles 64
              ReadAttributes 128
             WriteAttributes 256
                       Write 278
                      Delete 65536
             ReadPermissions 131072
                        Read 131209
              ReadAndExecute 131241
                      Modify 197055
           ChangePermissions 262144
               TakeOwnership 524288
                 Synchronize 1048576
                 FullControl 2032127

# FileSystemRights & Their Binary Value
foreach ($i in [System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights])) {
    Write-Host $i.ToString().PadLeft(28),([Convert]::ToString(([int]([System.Security.AccessControl.FileSystemRights])::$i),2).PadLeft(32,'0'))
}
               ListDirectory 00000000000000000000000000000001
                    ReadData 00000000000000000000000000000001
                   WriteData 00000000000000000000000000000010
                 CreateFiles 00000000000000000000000000000010
           CreateDirectories 00000000000000000000000000000100
                  AppendData 00000000000000000000000000000100
      ReadExtendedAttributes 00000000000000000000000000001000
     WriteExtendedAttributes 00000000000000000000000000010000
                    Traverse 00000000000000000000000000100000
                 ExecuteFile 00000000000000000000000000100000
DeleteSubdirectoriesAndFiles 00000000000000000000000001000000
              ReadAttributes 00000000000000000000000010000000
             WriteAttributes 00000000000000000000000100000000
                       Write 00000000000000000000000100010110
                      Delete 00000000000000010000000000000000
             ReadPermissions 00000000000000100000000000000000
                        Read 00000000000000100000000010001001
              ReadAndExecute 00000000000000100000000010101001
                      Modify 00000000000000110000000110111111
           ChangePermissions 00000000000001000000000000000000
               TakeOwnership 00000000000010000000000000000000
                 Synchronize 00000000000100000000000000000000
                 FullControl 00000000000111110000000111111111

# SDDL Code
# https://poshscripter.wordpress.com/2017/04/27/sddl-conversion-with-powershell/
$Path = 'C:\Apache24\bin'
$ACL = Get-Acl -Path $Path
$SDDL = $ACL.Sddl
$SDDL
$ACLObject = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
$ACLObject.SetSecurityDescriptorSddlForm($SDDL)
$ACLObject.Access
Set-Acl -Path $Path -AclObject $ACLObject
