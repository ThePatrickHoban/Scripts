# https://msdn.microsoft.com/en-us/powershell/scripting/getting-started/cookbooks/working-with-printers
# https://www.linkedin.com/pulse/powershell-20-get-printer-equivalent-michael-zanatta?forceNoSplash=true

$ClientName = (Get-ChildItem -Path 'HKCU:\Volatile Environment' | ForEach-Object {Get-ItemProperty $_.pspath}).ClientName
if ($ClientName -notlike 'COMPUTER1*') {
	# Write-Host "Computer does not start with COMPUTER1. Delete the printer."
	(New-Object -ComObject WScript.Network).RemovePrinterConnection("\\PS1\PRINTER1")
    (New-Object -ComObject WScript.Network).RemovePrinterConnection("\\PS2\PRINTER1")
} else {
	# Write-Host "Computer does start with COMPUTER1. Do not delete the printer."
}
