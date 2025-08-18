# Auto-Update System Setup Guide

## Overview
This guide explains how to set up and use the auto-update system for Matchify Desktop. The system allows users to update the application directly from within the app.

## Features
- ✅ Automatic update checking
- ✅ In-app update download and installation
- ✅ Progress tracking
- ✅ Release notes display
- ✅ Version comparison
- ✅ Windows-only builds

## Setup Instructions

### 1. Configure Repository Information

Edit `lib/core/services/auto_update_service.dart` and replace the placeholder URLs:

```dart
// Replace with your actual GitHub repository information
static const String _updateCheckUrl = 'https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/releases/latest';
static const String _githubRepoUrl = 'https://github.com/YOUR_USERNAME/YOUR_REPO';
```

**Example:**
```dart
static const String _updateCheckUrl = 'https://api.github.com/repos/johndoe/matchify-desktop/releases/latest';
static const String _githubRepoUrl = 'https://github.com/johndoe/matchify-desktop';
```

### 2. Update Version in pubspec.yaml

Before each release, update the version in `pubspec.yaml`:

```yaml
version: 1.0.1+2  # Increment this for each release
```

### 3. Create a Release

To create a new release:

1. **Commit and push your changes:**
   ```bash
   git add .
   git commit -m "New features and improvements"
   git push origin main
   ```

2. **Create and push a tag:**
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. **GitHub Actions will automatically:**
   - Build the Windows executable
   - Create a release archive
   - Publish the release on GitHub

### 4. Release Process

The GitHub Actions workflow (`/.github/workflows/release.yml`) will:

1. **Trigger** when you push a tag starting with `v`
2. **Build** the Windows executable using Flutter
3. **Package** the app into a ZIP file
4. **Create** a GitHub release with the executable
5. **Make** the update available to users

## How It Works

### Update Check Flow:
1. User clicks "Check for Updates" button
2. App queries GitHub API for latest release
3. Compares current version with latest version
4. Shows update information if available

### Update Process:
1. User clicks "Download and Install"
2. App downloads the new executable
3. Shows download progress
4. Launches the installer
5. User completes installation

### Version Comparison:
- Uses semantic versioning (e.g., 1.0.1, 1.1.0, 2.0.0)
- Automatically determines if update is needed
- Supports major, minor, and patch versions

## User Experience

### Update Checker Widget:
- **Location**: App bar (system update icon)
- **Features**: 
  - Current version display
  - Update availability check
  - Download progress
  - Release notes
  - Direct GitHub access

### Update States:
- **Checking**: "در حال بررسی به‌روزرسانی..."
- **Downloading**: "در حال دانلود به‌روزرسانی..."
- **Installing**: "در حال نصب به‌روزرسانی..."
- **Up to Date**: "نسخه شما به‌روز است"
- **Update Available**: Shows version info and download button

## Configuration Options

### Mandatory Updates:
You can make updates mandatory by modifying the `UpdateInfo` creation:

```dart
return UpdateInfo(
  // ... other fields
  isMandatory: true, // Force users to update
);
```

### Update Check Frequency:
Add automatic update checking by calling the service periodically:

```dart
// Check for updates every 24 hours
Timer.periodic(const Duration(hours: 24), (_) {
  ref.read(autoUpdateProvider.notifier).checkForUpdates();
});
```

## Troubleshooting

### Common Issues:

1. **Update not detected:**
   - Check repository URL configuration
   - Verify GitHub release exists
   - Check version format in pubspec.yaml

2. **Download fails:**
   - Check internet connection
   - Verify GitHub release is public
   - Check file size limits

3. **Installation fails:**
   - Ensure Windows compatibility
   - Check file permissions
   - Verify executable integrity

### Debug Information:
The service logs debug information to console:
```
Debug: Checking for updates...
Debug: Latest version: 1.0.1
Debug: Current version: 1.0.0
Debug: Update available
Debug: Downloading update...
Debug: Update downloaded successfully
```

## Security Considerations

- **HTTPS Only**: All downloads use HTTPS
- **GitHub Verification**: Updates only from your verified repository
- **File Integrity**: GitHub provides SHA checksums for verification
- **User Control**: Users can choose when to update

## Best Practices

1. **Version Management:**
   - Use semantic versioning
   - Increment version before each release
   - Tag releases consistently

2. **Release Notes:**
   - Write clear, Persian release notes
   - Include all changes and improvements
   - Mention breaking changes

3. **Testing:**
   - Test update process thoroughly
   - Verify installer works correctly
   - Test rollback scenarios

4. **User Communication:**
   - Notify users of important updates
   - Provide clear installation instructions
   - Offer support for update issues

## Support

For issues with the auto-update system:
1. Check the debug logs
2. Verify GitHub repository configuration
3. Test the GitHub Actions workflow
4. Check user permissions and network access

## Future Enhancements

Potential improvements:
- Delta updates (smaller downloads)
- Background update checking
- Automatic update installation
- Update rollback functionality
- Multi-platform support
- Enterprise update servers
