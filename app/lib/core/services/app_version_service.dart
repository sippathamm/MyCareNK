import 'dart:async';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppVersionInfo {
  final int id;
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String? releaseNotes;
  final bool forceUpdate;
  final String branch;

  const AppVersionInfo({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.releaseNotes,
    required this.forceUpdate,
    required this.branch,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    return AppVersionInfo(
      id: map['id'] as int,
      version: map['version'] as String,
      buildNumber: map['build_number'] as int,
      downloadUrl: map['download_url'] as String,
      releaseNotes: map['release_notes'] as String?,
      forceUpdate: map['force_update'] as bool,
      branch: map['branch'] as String,
    );
  }
}

class AppVersionService {
  static const _channel = MethodChannel('com.sippathamm.mycarenk/download');
  static final _supabase = Supabase.instance.client;

  // Mirrors Android DownloadManager status constants
  static const int statusPending = 1;
  static const int statusRunning = 2;
  static const int statusPaused = 4;
  static const int statusSuccessful = 8;
  static const int statusFailed = 16;

  // Strips pre-release suffix and returns [major, minor, patch].
  static List<int> _parseSemver(String version) {
    final clean = version.split('-').first;
    final parts = clean.split('.');
    return [
      int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(2) ?? '0') ?? 0,
    ];
  }

  // Returns >0 if a > b, 0 if equal, <0 if a < b.
  static int _compareVersions(String a, String b) {
    final va = _parseSemver(a);
    final vb = _parseSemver(b);
    for (int i = 0; i < 3; i++) {
      if (va[i] != vb[i]) return va[i] - vb[i];
    }
    return 0;
  }

  // Detects which branch to query based on the local version string.
  static String _detectBranch(String localVersion) {
    if (localVersion.contains('-preview')) return 'preview';
    if (localVersion.contains('-dev')) return 'dev';
    return 'main';
  }

  Future<AppVersionInfo?> getLatestVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final branch = _detectBranch(info.version);
      final rows = await _supabase.rpc(
        'get_latest_app_version',
        params: {'p_branch': branch},
      );
      if (rows == null || (rows as List).isEmpty) return null;
      return AppVersionInfo.fromMap(rows.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isUpdateAvailable() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final remote = await getLatestVersion();
      if (remote == null) return false;
      final semverCmp = _compareVersions(remote.version, info.version);
      if (semverCmp != 0) return semverCmp > 0;
      if (info.version.contains('-')) {
        final localBuild = int.tryParse(info.buildNumber) ?? 0;
        return remote.buildNumber > localBuild;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Enqueues the APK download via system DownloadManager.
  // Returns the DownloadManager download ID for progress tracking.
  Future<int> startDownload(String url) async {
    final id = await _channel.invokeMethod<int>('downloadApk', {
      'url': url,
      'fileName': 'MyCareNK_update.apk',
    });
    return id!;
  }

  // Polls the current progress of a download. Returns status, downloaded
  // bytes, and total bytes (all as int).
  Future<Map<String, int>> getDownloadProgress(int downloadId) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getDownloadProgress',
      {'downloadId': downloadId},
    );
    final map = result!;
    return {
      'status': (map['status'] as num).toInt(),
      'downloaded': (map['downloaded'] as num).toInt(),
      'total': (map['total'] as num).toInt(),
    };
  }

  Future<void> cancelDownload(int downloadId) async {
    await _channel.invokeMethod<void>('cancelDownload', {'downloadId': downloadId});
  }

  // Opens the system Downloads app so the user can tap the APK to install.
  Future<void> openDownloadsFolder() async {
    await _channel.invokeMethod<void>('openDownloadsFolder');
  }
}
