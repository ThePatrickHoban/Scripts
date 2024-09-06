$OUs = "OU=File Servers,OU=Servers,OU=Lab,DC=laptoplab,DC=net", `
        "OU=No GPOs,DC=laptoplab,DC=net"
$Computers = ForEach ($OU in $OUs) {
    Get-ADComputer -SearchBase $OU -Filter *
}
$Results = Invoke-Command -ComputerName $Computers.Name -ScriptBlock {
    $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths"
    $Return = @()
    $Items = (Get-Item -Path $RegistryPath -ErrorAction SilentlyContinue).Property

    If ($Items) {
        ForEach ($Item in $Items) {
            $Object = [pscustomobject]@{
                "ComputerName" = $env:COMPUTERNAME
                "Name" = $Item
                "Value" = Get-ItemPropertyValue -Path $RegistryPath -Name $Item
            }
            $Return += $Object
        }
    } Else {
        $Object = [pscustomobject]@{
            "ComputerName" = $env:COMPUTERNAME
            "Name" = "Empty"
            "Value" = "N/A"
        }
        $Return += $Object
    }
    $Return
}
$Results | select ComputerName,Name,Value
