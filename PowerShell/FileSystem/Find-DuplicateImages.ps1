function Find-DuplicateImages {
<#
.VERSION
    1.0.1.0

.SYNOPSIS
    Finds duplicate image files by SHA256 hash and generates HTML and CSV reports.

.DESCRIPTION
    Recursively scans the specified folder for image files, computes SHA256 hashes,
    identifies duplicates, and outputs:
    - An HTML report with image previews, file info, and PowerShell deletion commands.
    - A CSV file listing duplicate files with their metadata.

.PARAMETER PicturePath
    The root directory path to search for images. Defaults to 'C:\Temp\Pictures'.

.PARAMETER ReportPath
    The directory path where the HTML and CSV reports will be saved. Defaults to 'C:\Temp'.

.EXAMPLE
    Find-DuplicateImages -PicturePath "D:\Photos" -ReportPath "D:\Reports"
    Scans "D:\Photos" and saves the reports in "D:\Reports".

.EXAMPLE
    Find-DuplicateImages
    Uses default paths: scans "C:\Temp\Pictures" and saves reports to "C:\Temp".

.INPUTS
    None. This function does not accept pipeline input.

.OUTPUTS
    System.String
    Outputs the file paths of the generated HTML and CSV reports.

.NOTES
    - Requires PowerShell 5.1+ (for Get-FileHash and System.Drawing).
    - Images supported: JPG, PNG, GIF, BMP, TIFF.
    - The HTML report includes expandable groups of duplicates with previews and delete commands.
    - The CSV report contains file paths, sizes, dimensions, and hash values.

.LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/get-filehash
    https://learn.microsoft.com/dotnet/api/system.drawing.image

.EXTERNALHELP
    None.

#>

    [CmdletBinding()]
    param (
        [string]$PicturePath = "C:\Temp\Pictures",
        [string]$ReportPath = "C:\Temp"
    )

    # Version of this script/function
    [Version]$ScriptVersion = [Version]"1.0.1.0"

    # Write verbose info about version
    Write-Verbose "Running Find-DuplicateImages version $ScriptVersion"

    # Load required .NET assemblies for image processing and HTML encoding
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Web

    # Generate timestamp strings for filenames and display
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $humanTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Compose full output file paths with timestamp appended
    $CsvOutput = Join-Path -Path $ReportPath -ChildPath "DuplicateImages_$timestamp.csv"
    $HtmlOutput = Join-Path -Path $ReportPath -ChildPath "DuplicateImages_$timestamp.html"

    # Define image file extensions to search for
    $imageExtensions = '*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.tiff'

    # Get all image files recursively from the PicturePath
    $imageFiles = Get-ChildItem -Path $PicturePath -Recurse -Include $imageExtensions -File -ErrorAction SilentlyContinue

    # Hashtable to store lists of files grouped by their SHA256 hash
    $hashes = @{}

    # Hashtable to map file paths to their hashes (for CSV export)
    $fileHashMap = @{}

    # Loop through each image file and calculate its SHA256 hash
    foreach ($file in $imageFiles) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            $fileHashMap[$file.FullName] = $hash.Hash

            # Group files by hash - duplicates have the same hash key
            if ($hashes.ContainsKey($hash.Hash)) {
                $hashes[$hash.Hash] += ,$file
            } else {
                $hashes[$hash.Hash] = @($file)
            }
        } catch {
            # Warn if any file cannot be hashed (e.g., locked or inaccessible)
            Write-Warning "Failed to hash file: $($file.FullName)"
        }
    }

    # Array to store objects for CSV export
    $csvData = @()
    # Array to accumulate HTML sections per duplicate group
    $htmlSections = @()

    # Process each hash group that has duplicates (more than one file)
    foreach ($entry in $hashes.GetEnumerator()) {
        $hash = $entry.Key
        $files = $entry.Value

        if ($files.Count -gt 1) {
            # Start a collapsible section for this duplicate group with hash and file count
            $groupHeader = "<details><summary><strong>Duplicate Group - Hash:</strong> <code>$hash</code> ($($files.Count) files)</summary><div style='margin:10px 0;'>"

            # Initialize the HTML table for this group
            $sectionHtml = @"
$groupHeader
<table>
<tr>
    <th>Preview</th>
    <th>Path</th>
    <th>Size (KB)</th>
    <th>Dimensions</th>
    <th>Hash</th>
    <th>Delete Command</th>
</tr>
"@

            # Add a table row for each duplicate file
            foreach ($file in $files) {
                try {
                    # Load image to get dimensions
                    $img = [System.Drawing.Image]::FromFile($file.FullName)

                    # Prepare an object for CSV export
                    $entryObj = [PSCustomObject]@{
                        FilePath   = $file.FullName
                        FileSizeKB = "{0:N1}" -f ($file.Length / 1KB)
                        Width      = $img.Width
                        Height     = $img.Height
                        Hash       = $hash
                    }
                    $csvData += $entryObj

                    # Dispose image object to free file handle
                    $img.Dispose()

                    # HTML-encode file path to safely display in HTML
                    $encodedPath = [System.Web.HttpUtility]::HtmlEncode($file.FullName)

                    # Escape single quotes in path for use in PowerShell command string
                    $escapedPath = $file.FullName.Replace("'", "''")

                    # Prepare PowerShell delete command snippet for this file
                    $deleteCmd = "Remove-Item -LiteralPath '$escapedPath' -Force"

                    # Build image preview tag using local file URI
                    $imgTag = "<img src='file:///$encodedPath' alt='Image'/>"

                    # Append a table row with preview, file info, hash, and delete command
                    $sectionHtml += @"
<tr>
    <td>$imgTag</td>
    <td>$encodedPath</td>
    <td>$($entryObj.FileSizeKB)</td>
    <td>$($entryObj.Width) x $($entryObj.Height)</td>
    <td><code>$hash</code></td>
    <td><code>$deleteCmd</code></td>
</tr>
"@

                } catch {
                    # Warn if image metadata cannot be read (corrupt or unsupported file)
                    Write-Warning "Unable to read image metadata: $($file.FullName)"
                }
            }

            # Close the table and add a "Back to Top" link, then close details element
            $sectionHtml += "</table><div style='margin-top:10px;'><a href='#top'>🔝 Back to Top</a></div></div></details><br/>"

            # Add this group’s HTML to the array of all groups
            $htmlSections += $sectionHtml
        }
    }

    # Export the collected duplicate file info to CSV
    $csvData | Export-Csv -Path $CsvOutput -NoTypeInformation -Encoding UTF8

    # Build the full HTML page with styles, scripts, header, and the duplicate groups content
    $htmlBody = @"
<html>
<head>
    <title>Duplicate Images Report</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        img { max-width: 200px; max-height: 200px; margin: 5px; border: 1px solid #ccc; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #aaa; padding: 8px; text-align: left; vertical-align: middle; }
        code, pre { background-color: #f9f9f9; display: block; padding: 10px; border: 1px solid #ccc; overflow-x: auto; }
        details summary { cursor: pointer; font-size: 16px; padding: 4px; background: #e0e0e0; border: 1px solid #aaa; }
        details { margin-bottom: 10px; }
        .toggle-buttons { margin-bottom: 20px; }
        .toggle-buttons button { padding: 5px 10px; margin-right: 10px; font-size: 14px; cursor: pointer; }
        a { text-decoration: none; color: #0077cc; }
        a:hover { text-decoration: underline; }
    </style>
    <script>
        // Function to expand all <details> sections
        function expandAll() {
            document.querySelectorAll('details').forEach(d => d.open = true);
        }
        // Function to collapse all <details> sections
        function collapseAll() {
            document.querySelectorAll('details').forEach(d => d.open = false);
        }
    </script>
</head>
<body>
    <a id='top'></a>
    <h1>Duplicate Images Report</h1>
    <p><strong>Report Generated:</strong> $humanTimestamp</p>

    <div class='toggle-buttons'>
        <button onclick='expandAll()'>Expand All</button>
        <button onclick='collapseAll()'>Collapse All</button>
    </div>

    <p>Below are image groups with identical SHA256 hashes. Each row contains a deletion command you can run in PowerShell to remove the file.</p>
"@

    # Add all duplicate groups HTML content to the body
    $htmlBody += ($htmlSections -join "`n")

    # Close HTML tags
    $htmlBody += "</body></html>"

    # Write the final HTML report to file
    Set-Content -Path $HtmlOutput -Value $htmlBody -Encoding UTF8

    # Output paths of the generated reports
    Write-Output "✅ HTML report saved to: $HtmlOutput"
    Write-Output "✅ CSV report saved to: $CsvOutput"
}
