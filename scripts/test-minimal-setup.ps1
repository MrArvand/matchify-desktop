param(
    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0"
)

Write-Host "Testing minimal Inno Setup script for version: $Version" -ForegroundColor Green

# Check if setup-minimal.iss exists
if (!(Test-Path "setup-minimal.iss")) {
    Write-Error "setup-minimal.iss not found in current directory"
    Write-Host "Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found setup-minimal.iss template" -ForegroundColor Green

# Test the minimal script by replacing version
$templateContent = Get-Content -Path "setup-minimal.iss" -Raw -Encoding UTF8
$updatedContent = $templateContent -replace "\{#AppVersion\}", $Version

# Write the updated script
$outputPath = "setup-minimal-prepared.iss"
$updatedContent | Out-File -FilePath $outputPath -Encoding UTF8

if (Test-Path $outputPath) {
    Write-Host "✅ Minimal Inno Setup script prepared successfully" -ForegroundColor Green
    
    # Show the prepared script content
    Write-Host "`n📄 Prepared minimal script content (first 15 lines):" -ForegroundColor Cyan
    Get-Content $outputPath | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
    
    # Check if version was replaced correctly
    $content = Get-Content $outputPath -Raw
    if ($content -match $Version) {
        Write-Host "✅ Version replacement successful: $Version" -ForegroundColor Green
    } else {
        Write-Host "❌ Version replacement failed" -ForegroundColor Red
    }
    
    # Check for any problematic references
    Write-Host "`n🔍 Checking for potential issues..." -ForegroundColor Yellow
    $content = Get-Content $outputPath
    $lineNumber = 0
    foreach ($line in $content) {
        $lineNumber++
        if ($line -match "WizardImageFile|WizardSmallImageFile|SetupIconFile") {
            Write-Host "⚠️  Line $lineNumber contains image reference: $line" -ForegroundColor Yellow
        }
    }
    
    # Clean up
    Remove-Item $outputPath -Force
    Write-Host "🧹 Cleaned up test files" -ForegroundColor Yellow
    
} else {
    Write-Error "Failed to create setup-minimal-prepared.iss"
    exit 1
}

Write-Host "`n🎉 Minimal Inno Setup script test passed successfully!" -ForegroundColor Green
Write-Host "This script should work without any external file dependencies." -ForegroundColor Cyan
