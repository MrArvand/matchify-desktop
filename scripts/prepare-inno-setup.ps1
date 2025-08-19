param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

Write-Host "Preparing Inno Setup script for version: $Version"

# Remove 'v' prefix if present
$cleanVersion = $Version -replace "^v", ""

# Read the template Inno Setup script
$templatePath = "setup.iss"
$templateContent = Get-Content -Path $templatePath -Raw -Encoding UTF8

# Replace the version placeholder
$updatedContent = $templateContent -replace "\{#AppVersion}", $cleanVersion

# Write the updated script
$outputPath = "setup-prepared.iss"
$updatedContent | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "Inno Setup script prepared: $outputPath"
Write-Host "Version set to: $cleanVersion"

# Verify the file was created
if (Test-Path $outputPath) {
    $fileSize = (Get-Item $outputPath).Length
    Write-Host "File created successfully. Size: $fileSize bytes"
} else {
    Write-Error "Failed to create prepared Inno Setup script"
    exit 1
}
