import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'request_history_page.dart';

class RequestHistoryDetailPage extends StatelessWidget {
  final RequestMockData data;

  const RequestHistoryDetailPage({super.key, required this.data});

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

    switch (data.status) {
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

    // Example formatted date "22 มีนาคม 2569 16:32 น."
    String dateStr =
        '${data.date.day} มีนาคม ${data.date.year + 543} ${data.date.hour.toString().padLeft(2, '0')}:${data.date.minute.toString().padLeft(2, '0')} น.';

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
                  data.refNumber,
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
                    Clipboard.setData(ClipboardData(text: data.refNumber));
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
    bool isCancelled = data.status == RequestStatus.cancelled;

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
        data.status == RequestStatus.preparing ||
        data.status == RequestStatus.completed;
    bool isFinalDone = data.status == RequestStatus.completed;

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
                color: data.status == RequestStatus.submitted
                    ? subColor
                    : Colors.black87,
                fontSize: 12,
                fontWeight: data.status == RequestStatus.submitted
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              'กำลังเตรียม',
              style: GoogleFonts.prompt(
                color: data.status == RequestStatus.preparing
                    ? prepColor
                    : Colors.black87,
                fontSize: 12,
                fontWeight: data.status == RequestStatus.preparing
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              'เสร็จสิ้น',
              style: GoogleFonts.prompt(
                color: data.status == RequestStatus.completed
                    ? compColor
                    : Colors.black87,
                fontSize: 12,
                fontWeight: data.status == RequestStatus.completed
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
        children: [
          _buildSizeRow('49', 0),
          _buildSizeRow('52', 5),
          _buildSizeRow('54', 5),
          _buildSizeRow('56', 99),
        ],
      ),
      showDivider: true,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'รวม',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            '109 ชิ้น',
            style: TextStyle(
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
      content: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'สารหล่อลื่น',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            '99 ซอง',
            style: TextStyle(
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
                data.location,
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
              const Text(
                '31 มกราคม 2569',
                style: TextStyle(
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
              const Text(
                '14:00 น.',
                style: TextStyle(
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
      content: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'ข้อความ',
          style: TextStyle(fontSize: 16, color: Color(0xFFFF8A50)),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    bool canCancel = data.status == RequestStatus.submitted;

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
              onPressed: () {
                // handle cancel
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5252),
                side: const BorderSide(color: Color(0xFFFF5252)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'ยกเลิกคำขอ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
