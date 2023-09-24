#*****************************************************************
#
#   Script Name:  dhcpBackup.ps1
#   Version:  1.0
#   Author:  Jason Carter
#   https://jasonscottcarter.wordpress.com/
#   Description:  Used to backup DHCP logs from the DHCP server
#   to another location for archiving purposes.
#
#*****************************************************************

 #Get Yestedays Date In Month, Day, Year format
$yesterday=(get-date (get-date).AddDays(-1) -uformat %m%d%Y)

 #Get the first 3 letters of the day name from yesterday
$logdate=([string]((get-date).AddDays(-1).DayofWeek)).substring(0,3)

 #Change path to DHCP log folder, copy yesterdays log file to backup location
cd C:\Windows\System32\dhcp
copy "DhcpSrvLog-$logdate.log" C:\Temp\DHCParchive

 #Rename log file with yesterdays date
cd C:\Temp\DHCParchive
rename-item "DhcpSrvLog-$logdate.log" "$yesterday.log"

 #Dump DHCP database
$today=(get-date -uformat %m%d%Y)
$dumpfile="DHCP_DUMP-$today.txt"
netsh dhcp server \\FFBDC01 dump > C:\Temp\DHCParchive\$dumpfile
