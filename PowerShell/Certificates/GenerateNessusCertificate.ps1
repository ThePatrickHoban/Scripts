# https://patrickhoban.wordpress.com/2019/11/29/replace-tenable-nessus-essentials-self-signed-certificate

# Borrowed lots of code from: https://github.com/J0F3/PowerShell/blob/master/Request-Certificate.ps1

# Variables to update as needed
[string]$CN = 'nessus.laptoplab.net'
[string]$TemplateName = 'LabSSLWebCertificateCustom'
[string]$Password = 'P@ssw0rd'
[string]$NessusCAPath = 'C:\ProgramData\Tenable\Nessus\nessus\CA'
$Country = ''
$State = ''
$City = ''
$Organisation = ''
$Department = ''

# Other Variables
[string[]]$SAN = "DNS=$CN"
[string]$Date = Get-Date -Format yyyyMMddhhmmss
[string]$FriendlyName = """Nessus $Date"""
[int]$keyLength = 2048
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

# Certificate Authority
$rootDSE = [System.DirectoryServices.DirectoryEntry]'LDAP://RootDSE'
$searchBase = [System.DirectoryServices.DirectoryEntry]"LDAP://$($rootDSE.configurationNamingContext)"
$CAs = [System.DirectoryServices.DirectorySearcher]::new($searchBase,'objectClass=pKIEnrollmentService').FindAll()
If ($CAs.Count -eq 1){
    $CAName = "$($CAs[0].Properties.dnshostname)\$($CAs[0].Properties.cn)"
} Else {
    $CAName = ""
}
If (!$CAName -eq "") {
    $CAName = "$CAName"
}

# Stop the Tenable service
Stop-Service -Name 'Tenable Nessus'

# INF Template
$file = @"
[NewRequest]
FriendlyName = $FriendlyName
Subject = "CN=$CN,c=$Country,s=$State,l=$City,o=$Organisation,ou=$Department"
MachineKeySet = TRUE
KeyLength = $KeyLength
KeySpec=1
Exportable = TRUE
RequestType = PKCS10
ProviderName = "Microsoft Enhanced Cryptographic Provider v1.0"
[RequestAttributes]
CertificateTemplate = "$TemplateName"
"@

# SAN Certificate
If (($SAN).count -eq 1) {
    $SAN = @($SAN -split ',')
}
$file += 
@'

[Extensions]
; If your client operating system is Windows Server 2008, Windows Server 2008 R2, Windows Vista, or Windows 7
; SANs can be included in the Extensions section by using the following text format. Note 2.5.29.17 is the OID for a SAN extension.

2.5.29.17 = "{text}"

'@
ForEach ($an in $SAN) {
    $file += "_continue_ = `"$($an)&`"`n"
}

# Create temp files
$inf = Join-Path -Path $env:TEMP -ChildPath "$CN.inf"
$req = Join-Path -Path $env:TEMP -ChildPath "$CN.req"
$cer = Join-Path -Path $env:TEMP -ChildPath "$CN.cer"

# Create new request inf file
Set-Content -Path $inf -Value $file

# Create certificate signing request (CSR)
Invoke-Expression -Command "certreq -new `"$inf`" `"$req`""

# Private Key
$CertificateRequest = Get-ChildItem -Path Cert:\LocalMachine\REQUEST | Where-Object {$_.Subject -like "CN=$CN*"} | sort NotBefore | Select-Object -Last 1
Export-PfxCertificate -Cert $CertificateRequest -Password $SecurePassword -FilePath "$env:TEMP\$CN.pfx"

# Convert PFX to PEM
# You will need OpenSSL installed. Personally I like: https://slproweb.com/products/Win32OpenSSL.html
# https://www.jonathanmedd.net/2013/07/making-native-executables-in-windows-run-quietly-in-powershell.html
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_redirection?view=powershell-5.1
Set OPENSSL_CONF=C:\Program Files\OpenSSL-Win64\bin\openssl.cfg
Set-Location -Path 'C:\Program Files\OpenSSL-Win64\bin'
Invoke-Expression -Command ".\openssl.exe pkcs12 -in $env:TEMP\$CN.pfx -nocerts -out $env:TEMP\$CN.pem -passin pass:$Password -passout pass:$Password"
Invoke-Expression -Command ".\openssl.exe rsa -in $env:TEMP\$CN.pem -out $env:TEMP\$CN.key -passin pass:$Password -passout pass:$Password" 2>&1
Set-Location -Path C:\Temp

# Submit CSR
Invoke-Expression -Command "certreq -submit -config `"$CAName`" `"$req`" `"$cer`""

# Retrieve certificate
Invoke-Expression -Command "certreq -accept `"$cer`""

# Export certificate
$IssuedCertificate = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$CN*"} | sort NotBefore | Select-Object -Last 1
Export-Certificate -Cert $IssuedCertificate -FilePath "$env:TEMP\$CN`_Issued.cer"
# Convert to Base64
certutil -encode "$env:TEMP\$CN`_Issued.cer" "$env:TEMP\$CN`_Issued_Base64.cer"

# Get CA Certificate
# https://www.powershellgallery.com/packages/CertificatePS/1.2/Content/Copy-CertificateToRemote.ps1
[int]$iteration = 1
$Chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$Chain.Build($IssuedCertificate) | Out-Null
$ChainElements = $Chain.ChainElements | Select-Object -ExpandProperty Certificate -Skip 1
ForEach ($ChainElement in $ChainElements) {
    $Iteration++
    $CertificatePath = Join-Path $env:TEMP "$("{0:00}" -f $Iteration).$($ChainElement.Thumbprint).cer"
    $ChainElement | Export-Certificate -FilePath $CertificatePath | Out-Null
    # Convert to Base64
    $Output = certutil -encode "$CertificatePath" "$env:TEMP\$("{0:00}" -f $Iteration).$($ChainElement.Thumbprint)`_Base64.cer"
}

# Update Nessus certificate files
$Date = Get-Date -Format yyyyMMddhhmmss
Rename-Item -Path $NessusCAPath\cacert.pem -NewName $NessusCAPath\cacert`_$Date.pem
Copy-Item -Path $CertificatePath.Replace('.cer','_Base64.cer') -Destination $NessusCAPath\cacert.pem
Rename-Item -Path $NessusCAPath\servercert.pem -NewName $NessusCAPath\servercert`_$Date.pem
Copy-Item -Path $env:TEMP\$CN`_Issued_Base64.cer -Destination $NessusCAPath\servercert.pem -Force
Rename-Item -Path $NessusCAPath\serverkey.pem -NewName $NessusCAPath\serverkey`_$Date.pem
Copy-Item -Path $env:TEMP\$CN`.key -Destination $NessusCAPath\serverkey.pem -Force

# Start the Tenable service
Start-Service -Name 'Tenable Nessus'

# Cleanup
$Cleanup = Get-ChildItem -Path $env:TEMP | Where-Object {$_.Name -like "$CN*"}
Remove-Item -Path $Cleanup.FullName
