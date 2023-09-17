# This is just a bunch of code related to determining which NIC(s) RDP is bound to.
# https://serverfault.com/questions/506081/how-to-set-the-network-interface-for-rdp-in-windows-server-2012

$Results = Invoke-Command -ComputerName SERVER1 -ScriptBlock {
    # Check network adapters with IDs
    $TerminalServicesSettings = Get-WmiObject -Class Win32_TSNetworkAdapterSetting -Namespace "root/cimv2/TerminalServices" -Filter "TerminalName='RDP-Tcp'"
    $NetworkAdapters = $TerminalServicesSettings | select -expand NetworkAdapterList
    $NetworkAdaptersIDs = $TerminalServicesSettings | select -expand DeviceIDList
    $NetIPConfiguration = Get-NetIPConfiguration
    #$NetIPConfiguration | select IPv4Address,InterfaceAlias,InterfaceDescription

    $Return = @()
    foreach ($NetworkAdaptersID in $NetworkAdaptersIDs) {
        if ($NetworkAdaptersID -eq $TerminalServicesSettings.NetworkAdapterLanaID) {
            $Bound = $true
        } else {
            $Bound = $false
        }
        $Object = [PSCustomObject] @{
            ID = $NetworkAdaptersID
            Bound = $Bound
            IP = ($NetIPConfiguration | where {$_.InterfaceDescription -eq $NetworkAdapters[$NetworkAdaptersID]}).IPv4Address.IPAddress
            Alias = ($NetIPConfiguration | where {$_.InterfaceDescription -eq $NetworkAdapters[$NetworkAdaptersID]}).InterfaceAlias
            NetworkAdapter = $NetworkAdapters[$NetworkAdaptersID]
        }
        $Return += $Object
    }
    $Return | ft
}
$Results | ft
# Check RDP network binding
#$TerminalServicesSettings = Get-WmiObject -Class Win32_TSNetworkAdapterSetting -Namespace "root/cimv2/TerminalServices" -Filter "TerminalName='RDP-Tcp'"
#$NetworkAdapters[$TerminalServicesSettings.NetworkAdapterLanaID]


Get-NetAdapter
Get-NetAdapter | select *
Get-NetAdapter | select Name,InterfaceDescription
Get-NetIPAddress
Get-NetIPAddress | select *
Get-NetIPAddress | select InterfaceAlias,InterfaceIndex,IPAddress
Get-NetIPConfiguration | select IPv4Address,InterfaceAlias,InterfaceDescription


$TerminalServicesNetworkAdapterListSetting = Get-WmiObject -Class Win32_TSNetworkAdapterListSetting -Namespace "root/cimv2/TerminalServices"
$TerminalServicesNetworkAdapterListSetting
$TerminalServicesNetworkAdapterListSetting | select Description,NetworkAdapterIP,Status


# Set
$TerminalServicesSettings.SetNetworkAdapterLanaID(2)
Restart-Service -Name TermService -Force
#$ts.SetNetworkAdapterLanaID(1)
# Get
gwmi Win32_TSNetworkAdapterSetting -filter "TerminalName='RDP-Tcp'" -namespace "root/cimv2/TerminalServices" | Select NetworkAdapterLanaID,NetworkAdapterName
