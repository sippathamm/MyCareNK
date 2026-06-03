import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_version_service.dart';

class UpdateDialog extends StatefulWidget {
  final AppVersionInfo versionInfo;

  const UpdateDialog({super.key, required this.versionInfo});

  static Future<void> show(
    BuildContext context,
    AppVersionInfo versionInfo,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(versionInfo: versionInfo),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _DownloadState { idle, downloading, downloaded, error }

class _UpdateDialogState extends State<UpdateDialog> {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0;
  String? _errorMessage;
  String? _localPath;
  String _currentVersion = '';

  final _service = AppVersionService();

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _currentVersion = info.version);
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      final path = await _service.downloadApk(
        widget.versionInfo.downloadUrl,
        (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      _localPath = path;
      if (mounted) setState(() => _state = _DownloadState.downloaded);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = 'ดาวน์โหลดล้มเหลว กรุณาลองใหม่';
        });
      }
    }
  }

  Future<void> _openInstaller() async {
    if (_localPath == null) return;
    await _service.openApk(_localPath!);
  }

  @override
  Widget build(BuildContext context) {
    final force = widget.versionInfo.forceUpdate;

    return PopScope(
      canPop: !force && _state != _DownloadState.downloading || _state == _DownloadState.downloaded,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'มีเวอร์ชันใหม่!',
              style: GoogleFonts.googleSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentVersion.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      'v$_currentVersion',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.googleSans(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    'v${widget.versionInfo.version}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.versionInfo.releaseNotes != null &&
                widget.versionInfo.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  widget.versionInfo.releaseNotes!,
                  style: GoogleFonts.googleSans(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_state == _DownloadState.downloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กำลังดาวน์โหลด ${(_progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.googleSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (_state == _DownloadState.downloaded) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ดาวน์โหลดเสร็จสิ้น พร้อมติดตั้ง',
                        style: GoogleFonts.googleSans(
                          fontSize: 13,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (_state == _DownloadState.error) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage ?? 'เกิดข้อผิดพลาด',
                        style: GoogleFonts.googleSans(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
        actions: [
          if (!force && _state != _DownloadState.downloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ภายหลัง',
                style: GoogleFonts.googleSans(color: AppColors.textSecondary),
              ),
            ),
          if (_state == _DownloadState.downloaded)
            TextButton(
              onPressed: _openInstaller,
              child: Text(
                'ติดตั้ง',
                style: GoogleFonts.googleSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _state == _DownloadState.downloading ? null : _startDownload,
              child: Text(
                _state == _DownloadState.error ? 'ลองใหม่' : 'อัปเดต',
                style: GoogleFonts.googleSans(
                  color: _state == _DownloadState.downloading
                      ? AppColors.textMuted
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
