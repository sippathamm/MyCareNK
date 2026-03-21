import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/condom_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestHistoryDetailPage extends StatefulWidget {
  final CondomRequestModel data;

  const RequestHistoryDetailPage({super.key, required this.data});

  @override
  State<RequestHistoryDetailPage> createState() => _RequestHistoryDetailPageState();
}

class _RequestHistoryDetailPageState extends State<RequestHistoryDetailPage> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8A50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ดูข้อมูล',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 48),
              _buildBottomButtons(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderId(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (widget.data.status) {
      case RequestStatus.submitted:
        icon = Icons.assignment_outlined;
        iconColor = const Color(0xFFFF8A50);
        iconBgColor = const Color(0xFFFBE9E7);
        break;
      case RequestStatus.preparing:
        icon = Icons.inventory_2_outlined;
        iconColor = const Color(0xFF4A9FE8);
        iconBgColor = const Color(0xFFE3F2FD);
        break;
      case RequestStatus.completed:
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF26A69A);
        iconBgColor = const Color(0xFFE0F2F1);
        break;
      case RequestStatus.cancelled:
        icon = Icons.cancel_outlined;
        iconColor = Colors.grey[600]!;
        iconBgColor = Colors.grey[200]!;
        break;
    }

    // Format Date 
    final formattedDate = widget.data.createdAt.toUtc().add(const Duration(hours: 7));
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
              style: GoogleFonts.prompt(color: Colors.grey[500], fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  widget.data.referenceNumber,
                  style: GoogleFonts.prompt(
                    color: const Color(0xFF333333),
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
                    Clipboard.setData(ClipboardData(text: widget.data.referenceNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'คัดลอกหมายเลขอ้างอิงแล้ว',
                          style: GoogleFonts.prompt(),
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
              style: GoogleFonts.prompt(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTracker() {
    bool isCancelled = widget.data.status == RequestStatus.cancelled;

    if (isCancelled) {
      return Column(
        children: [
          Row(
            children: [
              _buildDot(const Color(0xFFFF8A50), isFilled: true),
              Expanded(child: _buildLine(const Color(0xFFFF8A50))),
              _buildDot(Colors.grey[600]!, isFilled: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ส่งคำขอ',
                style: GoogleFonts.prompt(color: Colors.black87, fontSize: 12),
              ),
              Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(
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

    Color subColor = const Color(0xFFFF8A50);
    Color prepColor = const Color(0xFF4A9FE8);
    Color compColor = const Color(0xFF26A69A);

    bool isPrepDone =
        widget.data.status == RequestStatus.preparing ||
        widget.data.status == RequestStatus.completed;
    bool isFinalDone = widget.data.status == RequestStatus.completed;

    Color line1Color = isPrepDone ? subColor : Colors.grey[300]!;
    Color line2Color = isFinalDone ? prepColor : Colors.grey[300]!;

    return Column(
      children: [
        Row(
          children: [
            _buildDot(subColor, isFilled: true),
            Expanded(child: _buildLine(line1Color)),
            _buildDot(prepColor, isFilled: isPrepDone),
            Expanded(child: _buildLine(line2Color)),
            _buildDot(compColor, isFilled: isFinalDone),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ส่งคำขอ',
              style: GoogleFonts.prompt(
                color: widget.data.status == RequestStatus.submitted
                    ? subColor
                    : Colors.black87,
                fontSize: 12,
                fontWeight: widget.data.status == RequestStatus.submitted
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              'กำลังเตรียม',
              style: GoogleFonts.prompt(
                color: widget.data.status == RequestStatus.preparing
                    ? prepColor
                    : Colors.black87,
                fontSize: 12,
                fontWeight: widget.data.status == RequestStatus.preparing
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              'เสร็จสิ้น',
              style: GoogleFonts.prompt(
                color: widget.data.status == RequestStatus.completed
                    ? compColor
                    : Colors.black87,
                fontSize: 12,
                fontWeight: widget.data.status == RequestStatus.completed
                    ? FontWeight.bold
                    : FontWeight.normal,
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
        color: isFilled ? color : Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: const Color(0x05000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
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
    int totalCondoms = widget.data.condomQuantities.values.fold(0, (sum, val) => sum + val);
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
        children: widget.data.condomQuantities.entries
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
              color: Color(0xFFFF8A50),
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
              color: quantity > 0 ? const Color(0xFFFF8A50) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard() {
    if (widget.data.lubricantQuantity == 0) return const SizedBox();

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
            '${widget.data.lubricantQuantity} ซอง',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8A50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    String outputDate = widget.data.selectedDate ?? '-';
    // Optionally format selectedDate properly if it follows YYYY-MM-DD
    if (widget.data.selectedDate != null && widget.data.selectedDate!.contains('-')) {
      try {
        DateTime parsedDate = DateTime.parse(widget.data.selectedDate!);
        outputDate = '${parsedDate.day} ${formatMonthTH(parsedDate.month)} ${parsedDate.year + 543}';
      } catch (e) {
        outputDate = widget.data.selectedDate!;
      }
    }

    String outputTime = widget.data.selectedTime ?? '-';
    if (widget.data.selectedTime != null && widget.data.selectedTime!.contains(':')) {
       final splitted = widget.data.selectedTime!.split(':');
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
            'จุดบริการ วันและเวลารับ',
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
              const Text('จุดบริการ', style: TextStyle(fontSize: 16)),
              Text(
                widget.data.selectedLocation ?? '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A50),
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
                  color: Color(0xFFFF8A50),
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
                  color: Color(0xFFFF8A50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    if (widget.data.message.isEmpty) return const SizedBox();

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
          widget.data.message,
          style: const TextStyle(fontSize: 16, color: Color(0xFFFF8A50)),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    bool canCancel = widget.data.status == RequestStatus.submitted;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A50),
              foregroundColor: Colors.white,
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
                      .update({'status': 'cancelled'})
                      .eq('id', widget.data.id);
                  
                  // Refund quota string to user_monthly_quotas
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session != null) {
                    final userId = session.user.id;
                    final createdAt = widget.data.createdAt.toLocal();
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
                      int totalCondomsToRefund = widget.data.condomQuantities.values
                          .fold(0, (sum, val) => sum + val);
                      int lubricantToRefund = widget.data.lubricantQuantity;

                      int currentUsedCondoms = (existingQuota['used_condoms'] as int?) ?? 0;
                      int currentUsedLubricants = (existingQuota['used_lubricants'] as int?) ?? 0;

                      int newUsedCondoms = (currentUsedCondoms - totalCondomsToRefund).clamp(0, 9999);
                      int newUsedLubricants = (currentUsedLubricants - lubricantToRefund).clamp(0, 9999);

                      await Supabase.instance.client.from('user_monthly_quotas').upsert({
                        'user_id': userId,
                        'month': monthStart,
                        'used_condoms': newUsedCondoms,
                        'used_lubricants': newUsedLubricants,
                        'updated_at': DateTime.now().toUtc().toIso8601String(),
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
                foregroundColor: const Color(0xFFFF5252),
                side: const BorderSide(color: Color(0xFFFF5252)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5252)),
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
