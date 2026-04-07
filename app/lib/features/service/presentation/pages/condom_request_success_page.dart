import 'package:flutter/material.dart';
import 'condom_request_detail_page.dart';

class CondomRequestSuccessPage extends StatelessWidget {
  final Map<int, int> quantities;
  final int lubricantQuantity;
  final String? selectedServiceCenter;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String message;
  final int currentMonthlyUsed;
  final int maxMonthlyQuota;
  final int currentMonthlyLubricantUsed;
  final int maxMonthlyLubricantQuota;
  final String referenceNumber;

  const CondomRequestSuccessPage({
    super.key,
    required this.quantities,
    required this.lubricantQuantity,
    this.selectedServiceCenter,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.currentMonthlyUsed,
    required this.maxMonthlyQuota,
    required this.currentMonthlyLubricantUsed,
    required this.maxMonthlyLubricantQuota,
    required this.referenceNumber,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final List<String> months = [
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
    return '${date.day} ${months[date.month]} ${date.year + 543}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Title
                        const Text(
                          'ขอขอบคุณ!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8A50),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Green Checkmark
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF5DB036),
                              width: 12,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              size: 80,
                              color: Color(0xFF5DB036),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Success Text
                        const Text(
                          'ส่งข้อมูลสำเร็จ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                        const SizedBox(height: 16),

                        const Text(
                          'จุดบริการกำลังเตรียมถุงยางอนามัยให้คุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'โปรดมารับที่',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            height: 1.5,
                          ),
                        ),

                        Text(
                          selectedServiceCenter ?? '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8A50),
                            height: 1.5,
                          ),
                        ),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF333333),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'วันที่ '),
                              TextSpan(
                                text: _formatDate(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8A50),
                                ),
                              ),
                              const TextSpan(text: ' เวลา '),
                              TextSpan(
                                text: _formatTime(selectedTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8A50),
                                ),
                              ),
                              const TextSpan(text: ' น.'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'หมายเลขอ้างอิง: $referenceNumber',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),

                        const Spacer(),

                        // Buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CondomRequestDetailPage(
                                            quantities: quantities,
                                            lubricantQuantity:
                                                lubricantQuantity,
                                            selectedServiceCenter: selectedServiceCenter,
                                            selectedDate: selectedDate,
                                            selectedTime: selectedTime,
                                            message: message,
                                            currentMonthlyUsed:
                                                currentMonthlyUsed,
                                            maxMonthlyQuota: maxMonthlyQuota,
                                            currentMonthlyLubricantUsed:
                                                currentMonthlyLubricantUsed,
                                            maxMonthlyLubricantQuota:
                                                maxMonthlyLubricantQuota,
                                          ),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  'ดูข้อมูล',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFF8A50),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  'กลับไปบริการ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF8A50),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

    );
  }
}
