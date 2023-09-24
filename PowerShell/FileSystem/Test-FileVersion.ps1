Function Test-FileVersion {
	<#
	.SYNOPSIS
		Validates a file exists & is correct.

	.DESCRIPTION
		Checks to see is a file specified exists & validates that the SHA256 hash of the file is correct. 

	.PARAMETER Path
		The path to the file including the file name.

	.PARAMETER Hash
		The SHA256 hash of the file.

	.EXAMPLE
		Test-FileVersion -Path "C:\Temp\Test.jpg" -Hash 082544DB10BA9FD11A87DA919669D272F6EE61BF925DFAFCF7394A65700C35BB

	.NOTES
		Author: Patrick Hoban
	#>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,Position=0,
          ValueFromPipeline=$false,ValueFromPipeLineByPropertyName=$false)]
        [string]$Path,
        [parameter(Mandatory=$true,Position=1,
         ValueFromPipeline=$false,ValueFromPipeLineByPropertyName=$false,
         HelpMessage="SHA256")]
        [string]$Hash
    )

    $File = $Path.Split("\")[-1]
    If (Test-Path -Path $Path) {
        If ((Get-FileHash -Path $Path -Algorithm SHA256).Hash -eq $Hash) {
            Write-Host "$env:COMPUTERNAME $File is correct." -ForegroundColor Green
        } Else {
            Write-Host "$env:COMPUTERNAME $File is incorrect." -ForegroundColor Red
        }
    } Else {
        Write-Host "$env:COMPUTERNAME $File is missing." -ForegroundColor Red
    }
}
