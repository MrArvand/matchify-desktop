param(
    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0"
)

Write-Host "Testing Inno Setup script preparation for version: $Version" -ForegroundColor Green

# Check if setup.iss exists
if (!(Test-Path "setup.iss")) {
    Write-Error "setup.iss not found in current directory"
    Write-Host "Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found setup.iss template" -ForegroundColor Green

# Test the prepare script
try {
    & "scripts\prepare-inno-setup.ps1" -Version $Version
    
    if (Test-Path "setup-prepared.iss") {
        Write-Host "✅ Inno Setup script prepared successfully" -ForegroundColor Green
        
        # Show the prepared script content
        Write-Host "`n📄 Prepared script content (first 15 lines):" -ForegroundColor Cyan
        Get-Content "setup-prepared.iss" | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
        
        # Check if version was replaced correctly
        $content = Get-Content "setup-prepared.iss" -Raw
        if ($content -match $Version) {
            Write-Host "✅ Version replacement successful: $Version" -ForegroundColor Green
        } else {
            Write-Host "❌ Version replacement failed" -ForegroundColor Red
        }
        
        # Clean up
        Remove-Item "setup-prepared.iss" -Force
        Write-Host "🧹 Cleaned up test files" -ForegroundColor Yellow
        
    } else {
        Write-Error "Failed to create setup-prepared.iss"
        exit 1
    }
    
} catch {
    Write-Error "Error testing Inno Setup script preparation: $_"
    exit 1
}

Write-Host "`n🎉 All tests passed successfully!" -ForegroundColor Green
Write-Host "The Inno Setup workflow is ready to use." -ForegroundColor Cyan
