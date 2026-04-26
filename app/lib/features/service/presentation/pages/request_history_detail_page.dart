import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/condom_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';

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
        title: const Text(
          'ดูข้อมูล',
          style: TextStyle(
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
              'หมายเลขอ้างอิง',
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
                          'คัดลอกหมายเลขอ้างอิงแล้ว',
                          style: GoogleFonts.googleSans(),
                        ),
                        duration: const Duration(seconds: 2),
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
      final cancelLabel = status == RequestStatus.cancelledByStaff
          ? 'ยกเลิกโดยเจ้าหน้าที่'
          : 'ยกเลิก';
      return Column(
        children: [
          Row(
            children: [
              _buildDot(AppColors.primary, isFilled: true),
              Expanded(child: _buildLine(AppColors.primary)),
              _buildDot(Colors.grey[600]!, isFilled: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รอดำเนินการ',
                style: GoogleFonts.googleSans(color: Colors.black87, fontSize: 12),
              ),
              Text(
                cancelLabel,
                style: GoogleFonts.googleSans(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      );
    }

    const Color prepColor = AppColors.lubricant;
    const Color readyColor = AppColors.statusReady;
    const Color compColor = AppColors.statusCompleted;

    final isPrepDone = status == RequestStatus.preparing ||
        status == RequestStatus.ready ||
        status == RequestStatus.completed;
    final isReadyDone = status == RequestStatus.ready ||
        status == RequestStatus.completed;
    final isFinalDone = status == RequestStatus.completed;

    return Column(
      children: [
        Row(
          children: [
            _buildDot(AppColors.primary, isFilled: true),
            Expanded(child: _buildLine(isPrepDone ? AppColors.primary : Colors.grey[300]!)),
            _buildDot(prepColor, isFilled: isPrepDone),
            Expanded(child: _buildLine(isReadyDone ? prepColor : Colors.grey[300]!)),
            _buildDot(readyColor, isFilled: isReadyDone),
            Expanded(child: _buildLine(isFinalDone ? readyColor : Colors.grey[300]!)),
            _buildDot(compColor, isFilled: isFinalDone),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รอดำเนินการ',
              style: GoogleFonts.googleSans(
                color: status == RequestStatus.pending ? AppColors.primary : Colors.black87,
                fontSize: 12,
                fontWeight: status == RequestStatus.pending ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'กำลังเตรียม',
              style: GoogleFonts.googleSans(
                color: status == RequestStatus.preparing ? prepColor : Colors.black87,
                fontSize: 12,
                fontWeight: status == RequestStatus.preparing ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'พร้อมรับ',
              style: GoogleFonts.googleSans(
                color: status == RequestStatus.ready ? readyColor : Colors.black87,
                fontSize: 12,
                fontWeight: status == RequestStatus.ready ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'เสร็จสิ้น',
              style: GoogleFonts.googleSans(
                color: status == RequestStatus.completed ? compColor : Colors.black87,
                fontSize: 12,
                fontWeight: status == RequestStatus.completed ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(Color color, {required bool isFilled}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? color : AppColors.white,
        border: isFilled ? null : Border.all(color: color, width: 2),
      ),
    );
  }

  Widget _buildLine(Color color) {
    return Container(height: 2, color: color);
  }

  Widget _buildCard({
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
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
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
              color: AppColors.white,
              width: double.infinity,
              child: header,
            ),
            const Divider(height: 1),
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

  Widget _buildQuantityCard() {
    int totalCondoms = _currentData.condomQuantities.values.fold(0, (sum, val) => sum + val);
    if (totalCondoms == 0) return const SizedBox();

    return _buildCard(
      header: const Text(
        'จำนวนถุงยางอนามัย',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        children: _currentData.condomQuantities.entries
            .where((e) => e.value > 0)
            .map((e) => _buildSizeRow('${e.key}', e.value))
            .toList(),
      ),
      showDivider: true,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'รวม',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '$totalCondoms ชิ้น',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeRow(String size, int quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ขนาด $size มม.',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            '$quantity ชิ้น',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: quantity > 0 ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard() {
    if (_currentData.lubricantQuantity == 0) return const SizedBox();

    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'เพิ่มเติม',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'สารหล่อลื่น',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            '${_currentData.lubricantQuantity} ซอง',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
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
       if(splitted.length >= 2) {
          outputTime = '${splitted[0]}:${splitted[1]} น.';
       }
    }

    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'สถานบริการ วันและเวลารับ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('สถานบริการ', style: TextStyle(fontSize: 16)),
              Text(
                _currentData.selectedServiceCenter ?? '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('วันที่', style: TextStyle(fontSize: 16)),
              Text(
                outputDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('เวลา', style: TextStyle(fontSize: 16)),
              Text(
                outputTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    if (_currentData.message.isEmpty) return const SizedBox();

    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.comment_outlined, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'ฝากข้อความ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentData.message,
          style: const TextStyle(fontSize: 16, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildCancelReasonCard() {
    if (_currentData.status != RequestStatus.cancelledByStaff) return const SizedBox();
    if (_currentData.cancelReason == null || _currentData.cancelReason!.isEmpty) return const SizedBox();

    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'เหตุผลที่ยกเลิก',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentData.cancelReason!,
          style: const TextStyle(fontSize: 16, color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    bool canCancel = _currentData.status == RequestStatus.pending;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'ตกลง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (canCancel) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : () async {
                setState(() {
                  _isCancelling = true;
                });
                try {
                  await Supabase.instance.client
                      .from('condom_requests')
                      .update({
                        'request_status': 'cancelled_by_user',
                      })
                      .eq('id', _currentData.id);

                  // Refund quota to user_monthly_quotas
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
                      int totalCondomsToRefund = _currentData.condomQuantities.values
                          .fold(0, (sum, val) => sum + val);
                      int lubricantToRefund = _currentData.lubricantQuantity;

                      int currentUsedCondoms = (existingQuota['used_condoms'] as int?) ?? 0;
                      int currentUsedLubricants = (existingQuota['used_lubricants'] as int?) ?? 0;

                      int newUsedCondoms = (currentUsedCondoms - totalCondomsToRefund).clamp(0, 9999);
                      int newUsedLubricants = (currentUsedLubricants - lubricantToRefund).clamp(0, 9999);

                      await Supabase.instance.client.from('user_monthly_quotas').upsert({
                        'user_id': userId,
                        'month': monthStart,
                        'used_condoms': newUsedCondoms,
                        'used_lubricants': newUsedLubricants,
                      }, onConflict: 'user_id, month');
                    }
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ยกเลิกคำขอเรียบร้อยแล้ว')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เกิดข้อผิดพลาดในการยกเลิกคำขอ')),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isCancelling = false;
                    });
                  }
                }
              },
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                    )
                  : const Text(
                      'ยกเลิกคำขอ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
