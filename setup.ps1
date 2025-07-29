# Matchify Desktop Setup Script
# This script helps set up the Flutter desktop application

Write-Host "🚀 Setting up Matchify Desktop..." -ForegroundColor Green

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Red
    exit 1
}

# Check Flutter version
$flutterVersion = flutter --version | Select-String "Flutter" | ForEach-Object { $_.ToString().Split()[1] }
Write-Host "✅ Flutter version: $flutterVersion" -ForegroundColor Green

# Get dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
    exit 1
}

# Create fonts directory if it doesn't exist
if (!(Test-Path "assets/fonts")) {
    Write-Host "Creating fonts directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "assets/fonts" -Force
}

# Check if Vazirmatn fonts are present
$fontFiles = @("Vazirmatn-Regular.ttf", "Vazirmatn-Medium.ttf", "Vazirmatn-Bold.ttf")
$missingFonts = @()

foreach ($font in $fontFiles) {
    if (!(Test-Path "assets/fonts/$font")) {
        $missingFonts += $font
    }
}

if ($missingFonts.Count -gt 0) {
    Write-Host "⚠️  Missing font files:" -ForegroundColor Yellow
    foreach ($font in $missingFonts) {
        Write-Host "   - $font" -ForegroundColor Yellow
    }
    Write-Host "Please download Vazirmatn fonts from Google Fonts and place them in assets/fonts/" -ForegroundColor Yellow
    Write-Host "Download URL: https://fonts.google.com/specimen/Vazirmatn" -ForegroundColor Cyan
}

# Enable Windows desktop
Write-Host "Enabling Windows desktop support..." -ForegroundColor Yellow
flutter config --enable-windows-desktop

# Build the application
Write-Host "Building the application..." -ForegroundColor Yellow
flutter build windows
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build application" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the application:" -ForegroundColor Cyan
Write-Host "  flutter run -d windows" -ForegroundColor White
Write-Host ""
Write-Host "To build for distribution:" -ForegroundColor Cyan
Write-Host "  flutter build windows --release" -ForegroundColor White
Write-Host ""
Write-Host "📖 For more information, see README.md" -ForegroundColor Cyan 