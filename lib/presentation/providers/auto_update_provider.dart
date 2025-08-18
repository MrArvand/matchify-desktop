import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/core/services/auto_update_service.dart';

class AutoUpdateState {
  final bool isChecking;
  final bool hasUpdate;
  final UpdateInfo? updateInfo;
  final bool isDownloading;
  final double downloadProgress;
  final String? error;
  final String currentVersion;

  AutoUpdateState({
    this.isChecking = false,
    this.hasUpdate = false,
    this.updateInfo,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.error,
    this.currentVersion = '',
  });

  AutoUpdateState copyWith({
    bool? isChecking,
    bool? hasUpdate,
    UpdateInfo? updateInfo,
    bool? isDownloading,
    double? downloadProgress,
    String? error,
    String? currentVersion,
  }) {
    return AutoUpdateState(
      isChecking: isChecking ?? this.isChecking,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      updateInfo: updateInfo ?? this.updateInfo,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

class AutoUpdateNotifier extends StateNotifier<AutoUpdateState> {
  AutoUpdateNotifier() : super(AutoUpdateState()) {
    _initializeVersion();
  }

  Future<void> _initializeVersion() async {
    final version = await AutoUpdateService.getCurrentVersion();
    state = state.copyWith(currentVersion: version);
  }

  /// Check for available updates
  Future<void> checkForUpdates() async {
    state = state.copyWith(isChecking: true, error: null);

    try {
      final updateInfo = await AutoUpdateService.checkForUpdates();

      if (updateInfo != null) {
        state = state.copyWith(
          isChecking: false,
          hasUpdate: updateInfo.isAvailable,
          updateInfo: updateInfo,
        );
      } else {
        state = state.copyWith(
          isChecking: false,
          error: 'خطا در بررسی به‌روزرسانی',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: 'خطا در بررسی به‌روزرسانی: $e',
      );
    }
  }

  /// Download and install the update
  Future<void> downloadAndInstallUpdate() async {
    if (state.updateInfo == null || !state.hasUpdate) return;

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      error: null,
    );

    try {
      // Simulate download progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(downloadProgress: i / 100);
      }

      // Download and install the update
      final success = await AutoUpdateService.downloadAndInstallUpdate(
        state.updateInfo!.downloadUrl,
      );

      if (success) {
        state = state.copyWith(
          isDownloading: false,
          downloadProgress: 1.0,
        );
        // The app will restart after installation
      } else {
        state = state.copyWith(
          isDownloading: false,
          error: 'خطا در نصب به‌روزرسانی',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'خطا در دانلود به‌روزرسانی: $e',
      );
    }
  }

  /// Clear any errors
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset the update state
  void reset() {
    state = AutoUpdateState();
    _initializeVersion();
  }
}

final autoUpdateProvider =
    StateNotifierProvider<AutoUpdateNotifier, AutoUpdateState>(
  (ref) => AutoUpdateNotifier(),
);
