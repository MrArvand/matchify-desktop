import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/core/services/auto_update_service.dart';

class AutoUpdateState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final UpdateInfo? availableUpdate;
  final String? error;
  final bool isInstalling;
  final bool hasChecked;

  AutoUpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.availableUpdate,
    this.error,
    this.isInstalling = false,
    this.hasChecked = false,
  });

  AutoUpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    UpdateInfo? availableUpdate,
    String? error,
    bool? isInstalling,
    bool? hasChecked,
  }) {
    return AutoUpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      availableUpdate: availableUpdate ?? this.availableUpdate,
      error: error ?? this.error,
      isInstalling: isInstalling ?? this.isInstalling,
      hasChecked: hasChecked ?? this.hasChecked,
    );
  }
}

class AutoUpdateNotifier extends StateNotifier<AutoUpdateState> {
  AutoUpdateNotifier() : super(AutoUpdateState());

  /// Check for available updates
  Future<void> checkForUpdates() async {
    try {
      print('Debug: Starting update check in provider...');
      state = state.copyWith(isChecking: true, error: null);

      final updateInfo = await AutoUpdateService.checkForUpdates();
      print('Debug: Update check result: $updateInfo');
      
      state = state.copyWith(
        isChecking: false,
        availableUpdate: updateInfo,
        hasChecked: true,
      );
      
      if (updateInfo != null) {
        print('Debug: Update available: ${updateInfo.version}');
      } else {
        print('Debug: No update available');
      }
    } catch (e, stackTrace) {
      print('Error in checkForUpdates: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'خطا در بررسی به‌روزرسانی';
      
      if (e.toString().contains('null')) {
        errorMessage =
            'خطا در پردازش اطلاعات به‌روزرسانی - لطفاً دوباره تلاش کنید';
      } else if (e.toString().contains('NetworkException')) {
        errorMessage =
            'خطا در اتصال به اینترنت - لطفاً اتصال خود را بررسی کنید';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'خطا در اتصال به سرور - لطفاً دوباره تلاش کنید';
      } else if (e.toString().contains('Repository URLs not configured')) {
        errorMessage =
            'تنظیمات مخزن GitHub ناقص است. لطفاً آن را در auto_update_service.dart تنظیم کنید.';
      } else {
        errorMessage = 'خطا در بررسی به‌روزرسانی: $e';
      }
      
      state = state.copyWith(
        isChecking: false,
        error: errorMessage,
        hasChecked: true,
      );
    }
  }

  /// Download the available update
  Future<void> downloadUpdate() async {
    if (state.availableUpdate == null) return;

    try {
      state = state.copyWith(isDownloading: true, error: null);

      final updateFilePath = await AutoUpdateService.downloadUpdate(
        state.availableUpdate!,
        (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
      );

      if (updateFilePath != null) {
        // Download successful, proceed to install
        await _installUpdate(updateFilePath);
      } else {
        state = state.copyWith(
          isDownloading: false,
          error: 'خطا در دانلود به‌روزرسانی',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'خطا در دانلود به‌روزرسانی: $e',
      );
    }
  }

  /// Install the downloaded update
  Future<void> _installUpdate(String updateFilePath) async {
    try {
      state = state.copyWith(isInstalling: true, error: null);

      final success = await AutoUpdateService.installUpdate(updateFilePath);

      if (success) {
        // Update installation started successfully
        // Show a message that the app will restart
        state = state.copyWith(
          isInstalling: false,
          error:
              'به‌روزرسانی در حال نصب است. برنامه به زودی مجدداً راه‌اندازی خواهد شد.',
        );

        // Wait a moment for the user to see the message
        await Future.delayed(const Duration(seconds: 3));

        // For EXE installers, wait for the installer to start and then close the appfi
        if (updateFilePath.toLowerCase().endsWith('.exe')) {
          print('Debug: EXE installer launched, waiting for it to start...');

          // Wait a bit longer for the installer to fully start
          await Future.delayed(const Duration(seconds: 5));

          // Check if installer is still running
          final installerRunning = await AutoUpdateService.isInstallerRunning();
          if (installerRunning) {
            print('Debug: Installer is running, waiting for it to complete...');

            // Wait for installer to complete with timeout
            final completed =
                await AutoUpdateService.waitForInstallerCompletion(
                    timeoutSeconds: 30);
            if (completed) {
              print('Debug: Installer completed successfully, closing app');
            } else {
              print('Debug: Installer timeout, closing app anyway');
            }

            await AutoUpdateService.closeAppForUpdate();
          } else {
            print('Debug: Installer may have completed, closing app anyway');
            await AutoUpdateService.closeAppForUpdate();
          }
        } else {
          // For ZIP updates, close the app manually
          await AutoUpdateService.closeAppForUpdate();
        }
      } else {
        state = state.copyWith(
          isInstalling: false,
          error: 'خطا در نصب به‌روزرسانی',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isInstalling: false,
        error: 'خطا در نصب به‌روزرسانی: $e',
      );
    }
  }

  /// Open GitHub releases page
  Future<void> openReleasesPage() async {
    try {
      await AutoUpdateService.openReleasesPage();
    } catch (e) {
      state = state.copyWith(error: 'خطا در باز کردن صفحه انتشارات: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = AutoUpdateState();
  }
}

final autoUpdateProvider =
    StateNotifierProvider<AutoUpdateNotifier, AutoUpdateState>(
  (ref) => AutoUpdateNotifier(),
);
