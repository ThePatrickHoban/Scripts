$Servers = Get-Content -Path PATH_TO_LIST_OF_SERVERS
$ScriptBlock = {
  $Path = "D:\Apps"
      $Files = Get-ChildItem -Path $Path -Recurse -Force
      $Attribute = [io.fileattributes]::hidden
      ForEach ($File in $Files) {
          $a = Get-Item $File.FullName -Force
          If (($a).Attributes -band $Attribute) {
              Write-Host $env:COMPUTERNAME $a ":" $a.Attributes -ForegroundColor Red
              #Remove Hidden attribute
              (($a).Attributes = 'Archive')
              Write-Host $env:COMPUTERNAME $a ":" $a.Attributes -ForegroundColor Yellow
          }
          Else {
              Write-Host $env:COMPUTERNAME $a ":" $a.Attributes -ForegroundColor Green
          }
          #(Get-Item $File.FullName -Force).Attribute
      }
}

Invoke-Command -ComputerName $Servers -ScriptBlock $ScriptBlock
