# Auto-Update System Setup Guide

This guide explains how to set up and use the auto-update system for your Matchify Desktop application.

## 🚀 Features

- **Automatic Update Detection**: Checks GitHub releases for new versions
- **In-App Updates**: Users can download and install updates directly from the app
- **Cross-Platform Support**: Works on Windows, macOS, and Linux
- **Progress Tracking**: Shows download and installation progress
- **Error Handling**: Graceful fallbacks and user-friendly error messages

## 📋 Prerequisites

1. **GitHub Repository**: Your project must be on GitHub
2. **Flutter Desktop Support**: Ensure Flutter desktop is properly configured
3. **Dependencies**: The required packages are already added to `pubspec.yaml`

## 🔧 Setup Steps

### 1. Update GitHub Repository Information

Edit `lib/core/services/auto_update_service.dart` and update these lines:

```dart
static const String _githubRepo = 'your-username/matchify-desktop'; // Replace with your actual repo
```

### 2. Configure Version Management

Update your `pubspec.yaml` version when releasing:

```yaml
version: 1.0.1+1 # Increment this for each release
```

### 3. GitHub Actions Workflow

The `.github/workflows/release.yml` file is already configured. It will:

- Build for all platforms when you create a release tag
- Upload platform-specific installers
- Create GitHub releases automatically

## 🏷️ Creating a New Release

### Method 1: GitHub Web Interface

1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Create a new tag (e.g., `v1.0.1`)
4. Write release notes
5. Publish the release

### Method 2: Git Commands

```bash
# Create and push a new tag
git tag v1.0.1
git push origin v1.0.1

# The GitHub Action will automatically:
# 1. Build the app for all platforms
# 2. Create installers
# 3. Upload to the release
```

## 📱 How Users Get Updates

### 1. **Automatic Check**

- The app checks for updates when launched
- Users see a notification if updates are available

### 2. **Manual Check**

- Users can go to the "به‌روزرسانی" tab
- Click "بررسی مجدد" to check for updates

### 3. **Installation Process**

- Click "دانلود و نصب به‌روزرسانی"
- The app downloads the appropriate installer
- Shows progress with a progress bar
- Launches the installer automatically

## 🛠️ Technical Implementation

### Core Components

1. **`AutoUpdateService`**: Handles GitHub API calls and file operations
2. **`AutoUpdateProvider`**: Manages state using Riverpod
3. **`AutoUpdateWidget`**: UI component for the update tab
4. **GitHub Actions**: Automated build and release pipeline

### Update Flow

```
User Opens App → Check for Updates → GitHub API → Compare Versions
                                                      ↓
                                              Update Available?
                                                      ↓
                                              Yes → Show Update UI
                                                      ↓
                                              User Clicks Install
                                                      ↓
                                              Download Installer
                                                      ↓
                                              Launch Installer
                                                      ↓
                                              App Restarts
```

## 🔒 Security Considerations

- **HTTPS Only**: All downloads use HTTPS from GitHub
- **Signature Verification**: Consider adding code signing for production
- **User Consent**: Users must explicitly choose to install updates
- **Rollback Support**: Users can reinstall previous versions

## 🐛 Troubleshooting

### Common Issues

1. **Update Not Detected**

   - Check GitHub repository name in `AutoUpdateService`
   - Verify release tag format (should start with 'v')
   - Ensure GitHub Actions workflow completed successfully

2. **Download Fails**

   - Check internet connection
   - Verify GitHub release assets are accessible
   - Check file permissions on target directory

3. **Installation Fails**
   - Ensure user has admin privileges (Windows/Linux)
   - Check antivirus software blocking installation
   - Verify installer file integrity

### Debug Information

Enable debug logging by checking console output:

```dart
// In AutoUpdateService, these print statements show debug info:
print('Debug: Copied font file: $fontFile');
print('Debug: Error checking for updates: $e');
```

## 📈 Best Practices

### For Developers

1. **Version Naming**: Use semantic versioning (e.g., v1.0.1)
2. **Release Notes**: Write clear, user-friendly release notes
3. **Testing**: Test updates on all target platforms
4. **Rollback Plan**: Keep previous versions available

### For Users

1. **Backup Data**: Backup important data before updating
2. **Close App**: Ensure the app is closed before installing updates
3. **Admin Rights**: Some platforms require admin privileges
4. **Stable Connection**: Ensure stable internet during download

## 🔄 Update Frequency

- **Critical Updates**: Release immediately for security/bug fixes
- **Feature Updates**: Monthly or quarterly releases
- **User Control**: Users can choose when to install updates
- **Automatic Checks**: App checks weekly for updates

## 📞 Support

If you encounter issues:

1. Check the console output for error messages
2. Verify GitHub repository configuration
3. Ensure all dependencies are properly installed
4. Test on a clean environment

## 🎯 Future Enhancements

Potential improvements for the auto-update system:

- **Delta Updates**: Download only changed files
- **Background Updates**: Install updates when app is closed
- **Update Scheduling**: Allow users to schedule updates
- **Multiple Channels**: Beta/stable release channels
- **Update Notifications**: Push notifications for new releases

---

**Note**: This auto-update system is designed for desktop applications. For mobile apps, use the respective app store update mechanisms.
