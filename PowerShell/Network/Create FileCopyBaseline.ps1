# It's always fun to look back at the ways you coded things.

####################################################################################################
# References
# http://www.jonathanmedd.net/2014/01/adding-and-removing-items-from-a-powershell-array.html,
# https://mjolinor.wordpress.com/2014/01/20/arrays-and-generic-collections-in-powershell
####################################################################################################

####################################################################################################
$ComputerList = Get-Content -Path M:\Scripts\Computers.txt
$RemotePath = "C$\Windows\Temp"
$Source = "SERVER1"
$SourcePath = "Apps\installs\PROWin32.exe"

# Convert array to System.Collection.ObjectModel.Collection
$Collection = {$ComputerList}.Invoke()
# If the Source is also in the array, remove it.
$Collection.Remove($Source)

# Is source computer offline? If so, stop.
if (Test-Connection -ComputerName $Source -Count 1 -erroraction silentlyContinue)
    {
        Write-Host $Source -ForegroundColor Green
        $Date = Get-Date
        Write-Host $Date -ForegroundColor Green
        Foreach ($Computer in $Collection)
        {
            if (Test-Connection -ComputerName $Computer -Count 1 -erroraction silentlyContinue)
                {
                    $Destination = "\\$Computer\$RemotePath"
                    # NEED TO ADD SOMETHING HERE TO SIGNAL THE COPY STARTING
                    $time=Measure-Command -Expression {Copy-Item \\$Source\$SourcePath $Destination}
                    # WRITE TO A FILE
                    write-host $Source","$Computer","$time -ForegroundColor Cyan
                }
            else
                {
                    # WRITE TO A FILES????????
                    Write-Host "$Computer appears to be offline" -ForegroundColor Red
                }
        }
        $Date = Get-Date
        Write-Host $Date -ForegroundColor Green
    }
else
    {
        Write-Host "$Source appears to be offline" -ForegroundColor Red
    }
##################################################################################################

$Source = "C:\Temp\PROWin32.exe"
$Destination = "\\COMPUTER1\c$\Windows\Temp"
$time=Measure-Command -Expression {Copy-Item $Source $Destination}
write-host $Source","$Destination","$time

************
# Point the script to the text file
$Computers = Read-Host "Enter Location Of TXT File"

# sets the varible for the file location ei c:\temp\ThisFile.exe
$Source = Read-Host "Enter File Source"

# sets the varible for the file destination
$Destination = Read-Host "Enter File destination (windows\temp)"


# displays the computer names on screen
Get-Content $Computers | foreach {Copy-Item $Source -Destination \\$_\c$\$Destination}
