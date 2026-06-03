import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  static final _supabase = Supabase.instance.client;

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
  // -preview → 'preview'; -dev → 'dev' (no rows → no update); no suffix → 'main'.
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

      // Semver equal on preview builds → fall back to build number.
      if (info.version.contains('-')) {
        final localBuild = int.tryParse(info.buildNumber) ?? 0;
        return remote.buildNumber > localBuild;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Downloads the APK to the app's external downloads dir with progress.
  // Returns the local file path on success. Pass cancelToken to support cancellation.
  Future<String> downloadApk(
    String url,
    void Function(double progress) onProgress, {
    CancelToken? cancelToken,
  }) async {
    final dir = await getExternalStorageDirectory();
    final downloadDir = Directory('${dir!.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    final savePath = '${downloadDir.path}/MyCareNK_update.apk';

    final dio = Dio();
    await dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    return savePath;
  }

  Future<OpenResult> openApk(String filePath) async {
    return OpenFile.open(filePath);
  }
}
