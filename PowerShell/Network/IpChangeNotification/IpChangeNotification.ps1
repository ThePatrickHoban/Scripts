$scriptpath = $MyInvocation.MyCommand.Definition 
[string]$dir = Split-Path $scriptpath  
set-location $dir

$oldip = gc .\ip.txt
Write-Host "Your previous IP was: $oldip"
$currentip = (New-Object net.webclient).downloadstring("http://api.ipify.org")
while ($currentip -eq '') {$currentip = (New-Object net.webclient).downloadstring("http://api.ipify.org")}
Write-Host "Your current IP is: $currentip"

$smtpServer = "smtp.mail.com"
$sender = "sender@mail.com"
$users = "user1@gmail.com", "user2@hotmail.com";
$subject = "Your IP $currentip" 
$body = "Previous IP was $oldip" 

if ($oldip -ne $currentip) {
    foreach ($user in $users) {
    Write-Host "Sending email notification to $user" -ForegroundColor Green
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, 587) 
    $smtp.EnableSsl = $true 
    $smtp.Credentials = New-Object System.Net.NetworkCredential("sender@email.com", "password"); 
    $smtp.Send($sender, $user, $subject, $body)
    }
}

$currentip | Out-File .\ip.txt -Force
Write-Host "New IP saved in file is: $currentip"
