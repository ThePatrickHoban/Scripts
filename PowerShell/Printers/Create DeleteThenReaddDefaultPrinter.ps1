# This is an old way of doing things.

$Net = New-Object -Com WScript.Network
$DefaultPrinter = Get-WMIObject -Class Win32_Printer -computer . -Filter Default=True
$DefaultPrinter
$DefaultPrinter.Delete()
$Net.AddWindowsPrinterConnection($DefaultPrinter.DeviceId)
$DefaultPrinter.SetDefaultPrinter()
