$dnsservers = "10.1.108.130","10.5.105.130"
$computers = Get-Content ComputerList.txt
foreach ($comp in $computers) {
	$adapters = Get-WmiObject -Query "select * from win32_networkadapterconfiguration where ipenabled='true'" -ComputerName $comp
	foreach ($adapter in $adapters) {
		$adapter.setDNSServerSearchOrder($dnsservers)
	}
}
