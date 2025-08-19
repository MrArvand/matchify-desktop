# Inno Setup Workflow Setup

## Overview

This project now uses Inno Setup to create professional Windows installers (.exe files) instead of ZIP archives. The workflow automatically builds and releases Windows installers using GitHub Actions.

## What Changed

### Before (ZIP-based)

- Flutter build → ZIP archive → GitHub release
- Users had to extract ZIP and run executable manually
- No professional installation experience

### After (Inno Setup-based)

- Flutter build → Inno Setup compilation → Professional .exe installer → GitHub release
- Users get a professional installer with:
  - Beautiful installation wizard
  - Desktop and Start Menu shortcuts
  - Uninstaller support
  - Automatic application launch after installation
  - Persian language support

## Files Added/Modified

### New Files

- `setup.iss` - Inno Setup script template
- `scripts/prepare-inno-setup.ps1` - PowerShell script to prepare Inno Setup script
- `INNO_SETUP_SETUP.md` - This documentation file

### Modified Files

- `.github/workflows/release.yml` - Updated to use Inno Setup Action
- `lib/core/services/auto_update_service.dart` - Updated to handle .exe installers

## How It Works

### 1. GitHub Actions Workflow

When you push a tag (e.g., `v1.0.1`), the workflow:

1. **Builds Flutter app** for Windows
2. **Prepares Inno Setup script** with correct version number
3. **Compiles installer** using [Inno-Setup-Action](https://github.com/Minionguyjpro/Inno-Setup-Action)
4. **Creates backup ZIP** for users who prefer it
5. **Publishes release** with both .exe installer and ZIP backup

### 2. Inno Setup Script Features

- **App Name**: Matchify Desktop
- **Version**: Automatically set from Git tag
- **Publisher**: MrArvand
- **Languages**: English and Persian
- **Features**:
  - Desktop shortcut (optional)
  - Start Menu shortcuts
  - Quick Launch shortcut (Windows 7/8)
  - Registry entries for installation tracking
  - Automatic app launch after installation

### 3. Auto-Update System

The auto-update system now:

- **Prioritizes .exe installers** over ZIP files
- **Handles both file types** seamlessly
- **Direct installation** of .exe installers
- **Fallback to ZIP** if .exe not available

## Usage

### For Developers

#### Creating a Release

```bash
# 1. Update version in pubspec.yaml
version: 1.0.1+2

# 2. Commit and push changes
git add .
git commit -m "New features and improvements"
git push origin main

# 3. Create and push tag
git tag v1.0.1
git push origin v1.0.1
```

#### Customizing the Installer

Edit `setup.iss` to modify:

- App information (name, publisher, URLs)
- Installation options
- Shortcut creation
- Language support
- Compression settings

### For Users

#### Installing Updates

1. **Automatic**: Click "Check for Updates" in the app
2. **Manual**: Download from GitHub releases page

#### Installation Options

- **Recommended**: Use `.exe` installer for professional experience
- **Alternative**: Use `.zip` backup for manual installation

## Technical Details

### Inno Setup Compilation

- **Action**: `Minionguyjpro/Inno-Setup-Action@v1.2.6`
- **Options**: `/O+` (optimized compilation)
- **Output**: `output/` directory
- **File naming**: `matchify-desktop-setup-{version}.exe`

### Version Management

- **Source**: Git tag (e.g., `v1.0.1`)
- **Processing**: PowerShell script removes `v` prefix
- **Template**: `{#AppVersion}` placeholder in `setup.iss`
- **Output**: Prepared script with actual version number

### File Structure

```
project/
├── setup.iss                    # Inno Setup template
├── scripts/
│   └── prepare-inno-setup.ps1  # Version preparation script
├── .github/workflows/
│   └── release.yml             # GitHub Actions workflow
└── output/                      # Generated installers (after build)
    └── matchify-desktop-setup-{version}.exe
```

## Troubleshooting

### Common Issues

#### 1. Inno Setup Compilation Fails

- Check if `setup.iss` exists and is valid
- Verify PowerShell script execution
- Check GitHub Actions logs for detailed errors

#### 2. Version Not Set Correctly

- Ensure Git tag format is `v{version}` (e.g., `v1.0.1`)
- Check PowerShell script execution in workflow
- Verify `setup-prepared.iss` is created

#### 3. Installer Not Found

- Check `output/` directory in workflow
- Verify file naming convention
- Check Inno Setup Action logs

### Debug Steps

1. **Check workflow logs** for each step
2. **Verify file creation** in each step
3. **Test PowerShell scripts** locally if needed
4. **Check Inno Setup syntax** in `setup.iss`

## Benefits

### For Users

- ✅ Professional installation experience
- ✅ Automatic shortcut creation
- ✅ Easy uninstallation
- ✅ Persian language support
- ✅ Automatic app launch

### For Developers

- ✅ Automated installer creation
- ✅ Professional release presentation
- ✅ Better user experience
- ✅ Reduced support requests
- ✅ Backup ZIP option maintained

### For Distribution

- ✅ Single .exe file distribution
- ✅ Professional appearance
- ✅ Better user trust
- ✅ Easier deployment
- ✅ Standard Windows installation

## Future Enhancements

### Potential Improvements

- **Multi-language support** for more languages
- **Custom installer themes** and branding
- **Silent installation** options
- **Update detection** in installer
- **Digital signatures** for security
- **Delta updates** for smaller downloads

### Advanced Features

- **MSI package** creation
- **Chocolatey package** support
- **Windows Store** preparation
- **Enterprise deployment** tools

## Support

### Resources

- [Inno Setup Documentation](https://jrsoftware.org/ishelp/)
- [Inno-Setup-Action](https://github.com/Minionguyjpro/Inno-Setup-Action)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Getting Help

1. Check GitHub Actions workflow logs
2. Verify Inno Setup script syntax
3. Test PowerShell scripts locally
4. Review this documentation
5. Check auto-update service logs

---

**Note**: This workflow maintains backward compatibility by providing both .exe installers and ZIP backups. Users can choose their preferred installation method.
