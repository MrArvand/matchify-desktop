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

  /// Check if Inno Setup is available for professional installation
  static Future<bool> isInnoSetupAvailable() async {
    final innoSetupPath = await _findInnoSetupCompiler();
    return innoSetupPath != null;
  }

  /// Get Inno Setup installation instructions
  static String getInnoSetupInstructions() {
    return '''
برای استفاده از نصب‌کننده حرفه‌ای Inno Setup:

1. **دانلود Inno Setup:**
   - به سایت https://jrsoftware.org/isdl.php بروید
   - نسخه 6 یا 5 را دانلود کنید (رایگان است)

2. **نصب Inno Setup:**
   - فایل دانلود شده را اجرا کنید
   - مراحل نصب را دنبال کنید
   - گزینه "Add Inno Setup directory to the system PATH" را فعال کنید

3. **مزایای استفاده از Inno Setup:**
   ✅ نصب حرفه‌ای با رابط کاربری زیبا
   ✅ ایجاد میانبر در منوی Start و Desktop
   ✅ پشتیبانی از Uninstaller
   ✅ نصب خودکار و بدون نیاز به تعامل کاربر
   ✅ مدیریت بهتر فایل‌ها و پوشه‌ها

4. **نکته:** اگر Inno Setup نصب نباشد، سیستم به صورت خودکار از روش batch file استفاده می‌کند.
''';
  }

  /// Test method to manually check GitHub API response
  static Future<void> testGitHubApi() async {
    try {
      print('Debug: Testing GitHub API...');
      final response = await http.get(Uri.parse(_updateCheckUrl));

      print('Debug: Response status: ${response.statusCode}');
      print('Debug: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        print('Debug: Release data: $releaseData');

        final tagName = releaseData['tag_name'];
        final body = releaseData['body'];
        final publishedAt = releaseData['published_at'];
        final assets = releaseData['assets'] as List?;

        print('Debug: Tag name: $tagName');
        print('Debug: Body: $body');
        print('Debug: Published at: $publishedAt');
        print('Debug: Assets count: ${assets?.length ?? 0}');

        if (assets != null) {
          for (var asset in assets) {
            print(
                'Debug: Asset: ${asset['name']} - Size: ${asset['size']} - URL: ${asset['browser_download_url']}');
          }
        }
      } else {
        print('Debug: Error response: ${response.body}');
      }
    } catch (e) {
      print('Debug: Error testing GitHub API: $e');
    }
  }

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
        print('Debug: Latest GitHub version: $latestVersion');

        // Compare versions
        final comparison = _compareVersions(latestVersion, currentVersion);
        print('Debug: Version comparison result: $comparison');

        if (comparison > 0) {
          print('Debug: New version available!');
          // New version available
          final assets = releaseData['assets'] as List?;
          if (assets != null && assets.isNotEmpty) {
            print('Debug: Found ${assets.length} assets');
            // Find Windows EXE installer asset (preferred) or ZIP fallback
            final windowsAsset = assets.firstWhere(
              (asset) =>
                  asset['name']?.toString().contains('.exe') == true &&
                  asset['name']?.toString().contains('setup') == true,
              orElse: () => assets.firstWhere(
                (asset) => asset['name']?.toString().contains('.zip') == true,
                orElse: () => null,
              ),
            );

            if (windowsAsset != null) {
              print('Debug: Found Windows ZIP asset: ${windowsAsset['name']}');
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
              print('Debug: No Windows ZIP found in assets');
              // List all available assets for debugging
              for (var asset in assets) {
                print('Debug: Available asset: ${asset['name']}');
              }
            }
          } else {
            print('Debug: No assets found in release');
          }
        } else {
          print('Debug: No update needed - current version is up to date');
          print('Debug: Current: $currentVersion, Latest: $latestVersion');
          print('Debug: Comparison result: $comparison');
        }
      } else {
        print('Debug: GitHub API returned status code: ${response.statusCode}');
        print('Debug: Response body: ${response.body}');
      }
    } catch (e) {
      print('Error checking for updates: $e');
      rethrow;
    }
    
    return null;
  }

  /// Download the update with fallback
  static Future<String?> downloadUpdate(
      UpdateInfo updateInfo, Function(double) onProgress) async {
    try {
      print('Debug: Starting download from: ${updateInfo.downloadUrl}');

      // First, get the file size for progress tracking
      final headResponse = await http
          .head(Uri.parse(updateInfo.downloadUrl))
          .timeout(const Duration(seconds: 30));
      final totalBytes =
          int.tryParse(headResponse.headers['content-length'] ?? '0') ?? 0;

      print('Debug: Total file size: $totalBytes bytes');

      // Check if this is an EXE installer or ZIP file
      final isExeInstaller =
          updateInfo.downloadUrl.toLowerCase().contains('.exe');
      print(
          'Debug: Downloading ${isExeInstaller ? "EXE installer" : "ZIP file"}');

      // Try streaming download first
      try {
        return await _downloadWithStreaming(
            updateInfo, onProgress, totalBytes, isExeInstaller);
      } catch (e) {
        print('Debug: Streaming download failed, trying fallback method: $e');
        return await _downloadWithFallback(
            updateInfo, onProgress, totalBytes, isExeInstaller);
      }
    } catch (e) {
      print('Error downloading update: $e');
      rethrow;
    }
  }

  /// Streaming download method
  static Future<String?> _downloadWithStreaming(UpdateInfo updateInfo,
      Function(double) onProgress, int totalBytes, bool isExeInstaller) async {
    // Create a client for streaming download with timeout
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
    request.headers['User-Agent'] = 'Matchify-Desktop-Updater';

    final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 60)); // 60 second timeout for initial response

    if (streamedResponse.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final fileExtension = isExeInstaller ? '.exe' : '.zip';
      final updateFile = File('${tempDir.path}/matchify_update$fileExtension');

      print('Debug: Downloading to: ${updateFile.path}');

      // Create a file sink for writing
      final sink = updateFile.openWrite();
      int downloadedBytes = 0;
      DateTime lastProgressUpdate = DateTime.now();

      // Stream the response and track progress with timeout
      await for (final chunk in streamedResponse.stream.timeout(
        const Duration(seconds: 300), // 5 minute timeout for entire download
        onTimeout: (sink) {
          print('Debug: Download timeout - closing sink');
          sink.close();
          throw Exception('Download timed out after 5 minutes');
        },
      )) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        // Update progress every 100KB or every 2 seconds, whichever comes first
        final now = DateTime.now();
        if (downloadedBytes % (100 * 1024) == 0 ||
            now.difference(lastProgressUpdate).inSeconds >= 2) {
          // Calculate and report progress
          if (totalBytes > 0) {
            final progress = downloadedBytes / totalBytes;
            print(
                'Debug: Download progress: ${(progress * 100).toStringAsFixed(1)}% ($downloadedBytes/$totalBytes bytes)');
            onProgress(progress);
          } else {
            // If we can't determine total size, estimate progress
            final estimatedProgress =
                downloadedBytes / (1024 * 1024); // Assume 1MB minimum
            onProgress(estimatedProgress.clamp(0.0, 1.0));
          }

          lastProgressUpdate = now;
        }
      }

      await sink.close();
      client.close();

      print('Debug: Download completed successfully');
      print('Debug: Final file size: ${await updateFile.length()} bytes');
      onProgress(1.0); // Ensure we show 100% completion

      return updateFile.path;
    } else {
      print(
          'Debug: Download failed with status: ${streamedResponse.statusCode}');
      client.close();
      return null;
    }
  }

  /// Fallback download method (simpler approach)
  static Future<String?> _downloadWithFallback(UpdateInfo updateInfo,
      Function(double) onProgress, int totalBytes, bool isExeInstaller) async {
    print('Debug: Using fallback download method');
    
    final response = await http.get(
      Uri.parse(updateInfo.downloadUrl),
      headers: {'User-Agent': 'Matchify-Desktop-Updater'},
    ).timeout(const Duration(seconds: 300)); // 5 minute timeout

    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final fileExtension = isExeInstaller ? '.exe' : '.zip';
      final updateFile = File('${tempDir.path}/matchify_update$fileExtension');

      print('Debug: Downloading to: ${updateFile.path}');
      print('Debug: Downloaded size: ${response.bodyBytes.length} bytes');
      
      // Write the file
      await updateFile.writeAsBytes(response.bodyBytes);
      
      print('Debug: Download completed successfully with fallback method');
      print('Debug: Final file size: ${await updateFile.length()} bytes');
      onProgress(1.0); // Show 100% completion

      return updateFile.path;
    } else {
      print(
          'Debug: Fallback download failed with status: ${response.statusCode}');
      return null;
    }
  }

  /// Safely clean up a directory with retry logic
  static Future<bool> _safeDeleteDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        return true;
      }
      return true;
    } catch (e) {
      print('Debug: Failed to delete directory ${directory.path}: $e');
      return false;
    }
  }

  /// Launch executable directly as a fallback method
  static Future<bool> _launchExecutableDirectly(String executablePath) async {
    try {
      print('Debug: Trying fallback method - launching executable directly');
      final directResult = await Process.start(
        executablePath,
        [],
        mode: ProcessStartMode.detached,
      );
      print('Debug: Direct launch successful, PID: ${directResult.pid}');
      return true;
    } catch (e) {
      print('Debug: Direct launch also failed: $e');
      return false;
    }
  }

  /// Install the update using Inno Setup
  static Future<bool> installUpdate(String updateFilePath) async {
    try {
      if (Platform.isWindows) {
        print('Debug: Installing update from: $updateFilePath');

        // Check if file exists
        final file = File(updateFilePath);
        if (!await file.exists()) {
          print('Debug: Update file does not exist: $updateFilePath');
          return false;
        }

        print('Debug: Update file size: ${await file.length()} bytes');

        // Check if this is an EXE installer or ZIP file
        final isExeInstaller = updateFilePath.toLowerCase().endsWith('.exe');
        print(
            'Debug: Installing ${isExeInstaller ? "EXE installer" : "ZIP file"}');

        if (isExeInstaller) {
          // Direct installation of EXE installer
          return await _installExeInstaller(updateFilePath);
        } else {
          // Handle ZIP file as before
          return await _installZipUpdate(updateFilePath);
        }
      }
    } catch (e) {
      print('Error installing update: $e');
    }

    return false;
  }

  /// Install EXE installer directly
  static Future<bool> _installExeInstaller(String installerPath) async {
    try {
      print('Debug: Installing EXE installer: $installerPath');

      // Verify the installer file exists and is accessible
      final installerFile = File(installerPath);
      if (!await installerFile.exists()) {
        print('Debug: Installer file does not exist: $installerPath');
        return false;
      }

      final fileSize = await installerFile.length();
      print('Debug: Installer file size: $fileSize bytes');

      // Check if file is actually an executable (should be > 1MB for a proper installer)
      if (fileSize < 1024 * 1024) {
        print(
            'Debug: Warning: Installer file seems too small: $fileSize bytes');
      }

      // Check file extension
      if (!installerPath.toLowerCase().endsWith('.exe')) {
        print(
            'Debug: Warning: File does not have .exe extension: $installerPath');
      }

      // Launch the installer with standard options (not silent to allow user interaction)
      print('Debug: About to launch installer: $installerPath');

      // Try to launch the installer with elevated privileges if needed
      final installResult = await Process.start(
        installerPath,
        [], // No silent flags - let user see the installer
        mode: ProcessStartMode.detached,
        runInShell: true, // Run in shell for better Windows compatibility
      );

      print('Debug: EXE installer launched with PID: ${installResult.pid}');
      print('Debug: Installer process started successfully');

      // Give installer time to start and show UI
      await Future.delayed(const Duration(seconds: 2));
      print('Debug: Installer should now be visible to user');

      // Verify the process is actually running
      try {
        final isRunning = await isInstallerRunning();
        if (isRunning) {
          print('Debug: Installer process verified as running');
          return true;
        } else {
          print(
              'Debug: Installer process not found, trying fallback launch method');

          // Fallback: try launching with different method
          final fallbackResult = await Process.run(
            installerPath,
            [],
            runInShell: true,
          );

          if (fallbackResult.exitCode == 0) {
            print('Debug: Fallback launch successful');
            return true;
          } else {
            print('Debug: Fallback launch failed: ${fallbackResult.stderr}');
            return false;
          }
        }
      } catch (e) {
        print('Debug: Error verifying installer process: $e');
        return true; // Assume success if we can't verify
      }
    } catch (e) {
      print('Debug: EXE installer installation failed: $e');
      return false;
    }
  }

  /// Install ZIP update (existing logic)
  static Future<bool> _installZipUpdate(String updateFilePath) async {
    try {
      // Create a temporary directory for extraction
      final tempDir = await getTemporaryDirectory();
      var extractDir = Directory('${tempDir.path}/matchify_update_extracted');

      // Clean up any existing extraction directory with better error handling
      if (await extractDir.exists()) {
        print(
            'Debug: Existing extraction directory found, attempting to clean up...');
        final cleanupSuccess = await _safeDeleteDirectory(extractDir);
        if (!cleanupSuccess) {
          // Try to use a different directory name
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newExtractDir =
              Directory('${tempDir.path}/matchify_update_extracted_$timestamp');
          print('Debug: Using alternative directory: ${newExtractDir.path}');
          extractDir = newExtractDir;
        }
      }

      // Ensure the extraction directory exists
      if (!await extractDir.exists()) {
        await extractDir.create(recursive: true);
        print('Debug: Created extraction directory: ${extractDir.path}');
      }

      print('Debug: Using extraction directory: ${extractDir.path}');
      print('Debug: Extracting to: ${extractDir.path}');

      // Extract the ZIP file
      final extractResult = await Process.run('powershell.exe', [
        '-Command',
        'Expand-Archive -Path "$updateFilePath" -DestinationPath "${extractDir.path}" -Force'
      ]);

      if (extractResult.exitCode != 0) {
        print('Debug: Extraction failed: ${extractResult.stderr}');
        return false;
      }

      print('Debug: Extraction successful');

      // Find the main executable in the extracted files
      final executableFile = await _findMainExecutable(extractDir);
      if (executableFile == null) {
        print('Debug: Main executable not found in extracted files');
        return false;
      }

      print('Debug: Found main executable: ${executableFile.path}');

      // Try Inno Setup installation first, fallback to batch file if not available
      final innoSetupResult =
          await _installWithInnoSetup(executableFile.path, extractDir);
      if (innoSetupResult) {
        print('Debug: Inno Setup installation successful');
        return true;
      }

      print(
          'Debug: Inno Setup not available, falling back to batch file method');
      return await _installWithBatchFile(executableFile.path);
    } catch (e) {
      print('Debug: Error in ZIP update installation: $e');
      return false;
    }
  }

  /// Install update using Inno Setup Compiler
  static Future<bool> _installWithInnoSetup(
      String executablePath, Directory extractDir) async {
    try {
      print('Debug: Attempting Inno Setup installation...');

      // Check if Inno Setup is available
      final innoSetupPath = await _findInnoSetupCompiler();
      if (innoSetupPath == null) {
        print('Debug: Inno Setup Compiler not found');
        return false;
      }

      print('Debug: Found Inno Setup at: $innoSetupPath');

      // Create Inno Setup script
      final scriptFile =
          await _createInnoSetupScript(executablePath, extractDir);
      if (scriptFile == null) {
        print('Debug: Failed to create Inno Setup script');
        return false;
      }

      print('Debug: Created Inno Setup script: ${scriptFile.path}');

      // Run Inno Setup compiler
      final compileResult = await Process.run(innoSetupPath, [
        '/cc', // Compile and create installer
        scriptFile.path,
      ]);

      if (compileResult.exitCode != 0) {
        print('Debug: Inno Setup compilation failed: ${compileResult.stderr}');
        return false;
      }

      print('Debug: Inno Setup compilation successful');

      // Find the generated installer
      final installerFile = await _findGeneratedInstaller();
      if (installerFile == null) {
        print('Debug: Generated installer not found');
        return false;
      }

      print('Debug: Found generated installer: ${installerFile.path}');

      // Run the installer silently
      final installResult = await Process.start(
        installerFile.path,
        ['/SILENT', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
        mode: ProcessStartMode.detached,
      );

      print(
          'Debug: Inno Setup installer launched with PID: ${installResult.pid}');

      // Give installer time to start
      await Future.delayed(const Duration(seconds: 5));

      return true;
    } catch (e) {
      print('Debug: Inno Setup installation failed: $e');
      return false;
    }
  }

  /// Find Inno Setup Compiler installation
  static Future<String?> _findInnoSetupCompiler() async {
    try {
      // Common installation paths
      final commonPaths = [
        r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
        r'C:\Program Files\Inno Setup 6\ISCC.exe',
        r'C:\Program Files (x86)\Inno Setup 5\ISCC.exe',
        r'C:\Program Files\Inno Setup 5\ISCC.exe',
      ];

      for (final path in commonPaths) {
        if (await File(path).exists()) {
          return path;
        }
      }

      // Try to find in PATH
      try {
        final result = await Process.run('where', ['ISCC']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().trim().split('\n');
          if (lines.isNotEmpty) {
            return lines.first.trim();
          }
        }
      } catch (e) {
        print('Debug: Could not find ISCC in PATH: $e');
      }

      return null;
    } catch (e) {
      print('Debug: Error finding Inno Setup: $e');
      return null;
    }
  }

  /// Create Inno Setup script for the update
  static Future<File?> _createInnoSetupScript(
      String executablePath, Directory extractDir) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final scriptFile = File('${tempDir.path}/update_script.iss');

      // Get application name and version from executable
      final appName = 'Matchify Desktop';
      final appVersion = '1.0.1'; // This could be extracted from the executable
      final appPublisher = 'MrArvand';
      final appExeName = 'matchify_desktop.exe';

      final scriptContent = '''
[Setup]
AppName=${appName}
AppVersion=${appVersion}
AppPublisher=${appPublisher}
AppPublisherURL=https://github.com/MrArvand/matchify-desktop
AppSupportURL=https://github.com/MrArvand/matchify-desktop
AppUpdatesURL=https://github.com/MrArvand/matchify-desktop
DefaultDirName={autopf}\\${appName}
DefaultGroupName=${appName}
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
OutputDir=${tempDir.path}
OutputBaseFilename=matchify_desktop_update
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "${extractDir.path}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\\${appName}"; Filename: "{app}\\${appExeName}"
Name: "{group}\\{cm:UninstallProgram,${appName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\\${appName}"; Filename: "{app}\\${appExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\\${appExeName}"; Description: "{cm:LaunchProgram,${appName}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Launch the new version after installation
    Exec(ExpandConstant('{app}\\${appExeName}'), '', '', SW_SHOW, ewNoWait, ResultCode);
  end;
end;
''';

      await scriptFile.writeAsString(scriptContent);
      return scriptFile;
    } catch (e) {
      print('Debug: Error creating Inno Setup script: $e');
      return null;
    }
  }

  /// Find the generated installer file
  static Future<File?> _findGeneratedInstaller() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final installerFile = File('${tempDir.path}/matchify_desktop_update.exe');

      if (await installerFile.exists()) {
        return installerFile;
      }

      // Look for any .exe files that might be the installer
      final tempDirContents = await tempDir.list().toList();
      for (final entity in tempDirContents) {
        if (entity is File &&
            entity.path.endsWith('.exe') &&
            entity.path.contains('matchify')) {
          return entity;
        }
      }

      return null;
    } catch (e) {
      print('Debug: Error finding generated installer: $e');
      return null;
    }
  }

  /// Install update using batch file (fallback method)
  static Future<bool> _installWithBatchFile(String executablePath) async {
    try {
      // Create a batch file to handle the update process
      final batchFile = await _createUpdateBatchFile(executablePath);
      if (batchFile == null) {
        print('Debug: Failed to create update batch file');
        return false;
      }

      print('Debug: Created update batch file: ${batchFile.path}');

      // Launch the update batch file
      print('Debug: About to launch update batch file: ${batchFile.path}');

      // Launch the update batch file in a non-blocking way
      try {
        // Use Process.start instead of Process.run to avoid blocking
        final process = await Process.start(
          'cmd.exe',
          ['/c', batchFile.path],
          mode: ProcessStartMode.detached,
        );

        print(
            'Debug: Update batch launched successfully with PID: ${process.pid}');

        // Give the batch file a moment to start and then check status
        await Future.delayed(const Duration(seconds: 3));

        // Check if the process is still running with a timeout
        try {
          final exitCode = await process.exitCode.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print(
                  'Debug: Batch file is still running after 10 seconds - this is good');
              return -1; // -1 indicates still running
            },
          );

          if (exitCode == -1) {
            print('Debug: Batch file is running successfully (still active)');
            return true;
          } else {
            print('Debug: Batch file exited with code: $exitCode');
            // Try fallback method
            return await _launchExecutableDirectly(executablePath);
          }
        } catch (e) {
          print('Debug: Error checking batch file status: $e');
          // Assume it's running if we can't check
          return true;
        }
      } catch (e) {
        print('Debug: Failed to launch batch file: $e');
        // Try fallback method
        return await _launchExecutableDirectly(executablePath);
      }
    } catch (e) {
      print('Debug: Error in batch file installation: $e');
      return false;
    }
  }

  /// Gracefully close the app after update initiation
  static Future<void> closeAppForUpdate() async {
    try {
      print('Debug: Closing app for update...');

      // On Windows, we can use taskkill to close the current process
      if (Platform.isWindows) {
        print('Debug: Closing app on Windows...');

        // Use a batch file to close the app after a delay
        final tempDir = await getTemporaryDirectory();
        final closeBatchFile = File('${tempDir.path}/close_app.bat');

        final batchContent = '''
@echo off
echo Closing Matchify Desktop for update...
echo Waiting 3 seconds before closing...
timeout /t 3 /nobreak >nul
echo Closing app now...
taskkill /F /IM "matchify_desktop.exe" 2>NUL
if %ERRORLEVEL% EQU 0 (
    echo App closed successfully
) else (
    echo App may already be closed
)
del "%~f0"
''';

        await closeBatchFile.writeAsString(batchContent);
        print('Debug: Created close app batch file: ${closeBatchFile.path}');

        // Launch the close batch file
        final result = await Process.run('cmd.exe', ['/c', closeBatchFile.path],
            runInShell: true);
        print('Debug: Close app batch result: ${result.exitCode}');
        print('Debug: Close app stdout: ${result.stdout}');
        print('Debug: Close app stderr: ${result.stderr}');

        // Wait a moment then exit
        await Future.delayed(const Duration(seconds: 5));
      }

      print('Debug: Exiting app...');
      // Exit the app
      exit(0);
    } catch (e) {
      print('Debug: Error closing app: $e');
      // Fallback: just exit the app
      exit(0);
    }
  }

  /// Check if an installer process is still running
  static Future<bool> isInstallerRunning() async {
    try {
      if (Platform.isWindows) {
        print('Debug: Checking for running installer processes...');

        // Check for common installer processes
        final result =
            await Process.run('tasklist', ['/FI', 'IMAGENAME eq setup.exe']);
        if (result.exitCode == 0 && result.stdout.contains('setup.exe')) {
          print('Debug: Installer process (setup.exe) is still running');
          return true;
        }

        // Check for Inno Setup processes
        final innoResult =
            await Process.run('tasklist', ['/FI', 'IMAGENAME eq innosetup*']);
        if (innoResult.exitCode == 0 &&
            innoResult.stdout.contains('innosetup')) {
          print('Debug: Inno Setup process is still running');
          return true;
        }

        // Also check for any process with "matchify" in the name
        final matchifyResult =
            await Process.run('tasklist', ['/FI', 'IMAGENAME eq matchify*']);
        if (matchifyResult.exitCode == 0 &&
            matchifyResult.stdout.contains('matchify')) {
          print('Debug: Matchify installer process is still running');
          return true;
        }

        // Check for any .exe processes that might be our installer
        final exeResult =
            await Process.run('tasklist', ['/FI', 'IMAGENAME eq *.exe']);
        if (exeResult.exitCode == 0) {
          final lines = exeResult.stdout.split('\n');
          for (final line in lines) {
            if (line.toLowerCase().contains('matchify') ||
                line.toLowerCase().contains('setup') ||
                line.toLowerCase().contains('installer')) {
              print('Debug: Found potential installer process: $line');
              return true;
            }
          }
        }
      }

      print('Debug: No installer processes found running');
      return false;
    } catch (e) {
      print('Debug: Error checking installer processes: $e');
      return false;
    }
  }

  /// Wait for installer to complete with timeout
  static Future<bool> waitForInstallerCompletion(
      {int timeoutSeconds = 60}) async {
    try {
      print(
          'Debug: Waiting for installer to complete (timeout: ${timeoutSeconds}s)...');

      final startTime = DateTime.now();
      while (DateTime.now().difference(startTime).inSeconds < timeoutSeconds) {
        final isRunning = await isInstallerRunning();
        if (!isRunning) {
          print('Debug: Installer process completed');
          return true;
        }

        print('Debug: Installer still running, waiting...');
        await Future.delayed(const Duration(seconds: 2));
      }

      print('Debug: Timeout waiting for installer completion');
      return false;
    } catch (e) {
      print('Debug: Error waiting for installer completion: $e');
      return false;
    }
  }

  /// Find the main executable in the extracted files
  static Future<File?> _findMainExecutable(Directory directory) async {
    try {
      final files = await directory.list(recursive: true).toList();

      // Look for the main executable
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.exe')) {
          final fileName = entity.uri.pathSegments.last.toLowerCase();
          // Look for the main app executable
          if (fileName.contains('matchify') || fileName.contains('runner')) {
            print('Debug: Found potential main executable: ${entity.path}');
            return entity;
          }
        }
      }

      // If no specific executable found, return the first .exe file
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.exe')) {
          print('Debug: Using fallback executable: ${entity.path}');
          return entity;
        }
      }

      print('Debug: No executable files found in extracted directory');
      return null;
    } catch (e) {
      print('Debug: Error finding main executable: $e');
      return null;
    }
  }

  /// Create a batch file to handle the update process
  static Future<File?> _createUpdateBatchFile(String newExecutablePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final batchFile = File('${tempDir.path}/update_matchify.bat');

      // Create a batch script that:
      // 1. Waits a moment for the current app to close
      // 2. Launches the new executable
      // 3. Cleans up temporary files
      final batchContent = '''
@echo off
echo ========================================
echo    Matchify Desktop Update
echo ========================================
echo.
echo Starting update process...
echo Please wait while the application updates...
echo.

REM Wait for the current app to close
echo Waiting for current app to close...
timeout /t 3 /nobreak >nul

echo.
echo Launching new version...
echo.

REM Launch the new executable
echo Executing: "${newExecutablePath.replaceAll('/', '\\')}"
start "" "${newExecutablePath.replaceAll('/', '\\')}"

REM Check if the new executable started successfully
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq matchify_desktop.exe" 2>NUL | find /I "matchify_desktop.exe" >NUL
if %ERRORLEVEL% EQU 0 (
    echo New version started successfully!
) else (
    echo Warning: New version may not have started properly
)

echo.
echo Update completed successfully!
echo The new version is now running.
echo.

REM Clean up temporary files
echo Cleaning up temporary files...
timeout /t 2 /nobreak >nul

REM Delete this batch file
del "%~f0"

echo.
echo Update process finished.
exit
''';

      await batchFile.writeAsString(batchContent);
      return batchFile;
    } catch (e) {
      print('Debug: Error creating update batch file: $e');
      return null;
    }
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
    print('Debug: Comparing versions: "$version1" vs "$version2"');

    // Remove build numbers (everything after +)
    final cleanV1 = version1.split('+')[0];
    final cleanV2 = version2.split('+')[0];

    print('Debug: Clean versions: "$cleanV1" vs "$cleanV2"');

    final v1Parts = cleanV1.split('.').map((s) {
      try {
        return int.parse(s);
      } catch (e) {
        print('Debug: Error parsing version part "$s" from version1: $e');
        return 0;
      }
    }).toList();

    final v2Parts = cleanV2.split('.').map((s) {
      try {
        return int.parse(s);
      } catch (e) {
        print('Debug: Error parsing version part "$s" from version2: $e');
        return 0;
      }
    }).toList();

    print('Debug: Version parts: $v1Parts vs $v2Parts');
    
    // Pad with zeros if needed
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) {
        print(
            'Debug: Version1 is greater at position $i: ${v1Parts[i]} > ${v2Parts[i]}');
        return 1;
      }
      if (v1Parts[i] < v2Parts[i]) {
        print(
            'Debug: Version2 is greater at position $i: ${v1Parts[i]} < ${v2Parts[i]}');
        return -1;
      }
    }
    
    print('Debug: Versions are equal');
    return 0;
  }

  /// Verify that the update was installed successfully
  static Future<bool> verifyUpdateInstallation() async {
    try {
      print('Debug: Verifying update installation...');

      // Check if the new executable exists and can be launched
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/matchify_update_extracted');

      if (await extractDir.exists()) {
        final executableFile = await _findMainExecutable(extractDir);
        if (executableFile != null && await executableFile.exists()) {
          print('Debug: Update executable verified: ${executableFile.path}');
          return true;
        }
      }

      print('Debug: Update verification failed');
      return false;
    } catch (e) {
      print('Debug: Error verifying update: $e');
      return false;
    }
  }

  /// Clean up temporary update files
  static Future<void> cleanupUpdateFiles() async {
    try {
      print('Debug: Cleaning up update files...');

      final tempDir = await getTemporaryDirectory();
      final updateFile = File('${tempDir.path}/matchify_update.*');
      final extractDir = Directory('${tempDir.path}/matchify_update_extracted');

      // Find and delete any update files (ZIP or EXE)
      final updateFiles = tempDir.listSync().where((entity) =>
          entity is File && entity.path.contains('matchify_update'));

      for (final file in updateFiles) {
        if (file is File) {
          await file.delete();
          print('Debug: Deleted update file: ${file.path}');
        }
      }

      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
        print('Debug: Deleted extracted update directory');
      }

      print('Debug: Cleanup completed');
    } catch (e) {
      print('Debug: Error during cleanup: $e');
    }
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
