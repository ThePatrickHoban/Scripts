$OldDate = (Get-Date).AddYears(-13).AddHours(-6)
$ConfigFiles = Get-Children -Path "C:\Temp\20170623" -Recurse -Filter "config.txt"
$ConfigFiles | Select Name,Directory,LastWriteTime
ConfigFiles | ForEach-Object {
	$_.CreationTime = $OldDate
	$_.LastAccessTime = $OldDate
	$_.LastWriteTime = $OldDate
}
$ConfigFiles | Get-FileHash
