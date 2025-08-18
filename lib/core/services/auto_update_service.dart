import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AutoUpdateService {
  static const String _githubRepo = 'MrArvand/matchify-desktop';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';

  /// Check if there's a new version available
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final latestVersion =
            releaseData['tag_name']?.replaceAll('v', '') ?? '';
        final releaseNotes = releaseData['body'] ?? '';
        final downloadUrl = _getDownloadUrl(releaseData['assets']);

        // Compare versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
            isAvailable: true,
          );
        }
      }

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        releaseNotes: '',
        downloadUrl: '',
        isAvailable: false,
      );
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }

  /// Get the appropriate download URL based on platform
  static String _getDownloadUrl(List<dynamic> assets) {
    if (assets == null || assets.isEmpty) return '';

    final platform = Platform.operatingSystem;

    for (final asset in assets) {
      final assetName = asset['name']?.toString().toLowerCase() ?? '';

      if (platform == 'windows' && assetName.contains('.exe')) {
        return asset['browser_download_url'] ?? '';
      } else if (platform == 'macos' && assetName.contains('.dmg')) {
        return asset['browser_download_url'] ?? '';
      } else if (platform == 'linux' && assetName.contains('.deb')) {
        return asset['browser_download_url'] ?? '';
      }
    }

    return assets.first['browser_download_url'] ?? '';
  }

  /// Compare version strings to determine if new version is available
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Pad with zeros if needed
      while (newParts.length < currentParts.length) newParts.add(0);
      while (currentParts.length < newParts.length) currentParts.add(0);

      for (int i = 0; i < newParts.length; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }

      return false; // Same version
    } catch (e) {
      return false;
    }
  }

  /// Download and install the update
  static Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      // Get temporary directory for download
      final tempDir = await getTemporaryDirectory();
      final fileName = downloadUrl.split('/').last;
      final filePath = '${tempDir.path}/$fileName';

      // Download the file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download update');
      }

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Install the update based on platform
      if (Platform.isWindows) {
        return await _installWindowsUpdate(filePath);
      } else if (Platform.isMacOS) {
        return await _installMacOSUpdate(filePath);
      } else if (Platform.isLinux) {
        return await _installLinuxUpdate(filePath);
      }

      return false;
    } catch (e) {
      print('Error downloading/installing update: $e');
      return false;
    }
  }

  /// Install update on Windows
  static Future<bool> _installWindowsUpdate(String filePath) async {
    try {
      // For Windows, we'll launch the installer
      final result = await Process.run('cmd', ['/c', 'start', '', filePath]);
      return result.exitCode == 0;
    } catch (e) {
      print('Error installing Windows update: $e');
      return false;
    }
  }

  /// Install update on macOS
  static Future<bool> _installMacOSUpdate(String filePath) async {
    try {
      // For macOS, mount the DMG and copy the app
      final result = await Process.run('open', [filePath]);
      return result.exitCode == 0;
    } catch (e) {
      print('Error installing macOS update: $e');
      return false;
    }
  }

  /// Install update on Linux
  static Future<bool> _installLinuxUpdate(String filePath) async {
    try {
      // For Linux, install the DEB package
      final result = await Process.run('sudo', ['dpkg', '-i', filePath]);
      return result.exitCode == 0;
    } catch (e) {
      print('Error installing Linux update: $e');
      return false;
    }
  }

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get app build number
  static Future<String> getBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      return 'Unknown';
    }
  }
}

/// Data class for update information
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool isAvailable;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.isAvailable,
  });

  /// Get formatted version comparison text
  String get versionComparisonText {
    if (!isAvailable) return 'نسخه فعلی: $currentVersion';
    return 'نسخه فعلی: $currentVersion → نسخه جدید: $latestVersion';
  }

  /// Get update size (if available)
  String get updateSize {
    // This would need to be implemented based on your GitHub release structure
    return 'نامشخص';
  }
}
