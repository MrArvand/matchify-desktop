import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime releaseDate;
  final bool isMandatory;
  final int fileSize;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseDate,
    required this.isMandatory,
    required this.fileSize,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
      releaseDate:
          DateTime.tryParse(json['release_date'] ?? '') ?? DateTime.now(),
      isMandatory: json['is_mandatory'] ?? false,
      fileSize: json['file_size'] ?? 0,
    );
  }
}

class AutoUpdateService {
  // TODO: Replace with your actual GitHub repository information
  static const String _updateCheckUrl =
      'https://api.github.com/repos/MrArvand/matchify-desktop/releases/latest';
  static const String _githubRepoUrl =
      'https://github.com/MrArvand/matchify-desktop';

  /// Check if repository URLs are properly configured
  static bool get isConfigured {
    return !_updateCheckUrl.contains('YOUR_USERNAME') &&
        !_updateCheckUrl.contains('YOUR_REPO');
  }

  /// Get configuration instructions
  static String get configurationInstructions {
    return '''
برای تنظیم سیستم به‌روزرسانی خودکار:

1. فایل `lib/core/services/auto_update_service.dart` را باز کنید
2. خطوط زیر را پیدا کنید:
   ```dart
   static const String _updateCheckUrl = 'https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/releases/latest';
   static const String _githubRepoUrl = 'https://github.com/YOUR_USERNAME/YOUR_REPO';
   ```
3. `YOUR_USERNAME` را با نام کاربری GitHub خود جایگزین کنید
4. `YOUR_REPO` را با نام مخزن GitHub خود جایگزین کنید

مثال:
```dart
static const String _updateCheckUrl = 'https://api.github.com/repos/johndoe/matchify-desktop/releases/latest';
static const String _githubRepoUrl = 'https://github.com/johndoe/matchify-desktop';
```
''';
  }

  /// Check for available updates
  static Future<UpdateInfo?> checkForUpdates() async {
    // Check if repository is configured
    if (!isConfigured) {
      print(
          'Debug: Repository URLs not configured. Please update the URLs in auto_update_service.dart');
      throw Exception(
          'Repository URLs not configured. Please update the URLs in auto_update_service.dart');
    }
    
    try {
      print('Debug: Checking for updates...');
      final response = await http.get(Uri.parse(_updateCheckUrl));
      
      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final latestVersion =
            releaseData['tag_name']?.replaceAll('v', '') ?? '';
        
        print('Debug: Latest version from GitHub: $latestVersion');

        // Get current app version
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        print('Debug: Current app version: $currentVersion');

        // Compare versions
        if (_compareVersions(latestVersion, currentVersion) > 0) {
          print('Debug: New version available!');
          // New version available
          final assets = releaseData['assets'] as List?;
          if (assets != null && assets.isNotEmpty) {
            print('Debug: Found ${assets.length} assets');
            // Find Windows executable asset
            final windowsAsset = assets.firstWhere(
              (asset) => asset['name']?.toString().contains('.exe') == true,
              orElse: () => null,
            );

            if (windowsAsset != null) {
              print('Debug: Found Windows asset: ${windowsAsset['name']}');
              return UpdateInfo(
                version: latestVersion,
                downloadUrl: windowsAsset['browser_download_url'] ?? '',
                releaseNotes: releaseData['body'] ?? '',
                releaseDate:
                    DateTime.tryParse(releaseData['published_at'] ?? '') ??
                        DateTime.now(),
                isMandatory: false, // You can make this configurable
                fileSize: windowsAsset['size'] ?? 0,
              );
            } else {
              print('Debug: No Windows executable found in assets');
            }
          } else {
            print('Debug: No assets found in release');
          }
        } else {
          print('Debug: No update needed - current version is up to date');
        }
      } else {
        print('Debug: GitHub API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking for updates: $e');
      rethrow;
    }
    
    return null;
  }

  /// Download the update
  static Future<String?> downloadUpdate(
      UpdateInfo updateInfo, Function(double) onProgress) async {
    try {
      final response = await http.get(
        Uri.parse(updateInfo.downloadUrl),
        headers: {'User-Agent': 'Matchify-Desktop-Updater'},
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final updateFile = File('${tempDir.path}/matchify_update.exe');
        
        // Write the file with progress tracking
        final bytes = response.bodyBytes;
        final totalBytes = bytes.length;
        
        await updateFile.writeAsBytes(bytes);
        
        onProgress(1.0); // Download complete
        return updateFile.path;
      }
    } catch (e) {
      print('Error downloading update: $e');
    }
    
    return null;
  }

  /// Install the update
  static Future<bool> installUpdate(String updateFilePath) async {
    try {
      if (Platform.isWindows) {
        // On Windows, we need to launch the installer
        // The installer should handle the update process
        final result = await Process.run(updateFilePath, []);
        return result.exitCode == 0;
      }
    } catch (e) {
      print('Error installing update: $e');
    }
    
    return false;
  }

  /// Open GitHub releases page
  static Future<void> openReleasesPage() async {
    final url = Uri.parse('$_githubRepoUrl/releases');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Compare version strings (returns 1 if version1 > version2, -1 if version1 < version2, 0 if equal)
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    // Pad with zeros if needed
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    
    return 0;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
