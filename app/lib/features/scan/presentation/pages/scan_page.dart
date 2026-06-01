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
import '../widgets/scan_overlay.dart';
import '../widgets/scan_result_widgets.dart';

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
          backgroundColor: AppColors.error,
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
              backgroundColor: AppColors.success,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              final cy = constraints.maxHeight / 2 - 40;
              final scanWindow = Rect.fromCenter(
                center: Offset(cx, cy),
                width: kScanFrameSize,
                height: kScanFrameSize,
              );
              return MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                scanWindow: scanWindow,
              );
            },
          ),
          const ScannerOverlay(),
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
    } catch (_) {
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
      try {
        httpStatus = (e as dynamic).status as int? ?? 500;
      } catch (_) {}

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
    } catch (_) {
      // Already-received state is set in the finally block.
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
        ScanPreviewHeader(request: request),
        const SizedBox(height: 24),
        ScanStatusTracker(request: request),
        const SizedBox(height: 32),
        ScanQuantityCard(request: request),
        ScanLubricantCard(request: request),
        ScanLocationCard(request: request),
        ScanMessageCard(request: request),
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

  Widget _buildAlreadyReceived() {
    final l10n = AppLocalizations.of(context);
    String receivedAt = '-';
    String refNumber = '-';

    if (_requestData != null) {
      final dt = _requestData!.updatedAt.toUtc().add(const Duration(hours: 7));
      receivedAt =
          '${dt.day} ${l10n.monthsFull[dt.month - 1]} ${dt.year + 543} ${l10n.timeLabel} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${l10n.timeWithUnit}';
      refNumber = _requestData!.referenceNumber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ScanSheetHeader(
          icon: Icons.block_outlined,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: l10n.cannotReceiveTitle,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.alreadyReceivedMsg(receivedAt),
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.referencePrefix(refNumber),
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
        ScanSheetHeader(
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
            ScanStatusChip(label: chipLabel, color: chipColor),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            Text(AppLocalizations.of(context).notReadyMsg2, style: textStyle),
            ScanStatusChip(label: AppLocalizations.of(context).statusReady, color: AppColors.statusReady),
            Text(AppLocalizations.of(context).notReadyMsg3, style: textStyle),
          ],
        ),
        if (_requestData != null) ...[
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).referencePrefix(_requestData!.referenceNumber),
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
        ScanSheetHeader(
          icon: Icons.block_outlined,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: AppLocalizations.of(context).qrNotYoursTitle,
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).qrNotYoursBody,
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
        ScanSheetHeader(
          icon: Icons.qr_code_outlined,
          iconColor: AppColors.error,
          iconBgColor: AppColors.errorShadow,
          title: AppLocalizations.of(context).qrInvalidTitle,
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
        ScanSheetHeader(
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
        ScanSheetHeader(
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

  Widget _rescanButton() {
    return GradientButton(
      height: 48,
      onPressed: widget.onRescan,
      label: AppLocalizations.of(context).scanAgain,
    );
  }

}
