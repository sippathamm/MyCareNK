import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../service/data/models/condom_request_model.dart';
import '../../../../../core/l10n/app_localizations.dart';

enum _ScanResultType {
  loading,
  preview,
  alreadyReceived,
  notReady,
  notYours,
  invalidQr,
  notLoggedIn,
  error,
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _torchOn = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();

    _showResultSheet(barcode.rawValue!);
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final result = await _controller.analyzeImage(image.path);
    if (!mounted) return;

    if (result == null || result.barcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.current.qrNotFoundInImage),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final rawValue = result.barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    _showResultSheet(rawValue);
  }

  void _showResultSheet(String value) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ScanResultSheet(
        payload: value,
        onRescan: () => Navigator.of(sheetContext).pop(),
        onSuccess: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).receiveSuccess,
                style: GoogleFonts.googleSans(),
              ),
              backgroundColor: AppColors.statusCompleted,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _hasScanned = false);
        _controller.start();
      }
    });
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScannerOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).scanTitle,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleTorch,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _torchOn
                            ? AppColors.primary
                            : AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).scanSubtitle,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).scanHint,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: AppColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).selectFromGallery,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  static const double _frameSize = 240;
  static const double _cornerLength = 28;
  static const double _cornerRadius = 8;
  static const double _cornerStroke = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2 - 40;

    final Rect frame = Rect.fromCenter(
      center: Offset(cx, cy),
      width: _frameSize,
      height: _frameSize,
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(_cornerRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    _drawCorners(canvas, frame, cornerPaint);
  }

  void _drawCorners(Canvas canvas, Rect frame, Paint paint) {
    final l = _cornerLength;
    final r = _cornerRadius;
    final left = frame.left;
    final top = frame.top;
    final right = frame.right;
    final bottom = frame.bottom;

    canvas.drawPath(
      Path()
        ..moveTo(left + r, top)
        ..lineTo(left + l, top)
        ..moveTo(left, top + r)
        ..lineTo(left, top + l),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(right - l, top)
        ..lineTo(right - r, top)
        ..moveTo(right, top + r)
        ..lineTo(right, top + l),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - l)
        ..lineTo(left, bottom - r)
        ..moveTo(left + r, bottom)
        ..lineTo(left + l, bottom),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - l)
        ..lineTo(right, bottom - r)
        ..moveTo(right - l, bottom)
        ..lineTo(right - r, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanResultSheet extends StatefulWidget {
  final String payload;
  final VoidCallback onRescan;
  final VoidCallback onSuccess;

  const _ScanResultSheet({
    required this.payload,
    required this.onRescan,
    required this.onSuccess,
  });

  @override
  State<_ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<_ScanResultSheet> {
  _ScanResultType _resultType = _ScanResultType.loading;
  CondomRequestModel? _requestData;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _processQrCode();
  }

  Future<void> _processQrCode() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) setState(() => _resultType = _ScanResultType.notLoggedIn);
      return;
    }

    String? ref;
    bool hasValidSignatureFormat = false;
    try {
      final map = jsonDecode(widget.payload) as Map<String, dynamic>;
      ref = (map['ref'] as String?)?.trim();
      final sig = (map['sig'] as String?)?.trim() ?? '';
      hasValidSignatureFormat =
          (ref?.isNotEmpty ?? false) && RegExp(r'^[0-9a-f]{64}$').hasMatch(sig);
    } catch (_) {}

    if (ref == null || ref.isEmpty) {
      if (mounted) setState(() => _resultType = _ScanResultType.invalidQr);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('condom_requests')
          .select()
          .eq('reference_number', ref)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(
          () => _resultType = hasValidSignatureFormat
              ? _ScanResultType.notYours
              : _ScanResultType.invalidQr,
        );
        return;
      }

      final request = CondomRequestModel.fromJson(response);

      if (request.status == RequestStatus.completed) {
        setState(() {
          _resultType = _ScanResultType.alreadyReceived;
          _requestData = request;
        });
        return;
      }

      if (request.status != RequestStatus.ready) {
        setState(() {
          _resultType = _ScanResultType.notReady;
          _requestData = request;
        });
        return;
      }

      setState(() {
        _resultType = _ScanResultType.preview;
        _requestData = request;
      });
    } catch (e) {
      String msg = e.toString();
      try {
        msg = (e as dynamic).message as String? ?? e.toString();
      } catch (_) {}
      debugPrint('[QR Scanner] processQrCode: $msg');
      if (mounted) setState(() => _resultType = _ScanResultType.error);
    }
  }

  Future<void> _confirmReceive() async {
    setState(() => _isConfirming = true);

    try {
      await Supabase.instance.client.functions.invoke(
        'verify-receive',
        body: {'payload': widget.payload},
      );

      if (!mounted) return;
      setState(() => _isConfirming = false);
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;

      int httpStatus = 500;
      String responseMessage = e.toString();
      try {
        httpStatus = (e as dynamic).status as int? ?? 500;
        final details = (e as dynamic).details;
        if (details is Map<String, dynamic>) {
          responseMessage = details['message'] as String? ?? e.toString();
        }
      } catch (_) {}

      debugPrint('[QR Scanner] verify-receive: $responseMessage');

      if (httpStatus == 409) {
        await _refetchForAlreadyReceived();
        return;
      }

      setState(() {
        _isConfirming = false;
        switch (httpStatus) {
          case 400:
          case 404:
            _resultType = _ScanResultType.invalidQr;
            break;
          case 401:
            _resultType = _ScanResultType.notLoggedIn;
            break;
          case 403:
            _resultType = _ScanResultType.notYours;
            break;
          default:
            _resultType = _ScanResultType.error;
        }
      });
    }
  }

  Future<void> _refetchForAlreadyReceived() async {
    try {
      if (_requestData != null) {
        final response = await Supabase.instance.client
            .from('condom_requests')
            .select()
            .eq('id', _requestData!.id)
            .maybeSingle();

        if (!mounted) return;

        if (response != null) {
          _requestData = CondomRequestModel.fromJson(response);
        }
      }
    } catch (e) {
      String msg = e.toString();
      try {
        msg = (e as dynamic).message as String? ?? e.toString();
      } catch (_) {}
      debugPrint('[QR Scanner] refetch: $msg');
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
          _resultType = _ScanResultType.alreadyReceived;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreview = _resultType == _ScanResultType.preview;

    final handleBar = Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    if (isPreview) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: handleBar,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: _buildPreview(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [handleBar, _buildContent(context)],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_resultType) {
      case _ScanResultType.loading:
        return _buildLoading();
      case _ScanResultType.alreadyReceived:
        return _buildAlreadyReceived();
      case _ScanResultType.notReady:
        return _buildNotReady();
      case _ScanResultType.notYours:
        return _buildNotYours();
      case _ScanResultType.invalidQr:
        return _buildInvalidQr();
      case _ScanResultType.notLoggedIn:
        return _buildNotLoggedIn(context);
      case _ScanResultType.error:
        return _buildError();
      case _ScanResultType.preview:
        return const SizedBox();
    }
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).scanChecking,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final request = _requestData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewHeader(request),
        const SizedBox(height: 24),
        _buildStatusTracker(request),
        const SizedBox(height: 32),
        _buildQuantityCard(request),
        _buildLubricantCard(request),
        _buildLocationCard(request),
        _buildMessageCard(request),
        const SizedBox(height: 32),
        GradientButton(
          height: 52,
          onPressed: _isConfirming ? null : _confirmReceive,
          label: AppLocalizations.of(context).confirmReceive,
          isLoading: _isConfirming,
          gradientColors: GradientButton.completedGradient,
        ),
      ],
    );
  }

  Widget _buildPreviewHeader(CondomRequestModel request) {
    final dt = request.updatedAt.toUtc().add(const Duration(hours: 7));
    final dateStr =
        '${dt.day} ${_monthTH(dt.month)} ${dt.year + 543}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).referenceNumber,
              style: GoogleFonts.googleSans(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              request.referenceNumber,
              style: GoogleFonts.googleSans(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.statusReadyLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.statusReady,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.googleSans(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTracker(CondomRequestModel request) {
    final steps = [
      (label: AppLocalizations.of(context).statusPending, status: RequestStatus.pending,   color: AppColors.primary),
      (label: AppLocalizations.of(context).statusPreparing, status: RequestStatus.preparing,  color: AppColors.statusPreparing),
      (label: AppLocalizations.of(context).statusReady, status: RequestStatus.ready,      color: AppColors.statusReady),
      (label: AppLocalizations.of(context).statusCompleted, status: RequestStatus.completed,  color: AppColors.statusCompleted),
    ];
    final currentIdx = steps.indexWhere((s) => s.status == request.status);
    const double nodeSize = 28;
    const double gap = 6;
    final n = steps.length;

    final iconItems = <Widget>[];
    for (int idx = 0; idx < n; idx++) {
      final step = steps[idx];
      final isDone = idx < currentIdx;
      final isCurrent = idx == currentIdx;
      final isLast = idx == n - 1;
      final showCheck = isDone || (isCurrent && isLast);
      iconItems.add(AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: nodeSize, height: nodeSize,
        decoration: BoxDecoration(
          color: (isDone || isCurrent) ? step.color : const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: showCheck
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text('${idx + 1}',
                  style: GoogleFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (isDone || isCurrent) ? Colors.white : AppColors.textMuted)),
        ),
      ));
      if (!isLast) {
        iconItems.addAll([
          const SizedBox(width: gap),
          Expanded(child: Container(height: 3, decoration: BoxDecoration(color: isDone ? step.color : const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(width: gap),
        ]);
      }
    }

    return Column(children: [
      Row(children: iconItems),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (context, constraints) {
        final W = constraints.maxWidth;
        final slotSpacing = (W - nodeSize) / (n - 1);
        TextStyle labelStyle(int idx) {
          final isDone = idx < currentIdx;
          final isCurrent = idx == currentIdx;
          return GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? steps[idx].color : isDone ? AppColors.textSecondary : AppColors.textMuted,
          );
        }
        return SizedBox(
          height: 16,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 0, top: 0, child: Text(steps[0].label, style: labelStyle(0))),
            Positioned(right: 0, top: 0, child: Text(steps[n - 1].label, style: labelStyle(n - 1))),
            for (int i = 1; i < n - 1; i++)
              Positioned(
                left: nodeSize / 2 + i * slotSpacing,
                top: 0,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: Text(steps[i].label, style: labelStyle(i)),
                ),
              ),
          ]),
        );
      }),
    ]);
  }

  Widget _buildQuantityCard(CondomRequestModel request) {
    final total = request.condomQuantities.values.fold(0, (s, v) => s + v);
    if (total == 0) return const SizedBox();

    return _card(
      header: Row(children: [
        const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('ถุงยางอนามัย',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          ...request.condomQuantities.entries
              .where((e) => e.value > 0)
              .map((e) => _infoRow('ขนาด ${e.key} มม.', '${e.value} ชิ้น')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รวม',
                  style: GoogleFonts.googleSans(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('$total ชิ้น',
                  style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard(CondomRequestModel request) {
    if (request.lubricantQuantity == 0) return const SizedBox();

    return _card(
      header: Row(children: [
        const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('เพิ่มเติม',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: _infoRow('เจลหล่อลื่น', '${request.lubricantQuantity} ชิ้น'),
    );
  }

  Widget _buildLocationCard(CondomRequestModel request) {
    String outputDate = request.selectedDate ?? '-';
    if (request.selectedDate != null && request.selectedDate!.contains('-')) {
      try {
        final d = DateTime.parse(request.selectedDate!);
        outputDate = '${d.day} ${_monthTH(d.month)} ${d.year + 543}';
      } catch (_) {}
    }

    String outputTime = '-';
    if (request.selectedTime != null && request.selectedTime!.contains(':')) {
      final parts = request.selectedTime!.split(':');
      if (parts.length >= 2) outputTime = '${parts[0]}:${parts[1]} น.';
    }

    return _card(
      header: Row(children: [
        const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('สถานบริการ วันที่และเวลารับ',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          _infoRow('สถานบริการ', request.selectedServiceCenter ?? '-'),
          _infoRow('วันที่', outputDate),
          _infoRow('เวลา', outputTime),
        ],
      ),
    );
  }

  Widget _buildMessageCard(CondomRequestModel request) {
    if (request.message.isEmpty) return const SizedBox();

    return _card(
      header: Row(children: [
        const Icon(Icons.comment_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('ฝากข้อความ',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(request.message,
            style: GoogleFonts.googleSans(
                fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.googleSans(
                    fontSize: 14, color: AppColors.textSecondary)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.googleSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    ),
  );

  Widget _card({
    required Widget header,
    required Widget content,
    bool showDivider = false,
    Widget? footer,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowMedium,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: header,
            ),
            Padding(padding: const EdgeInsets.all(16), child: content),
            if (showDivider) const Divider(height: 1),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyReceived() {
    String receivedAt = '-';
    String refNumber = '-';

    if (_requestData != null) {
      final dt = _requestData!.updatedAt.toUtc().add(const Duration(hours: 7));
      receivedAt =
          '${dt.day} ${_monthTH(dt.month)} ${dt.year + 543} เวลา ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
      refNumber = _requestData!.referenceNumber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(
          icon: Icons.block_outlined,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: AppLocalizations.of(context).cannotReceiveTitle,
        ),
        const SizedBox(height: 12),
        Text(
          'คุณรับถุงยางอนามัยคำขอนี้ไปแล้ว เมื่อ $receivedAt',
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'รหัสอ้างอิง: $refNumber',
          style: GoogleFonts.googleSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _rescanButton(),
      ],
    );
  }

  Widget _buildNotReady() {
    String chipLabel = '-';
    Color chipColor = Colors.grey[600]!;
    if (_requestData != null) {
      switch (_requestData!.status) {
        case RequestStatus.pending:
          chipLabel = AppLocalizations.of(context).statusPending;
          chipColor = AppColors.primary;
          break;
        case RequestStatus.preparing:
          chipLabel = AppLocalizations.of(context).statusPreparing;
          chipColor = AppColors.statusPreparing;
          break;
        case RequestStatus.cancelledByUser:
          chipLabel = AppLocalizations.of(context).statusCancelledByUser;
          chipColor = Colors.grey[600]!;
          break;
        case RequestStatus.cancelledByStaff:
          chipLabel = AppLocalizations.of(context).statusCancelledByStaff;
          chipColor = Colors.grey[600]!;
          break;
        default:
          break;
      }
    }

    final textStyle = GoogleFonts.googleSans(
      fontSize: 14,
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(
          icon: Icons.warning_amber_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryShadow,
          title: AppLocalizations.of(context).notReadyTitle,
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(AppLocalizations.of(context).notReadyMsg1, style: textStyle),
            _statusChip(chipLabel, chipColor),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            Text(AppLocalizations.of(context).notReadyMsg2, style: textStyle),
            _statusChip('พร้อมรับ', AppColors.statusReady),
            Text(AppLocalizations.of(context).notReadyMsg3, style: textStyle),
          ],
        ),
        if (_requestData != null) ...[
          const SizedBox(height: 6),
          Text(
            'รหัสอ้างอิง: ${_requestData!.referenceNumber}',
            style: GoogleFonts.googleSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _rescanButton(),
      ],
    );
  }

  Widget _buildNotYours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(
          icon: Icons.block_outlined,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: 'QR Code ไม่ใช่ของคุณ',
        ),
        const SizedBox(height: 12),
        Text(
          'QR Code นี้เป็นของผู้ใช้งานท่านอื่น ไม่สามารถใช้งานได้',
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _rescanButton(),
      ],
    );
  }

  Widget _buildInvalidQr() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(
          icon: Icons.qr_code_outlined,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: 'QR Code ไม่ถูกต้อง',
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).notYoursMsg,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _rescanButton(),
      ],
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(
          icon: Icons.lock_outline,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: AppLocalizations.of(context).pleaseLogin,
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).notLoggedInScan,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          height: 48,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final rootNav = Navigator.of(context, rootNavigator: true);
            Navigator.of(context).pop();
            final loggedIn = await rootNav
                .push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
            if (loggedIn == true) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.current.loggedIn,
                      style: GoogleFonts.googleSans()),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          label: AppLocalizations.of(context).loginBtn,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: AppLocalizations.of(context).errorOccurredTitle,
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).qrError,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _rescanButton(),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.googleSans(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.googleSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _rescanButton() {
    return GradientButton(
      height: 48,
      onPressed: widget.onRescan,
      label: AppLocalizations.of(context).scanAgain,
    );
  }

  String _monthTH(int month) {
    const months = [
      '',
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}
