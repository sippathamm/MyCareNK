import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class CondomRequestSuccessPage extends StatelessWidget {
  final Map<int, int> quantities;
  final int lubricantQuantity;
  final String? selectedServiceCenter;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String message;
  final String referenceNumber;

  const CondomRequestSuccessPage({
    super.key,
    required this.quantities,
    required this.lubricantQuantity,
    this.selectedServiceCenter,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.referenceNumber,
  });

  int get _totalSelected =>
      quantities.values.fold(0, (sum, c) => sum + c);

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return '${date.day} ${months[date.month]} ${date.year + 543}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    final infoRows = [
      (Icons.local_hospital_outlined, 'สถานบริการ', selectedServiceCenter ?? '-'),
      (Icons.event_outlined, 'วันที่', _formatDate(selectedDate)),
      (Icons.schedule_outlined, 'เวลา', _formatTime(selectedTime)),
      if (_totalSelected > 0)
        (Icons.inventory_2_outlined, 'ถุงยางอนามัย', '$_totalSelected ชิ้น'),
      if (lubricantQuantity > 0)
        (Icons.add_circle_outline, 'เจลหล่อลื่น', '$lubricantQuantity ชิ้น'),
      if (message.isNotEmpty)
        (Icons.comment_outlined, 'ฝากข้อความ', message),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.primary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'รับถุงยางอนามัย',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: _buildStepIndicator(2),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F5E9),
                      border: Border.all(color: AppColors.success, width: 4),
                    ),
                    child: const Icon(Icons.check,
                        color: AppColors.success, size: 52),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ส่งข้อมูลสำเร็จ!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'เราได้รับคำขอถุงยางอนามัยของคุณแล้ว',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.cardShadowMedium,
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryDark, AppColors.primary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.event_note_outlined,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('รายละเอียดคำขอ',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: infoRows
                                  .map((row) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryCardStart,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(row.$1,
                                                  color: AppColors.primary,
                                                  size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(row.$2,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .textHint)),
                                                  Text(row.$3,
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'หมายเลขอ้างอิง: $referenceNumber',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('กลับไปบริการ',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white)),
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

  Widget _buildStepIndicator(int step) {
    const labels = ['กรอกข้อมูล', 'ยืนยัน', 'สำเร็จ'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < step;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final isDone = idx < step;
          final isCurrent = idx == step;
          final active = isDone || isCurrent;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : const Color(0xFFE8E8E8),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
