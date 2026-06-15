import 'dart:async';

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
  String _currentVersion = '';
  int? _downloadId;
  Timer? _pollTimer;

  final _service = AppVersionService();

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
      final id = await _service.startDownload(widget.versionInfo.downloadUrl);
      _downloadId = id;
      _startPolling(id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = 'ดาวน์โหลดล้มเหลว กรุณาลองใหม่';
        });
      }
    }
  }

  void _startPolling(int downloadId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final progress = await _service.getDownloadProgress(downloadId);
        if (!mounted) return;
        final status = progress['status']!;
        if (status == AppVersionService.statusSuccessful) {
          _pollTimer?.cancel();
          setState(() => _state = _DownloadState.downloaded);
        } else if (status == AppVersionService.statusFailed) {
          _pollTimer?.cancel();
          setState(() {
            _state = _DownloadState.error;
            _errorMessage = 'ดาวน์โหลดล้มเหลว กรุณาลองใหม่';
          });
        } else {
          final total = progress['total']!;
          final downloaded = progress['downloaded']!;
          if (total > 0) setState(() => _progress = downloaded / total);
        }
      } catch (_) {
        // ignore transient poll errors
      }
    });
  }

  void _cancelDownload() {
    _pollTimer?.cancel();
    if (_downloadId != null) {
      _service.cancelDownload(_downloadId!);
      _downloadId = null;
    }
    setState(() => _state = _DownloadState.idle);
  }

  Future<void> _openDownloadsFolder() async {
    try {
      await _service.openDownloadsFolder();
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = 'ไม่สามารถเปิดโฟลเดอร์ดาวน์โหลดได้';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final force = widget.versionInfo.forceUpdate;
    final canDismiss = !force && _state != _DownloadState.downloading;

    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.success,
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
            if (widget.versionInfo.hasNotes) ...[
              const SizedBox(height: 12),
              _ReleaseNotes(versionInfo: widget.versionInfo),
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
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ดาวน์โหลดเสร็จสิ้น กด "ติดตั้ง" เพื่อเปิดโฟลเดอร์ดาวน์โหลด',
                        style: GoogleFonts.googleSans(
                          fontSize: 15,
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
                          fontSize: 15,
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
          if (_state == _DownloadState.downloading)
            TextButton(
              onPressed: _cancelDownload,
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.googleSans(color: AppColors.textSecondary),
              ),
            )
          else if (!force)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ภายหลัง',
                style: GoogleFonts.googleSans(color: AppColors.textSecondary),
              ),
            ),
          if (_state == _DownloadState.downloaded)
            TextButton(
              onPressed: _openDownloadsFolder,
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

class _ReleaseNotes extends StatelessWidget {
  final AppVersionInfo versionInfo;

  const _ReleaseNotes({required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (versionInfo.additions.isNotEmpty)
            _NoteSection(
              label: 'เพิ่ม',
              color: AppColors.success,
              items: versionInfo.additions,
            ),
          if (versionInfo.fixes.isNotEmpty)
            _NoteSection(
              label: 'แก้ไข',
              color: AppColors.error,
              items: versionInfo.fixes,
              topSpacing: versionInfo.additions.isNotEmpty,
            ),
          if (versionInfo.improvements.isNotEmpty)
            _NoteSection(
              label: 'ปรับปรุง',
              color: AppColors.primary,
              items: versionInfo.improvements,
              topSpacing: versionInfo.additions.isNotEmpty || versionInfo.fixes.isNotEmpty,
            ),
          if (versionInfo.others.isNotEmpty)
            _NoteSection(
              label: 'อื่น ๆ',
              color: AppColors.textSecondary,
              items: versionInfo.others,
              topSpacing: versionInfo.additions.isNotEmpty ||
                  versionInfo.fixes.isNotEmpty ||
                  versionInfo.improvements.isNotEmpty,
            ),
        ],
      ),
    );
  }
}

class _NoteSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;
  final bool topSpacing;

  const _NoteSection({
    required this.label,
    required this.color,
    required this.items,
    this.topSpacing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topSpacing) const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.googleSans(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
