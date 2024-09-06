# Work in progress
# https://stackoverflow.com/questions/39252620/powershell-split-specify-a-new-line
# https://www.powershelladmin.com/wiki/Powershell_split_operator

$Content = Import-Excel -Path 'C:\Temp\New Text Document.xlsx'
#$Content[0].'Plugin Output'
#$Content[0].'Plugin Output' | Select-String "Actual Value:"
#$Content[0].'Plugin Output'.ToCharArray()
#$Results = $Content[0].'Plugin Output'.Split([Environment]::NewLine)
$Results = $Content[0].'Plugin Output' -split "[\r\n]+"
foreach ($line in $Results) {
    Write-Host $line
    Write-Host "Test"
}
$Results | Select-String "Actual Value:"
$Results | Select-String "Policy Value:"
