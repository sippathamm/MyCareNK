import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/condom_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/gradient_button.dart';

class RequestHistoryDetailPage extends StatefulWidget {
  final CondomRequestModel data;

  const RequestHistoryDetailPage({super.key, required this.data});

  @override
  State<RequestHistoryDetailPage> createState() => _RequestHistoryDetailPageState();
}

class _RequestHistoryDetailPageState extends State<RequestHistoryDetailPage> {
  bool _isCancelling = false;
  late CondomRequestModel _currentData;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _currentData = widget.data;
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await Supabase.instance.client
          .from('condom_requests')
          .select()
          .eq('id', _currentData.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentData = CondomRequestModel.fromJson(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _setupRealtime() {
    _subscription = Supabase.instance.client
        .channel('public:condom_requests:${_currentData.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'condom_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentData.id,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchData();
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'รายละเอียดคำขอ',
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderId(context),
                const SizedBox(height: 24),
                _buildStatusTracker(),
                const SizedBox(height: 32),
                _buildQuantityCard(),
                _buildLubricantCard(),
                _buildLocationCard(),
                _buildMessageCard(),
                _buildCancelReasonCard(),
                const SizedBox(height: 48),
                _buildBottomButtons(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderId(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    if (_currentData.status.isCancelled) {
      icon = Icons.cancel_outlined;
      iconColor = Colors.grey[600]!;
      iconBgColor = Colors.grey[200]!;
    } else {
      switch (_currentData.status) {
        case RequestStatus.pending:
          icon = Icons.assignment_outlined;
          iconColor = AppColors.primary;
          iconBgColor = AppColors.statusPendingLight;
          break;
        case RequestStatus.preparing:
          icon = Icons.inventory_2_outlined;
          iconColor = AppColors.lubricant;
          iconBgColor = AppColors.statusPreparingLight;
          break;
        case RequestStatus.ready:
          icon = Icons.local_shipping_outlined;
          iconColor = AppColors.statusReady;
          iconBgColor = AppColors.statusReadyLight;
          break;
        case RequestStatus.completed:
          icon = Icons.check_circle_outline;
          iconColor = AppColors.statusCompleted;
          iconBgColor = AppColors.statusCompletedLight;
          break;
        default:
          icon = Icons.assignment_outlined;
          iconColor = AppColors.primary;
          iconBgColor = AppColors.statusPendingLight;
      }
    }

    // Format Date
    final formattedDate = _currentData.updatedAt.toUtc().add(const Duration(hours: 7));
    String dateStr = '${formattedDate.day} ${formatMonthTH(formattedDate.month)} ${formattedDate.year + 543} ${formattedDate.hour.toString().padLeft(2, '0')}:${formattedDate.minute.toString().padLeft(2, '0')} น.';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รหัสอ้างอิง',
              style: GoogleFonts.googleSans(color: Colors.grey[500], fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  _currentData.referenceNumber,
                  style: GoogleFonts.googleSans(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentData.referenceNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'คัดลอกรหัสอ้างอิงแล้ว',
                          style: GoogleFonts.googleSans(),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
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

  Widget _buildStatusTracker() {
    final status = _currentData.status;

    if (status.isCancelled) {
      const cancelLabel = 'ยกเลิก';
      return Row(
        children: [
          _buildStepNode(
            color: AppColors.primary,
            icon: Icons.check,
            label: 'รอดำเนินการ',
            isCurrent: false,
            isDone: true,
          ),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildStepNode(
            color: Colors.grey,
            icon: Icons.close,
            label: cancelLabel,
            isCurrent: true,
            isDone: false,
            labelColor: Colors.grey[600],
          ),
        ],
      );
    }

    final steps = [
      (label: 'รอดำเนินการ', status: RequestStatus.pending,   color: AppColors.primary),
      (label: 'กำลังเตรียม', status: RequestStatus.preparing,  color: AppColors.statusPreparing),
      (label: 'พร้อมรับ',    status: RequestStatus.ready,      color: AppColors.statusReady),
      (label: 'เสร็จสิ้น',   status: RequestStatus.completed,  color: AppColors.statusCompleted),
    ];
    final currentIdx = steps.indexWhere((s) => s.status == status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftIdx = i ~/ 2;
          final done = leftIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: done ? steps[leftIdx].color : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final idx = i ~/ 2;
        final isDone = idx < currentIdx;
        final isCurrent = idx == currentIdx;
        return _buildStepNode(
          color: (isDone || isCurrent) ? steps[idx].color : const Color(0xFFE8E8E8),
          icon: isDone ? Icons.check : null,
          label: steps[idx].label,
          number: isDone ? null : idx + 1,
          isCurrent: isCurrent,
          isDone: isDone,
          labelColor: isCurrent
              ? steps[idx].color
              : isDone
                  ? AppColors.textSecondary
                  : AppColors.textMuted,
        );
      }),
    );
  }

  Widget _buildStepNode({
    required Color color,
    IconData? icon,
    int? number,
    required String label,
    required bool isCurrent,
    required bool isDone,
    Color? labelColor,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 14)
                : Text(
                    '${number ?? ''}',
                    style: GoogleFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (isCurrent || isDone)
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: labelColor ?? AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required Widget header,
    required Widget content,
    bool showDivider = false,
    Widget? footer,
    List<Color>? headerColors,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors ?? [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: header,
            ),
            Padding(padding: const EdgeInsets.all(16.0), child: content),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
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
  }

  Widget _buildQuantityCard() {
    int totalCondoms = _currentData.condomQuantities.values.fold(0, (sum, val) => sum + val);
    if (totalCondoms == 0) return const SizedBox();

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('ถุงยางอนามัย',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          ..._currentData.condomQuantities.entries
              .where((e) => e.value > 0)
              .map((e) => _buildInfoRow('ขนาด ${e.key} มม.', '${e.value} ชิ้น')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รวม',
                  style: GoogleFonts.googleSans(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '$totalCondoms ชิ้น',
                style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard() {
    if (_currentData.lubricantQuantity == 0) return const SizedBox();

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('เพิ่มเติม',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: _buildInfoRow('เจลหล่อลื่น', '${_currentData.lubricantQuantity} ชิ้น'),
    );
  }

  Widget _buildLocationCard() {
    String outputDate = _currentData.selectedDate ?? '-';
    if (_currentData.selectedDate != null && _currentData.selectedDate!.contains('-')) {
      try {
        DateTime parsedDate = DateTime.parse(_currentData.selectedDate!);
        outputDate = '${parsedDate.day} ${formatMonthTH(parsedDate.month)} ${parsedDate.year + 543}';
      } catch (e) {
        outputDate = _currentData.selectedDate!;
      }
    }

    String outputTime = _currentData.selectedTime ?? '-';
    if (_currentData.selectedTime != null && _currentData.selectedTime!.contains(':')) {
      final splitted = _currentData.selectedTime!.split(':');
      if (splitted.length >= 2) {
        outputTime = '${splitted[0]}:${splitted[1]} น.';
      }
    }

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('สถานบริการ วันที่และเวลารับ',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          _buildInfoRow('สถานบริการ', _currentData.selectedServiceCenter ?? '-'),
          _buildInfoRow('วันที่', outputDate),
          _buildInfoRow('เวลา', outputTime),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    if (_currentData.message.isEmpty) return const SizedBox();

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.comment_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('ฝากข้อความ',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentData.message,
          style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildCancelReasonCard() {
    if (_currentData.status != RequestStatus.cancelledByStaff) return const SizedBox();
    if (_currentData.cancelReason == null || _currentData.cancelReason!.isEmpty) return const SizedBox();

    return _buildCard(
      headerColors: [AppColors.errorDark, AppColors.error],
      header: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('เหตุผลที่ยกเลิก',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentData.cancelReason!,
          style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Future<void> _doCancelRequest() async {
    setState(() => _isCancelling = true);
    try {
      await Supabase.instance.client
          .from('condom_requests')
          .update({'request_status': 'cancelled_by_user'})
          .eq('id', _currentData.id);

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final userId = session.user.id;
        final createdAt = _currentData.createdAt.toLocal();
        final monthStart = DateTime(createdAt.year, createdAt.month, 1)
            .toIso8601String()
            .substring(0, 10);

        final existingQuota = await Supabase.instance.client
            .from('user_monthly_quotas')
            .select('used_condoms, used_lubricants')
            .eq('user_id', userId)
            .eq('month', monthStart)
            .maybeSingle();

        if (existingQuota != null) {
          final totalCondomsToRefund = _currentData.condomQuantities.values
              .fold(0, (sum, val) => sum + val);
          final lubricantToRefund = _currentData.lubricantQuantity;
          final newUsedCondoms =
              (((existingQuota['used_condoms'] as int?) ?? 0) - totalCondomsToRefund)
                  .clamp(0, 9999);
          final newUsedLubricants =
              (((existingQuota['used_lubricants'] as int?) ?? 0) - lubricantToRefund)
                  .clamp(0, 9999);

          await Supabase.instance.client.from('user_monthly_quotas').upsert({
            'user_id': userId,
            'month': monthStart,
            'used_condoms': newUsedCondoms,
            'used_lubricants': newUsedLubricants,
          }, onConflict: 'user_id, month');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ยกเลิกคำขอเรียบร้อยแล้ว', style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาดในการยกเลิกคำขอ', style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        elevation: 24,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ยืนยันการยกเลิกคำขอ',
          style: GoogleFonts.googleSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการยกเลิกคำขอนี้ใช่หรือไม่?\nการยกเลิกจะคืนสิทธิ์การรับให้กับคุณทันที',
          style: GoogleFonts.googleSans(fontSize: 15, height: 1.6),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          GradientButton(
            height: 46,
            onPressed: () => Navigator.of(ctx).pop(true),
            label: 'ยืนยันยกเลิก',
            gradientColors: GradientButton.errorGradient,
            fontSize: 15,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text('ไม่ยกเลิก',
                  style: GoogleFonts.googleSans(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _doCancelRequest();
  }

  Widget _buildBottomButtons(BuildContext context) {
    final canCancel = _currentData.status == RequestStatus.pending;

    return Column(
      children: [
        GradientButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'ตกลง',
        ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _confirmCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : Text(
                      'ยกเลิกคำขอ',
                      style: GoogleFonts.googleSans(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  String formatMonthTH(int month) {
    switch (month) {
      case 1: return 'มกราคม';
      case 2: return 'กุมภาพันธ์';
      case 3: return 'มีนาคม';
      case 4: return 'เมษายน';
      case 5: return 'พฤษภาคม';
      case 6: return 'มิถุนายน';
      case 7: return 'กรกฎาคม';
      case 8: return 'สิงหาคม';
      case 9: return 'กันยายน';
      case 10: return 'ตุลาคม';
      case 11: return 'พฤศจิกายน';
      case 12: return 'ธันวาคม';
      default: return '';
    }
  }
}
