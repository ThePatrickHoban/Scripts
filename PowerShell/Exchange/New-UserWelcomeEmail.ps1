#############################################################################
# New-UserWelcomeEmail.ps1
# Send email to newly created mailboxes
#
# Pat Richard, MVP
# http://ucblogs.net/blogs/exchange
# 
# This script is designed to be run as a Windows Scheduled task on an Exchange
# server. See http://www.ucblogs.net/blogs/exchange/archive/2009/10/07/Running-PowerShell-scripts-via-Scheduled-Tasks.aspx
# 
# VERSION COMPATIBILITY
# =====================
# Exchange: 2007
# PowerShell: 1.0
#
# RIGHTS REQUIRED
# ===============
# Exchange Recipient Administrator role (unverified)
#
# UPDATES
# =======
# v1.2 03/27/2010 use registry for last run info; variable cleanup
# v1.1 05/01/2009 
# v1.0 04/30/2009 Initial version
#
# DEDICATED BLOG POST:
# ====================
# None
#
# SOME INFO TAKEN FROM
# ====================
# http://blog.flaphead.dns2go.com/archive/2009/07/29/system-uptime.aspx
#
# DISCLAIMER
# ==========
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
# RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#############################################################################
if (-not((Get-PSSnapin) -match "Microsoft.Exchange.Management.PowerShell.Admin")){ Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin }

$strScriptName = 	$MyInvocation.MyCommand.Name
if (!(Get-ItemProperty HKLM:\Software\Innervation\$strScriptName -Name LastRun -EA SilentlyContinue)){
	# this is the first time the script has run - let's create the registry key and value for future runs
	New-Item -path HKLM:\Software\Innervation -EA SilentlyContinue | Out-Null
	New-Item -path HKLM:\Software\Innervation\$strScriptName | Out-Null
	New-ItemProperty -path HKLM:\Software\Innervation\$strScriptName -Name "LastRun" -Value (Get-Date) -propertyType String | Out-Null
	write-host "Initial configuration completed." -ForegroundColor green
}
# get time stamp from registry so we know when it last ran
$LastRun = Get-Date ((Get-ItemProperty -path HKLM:\Software\Innervation\$strScriptName -Name LastRun).LastRun)
$ElapsedTime = ((Get-Date) - $lastrun).TotalSeconds

$strMsgFrom = "Contoso HelpDesk <HelpDesk@contoso.com>"
$strMsgTitle = "Welcome to Contoso!"

$SMTPClient = New-Object Net.Mail.SmtpClient("localhost")

$MBXArray = @(Get-Mailbox -ResultSize Unlimited | ? {($_.WhenCreated -gt (Get-Date).AddSeconds(-$ElapsedTime)) -and ($_.ExchangeUserAccountControl -ne "AccountDisabled")})

ForEach ($mailbox in $MBXArray ) { 
$strMsgTo = $mailbox.PrimarySMTPAddress

$strMsgBody = "Hello, "+$mailbox.DisplayName+", and welcome to the Contoso family! Please keep this email for future use. It contains vital information.

--------------------------------------
Username and password
--------------------------------------
Your network username is '"+$mailbox.SamAccountName+"'. Use your username and password to login to the network. Your password should NEVER be shared with anyone except the I.T. department, and only then when requested. Please do not write it down on anything that can be seen by your coworkers. You will be prompted to change it regularly.

--------------------------------------
Email
--------------------------------------
Your email address is '"+$mailbox.PrimarySMTPAddress+"'. 

To access your email, calendar, contacts, and tasks from outside of the building, such as from home, you can do so from any Internet connected computer. Simply open Internet Explorer and go to the Outlook Web Access (OWA) page at https://mail.contoso.com/ and log in using your username and password. Please note the 's' in https.

If you’d like to have access to your email and contacts from your cell phone, you will need a cell phone that has Windows Mobile 5 or later, or an Apple iPhone. Blackberry phones are not supported. Instructions for configuring your device can be found in the Frequently Asked Questions (FAQ) section of the Contoso Intranet at https://intranet.contoso.com/helpdesk/Lists/SupportFaq/AllItems.aspx 

--------------------------------------
Contact information
--------------------------------------
Once you’re situated, please go to http://directory/DirectoryUpdate and update your information. Log in using your username and password. It’s important that you update your information anytime something changes, such as title, department, phone number, etc. This information is used in various systems and applications, and is your responsibility to keep up to date.

--------------------------------------
Computer, Email, and Internet policies
--------------------------------------
Contoso, Inc. provides a computer for your work tasks. The use of personally owned computers and related equipment is not permitted on our network. Additional information about use of Contoso computers, email, Internet, etc. can be found in the Employee Handbook located in the HR section of the intranet at https://intranet.contoso.com/hr/

--------------------------------------
Technical assistance
--------------------------------------
Should you need technical assistance, please check the Frequently Asked Questions (FAQ) section of the Contoso Intranet at https://intranet.contoso.com/helpdesk/Lists/SupportFaq/AllItems.aspx. If you cannot find an answer there, submit a Service Request on the Contoso intranet at https://intranet.contoso.com/helpdesk. If you are unable to access the intranet site, only then should you email HelpDesk@contoso.com. It is monitored by the whole IT department, and will ensure your issue is resolved in a timely manner.

Thank you, and, again, welcome to Contoso!
The Information Technology Department"


$SMTPClient.Send($strMsgFrom,$strMsgTo,$strMsgTitle,$strMsgBody)
}

# update registry here with a fresh time stamp
Set-ItemProperty HKLM:\Software\Innervation\$strScriptName -Name "LastRun" -Value (Get-Date) | Out-Null
