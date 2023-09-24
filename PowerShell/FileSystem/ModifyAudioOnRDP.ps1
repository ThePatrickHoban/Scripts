# Updates all RDP files in a directory to enable the audio settings using a list of computers .

# ModifyAudioOnRDP.txt contains a list of computers on each line.
$Computers = Get-Content -Path "M:\Scripts\ModifyAudioOnRDP.txt"
ForEach ($Computer in $Computers) {
    If (Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue) {
        Write-Host "$Computer UP" -ForegroundColor Green
        #Check C:\RDP for all .RDP files.
        $RDPs = Get-ChildItem "\\$Computer\c$\RDP\*.*" -File -Include *.RDP
        ForEach ($File in $RDPs) {
            Write-Host $File
            (Get-Content $File).Replace('audiomode:i:2','audiomode:i:0') | Out-File $File
        }
        #Remove computername from list??????
    } Else {
        Write-Host "$Computer Down" -ForegroundColor Red
    }
}
