function Get-RDPCertificate {
<#
.SYNOPSIS
    Gets the Remote Desktop Protocol (RDP) certificate.

.DESCRIPTION
    Gets the certificate bound to the Remote Desktop Protocol (RDP) listener using PowerShell cmdlets.

.PARAMETER ComputerName
    Specifies the computers for which this cmdlet gets the RDP certificate information. The default is the local computer.
        
    Type the NetBIOS name, an IP address, or a fully qualified domain name (FQDN) of one or more computers.
    To specify the local computer, type the computer name, a dot (.), or localhost. You can also not use the
    parameter at all & it will run locally.

.PARAMETER Possible
    When this switch is used, the function will also check for certificates that could "possibly" be used for RDP.

.EXAMPLE
    Get-RDPCertificate

    Subject    : CN=WIN10.laptoplab.net
    Store      : LocalMachine\My
    Thumbprint : 08A6E9157A2880FBA6B0A826EA376F368125A8D3
    ValidFrom  : 3/5/2021 11:10:04 PM
    ValidTo    : 3/5/2023 11:10:04 PM
    Template   : LabRemoteDesktopAuthentication
    Status     : Current

.EXAMPLE
    Get-RDPCertificate -ComputerName SERVER2 -Possible

    Subject        : CN=SERVER2.laptoplab.net
    Store          : LocalMachine\My
    Thumbprint     : D5F9A804054F5F455D214DD87125A2600410AE65
    ValidFrom      : 3/5/2021 8:28:15 PM
    ValidTo        : 3/5/2023 8:28:15 PM
    Template       : LabRemoteDesktopAuthentication
    Status         : Current
    PSComputerName : SERVER2
    RunspaceId     : 3f12c027-4a45-4c1f-ae2b-f0d40ea0d793

    Subject        : CN=SERVER2.laptoplab.net
    Store          : LocalMachine\My
    Thumbprint     : 6D16B38ED8DEC18CB4115FFE013CBC24F43D7B72
    ValidFrom      : 3/18/2021 5:21:00 PM
    ValidTo        : 3/18/2023 5:21:00 PM
    Template       : LabRemoteDesktopAuthentication
    Status         : Possible
    PSComputerName : SERVER2
    RunspaceId     : 3f12c027-4a45-4c1f-ae2b-f0d40ea0d793

.NOTES
    Author: Patrick Hoban
    Version: 1.0.2
    -Published
    Version: 1.0.1
    -Initial release

.LINK 
   https://patrickhoban.wordpress.com
   https://github.com/ThePatrickHoban/Scripts/blob/master/PowerShell/Certificates/Get-RDPCertificate.ps1
#>

    [CmdletBinding(
        DefaultParameterSetName="Default"
    )]
    Param (
        [Parameter(ParameterSetName="Default",Mandatory=$false,ValueFromPipeline=$false,Position=0)]
            [String[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(ParameterSetName="Default",Mandatory=$false,ValueFromPipeLine=$false)]
            [switch]$Possible
    )

    begin {
        [scriptblock]$GetRDPCertificateScriptBlock = {
            # Get arguments passed to the function
            if ($args) {
                $args[0].GetEnumerator() | ForEach-Object {
                    New-Variable -Name $_.Key -Value $_.Value
                }
            }
            # Find the certificate bound to the RDP listener
            $RDPListener = Get-WmiObject -Class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
            $CertificateStores = 'Cert:\LocalMachine\My','Cert:\LocalMachine\Remote Desktop'
            $RDPCertificateObject = @()
            foreach ($CertificateStore in $CertificateStores) {
                $RDPCert = Get-ChildItem -Path $CertificateStore | where {$_.Thumbprint -eq $RDPListener.SSLCertificateSHA1Hash}
                if ($RDPCert) {
                    $Object = [PSCustomObject]@{
                        Subject = $RDPCert.Subject
                        Store = ($RDPCert.PSParentPath).Split(':')[-1]
                        Thumbprint = $RDPCert.Thumbprint
                        ValidFrom = $RDPCert.NotBefore
                        ValidTo = $RDPCert.NotAfter
                        Template = $RDPCert.Extensions.Format(1)[0].split('(')[0] -replace "template="
                        Status = "Current"
                    }
                    $RDPCertificateObject += $Object
                }
            }

            # Process the "Possible" parameter
            if ($Possible) {
                $PossibleRDCertificates = Get-ChildItem -Path Cert:\LocalMachine\My | where {$_.EnhancedKeyUsageList -like "*Remote Desktop Authentication*"}
                foreach ($PossibleRDCertificate in $PossibleRDCertificates) {
                    if ($PossibleRDCertificate.Thumbprint -eq $RDPCertificateObject[0].Thumbprint) {
                        # Skip
                    } else {
                        $Date = Get-Date
                        if ($PossibleRDCertificate.NotAfter -gt $Date) {
                            $Object = [PSCustomObject]@{
                                Subject = $PossibleRDCertificate.Subject
                                Store = ($PossibleRDCertificate.PSParentPath).Split(':')[-1]
                                Thumbprint = $PossibleRDCertificate.Thumbprint
                                ValidFrom = $PossibleRDCertificate.NotBefore
                                ValidTo = $PossibleRDCertificate.NotAfter
                                Template = $PossibleRDCertificate.Extensions.Format(1)[0].split('(')[0] -replace "template="
                                Status = "Possible"
                            }
                            $RDPCertificateObject += $Object
                        }
                    }
                } # End PossibleRDCertificates FOREACH
            } else {
                # Skip
            }

            # All done
            $RDPCertificateObject

        } # End GetRDPCertificateScriptblock
    }
    process {
        try {
            if ($ComputerName -eq $env:COMPUTERNAME) {
                & $GetRDPCertificateScriptBlock
            } else {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $GetRDPCertificateScriptBlock -ArgumentList $PSBoundParameters
            }
        }
        catch {
            Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
    end {
    }

} # End of Get-RDPCertificate function
