import 'package:flutter/material.dart';

class CondomRequestDetailPage extends StatelessWidget {
  final Map<int, int> quantities;
  final int lubricantQuantity;
  final String? selectedLocation;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String message;
  final int currentMonthlyUsed;
  final int maxMonthlyQuota;
  final int currentMonthlyLubricantUsed;
  final int maxMonthlyLubricantQuota;

  const CondomRequestDetailPage({
    super.key,
    required this.quantities,
    required this.lubricantQuantity,
    this.selectedLocation,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.currentMonthlyUsed,
    required this.maxMonthlyQuota,
    required this.currentMonthlyLubricantUsed,
    required this.maxMonthlyLubricantQuota,
  });

  int get _totalSelected =>
      quantities.values.fold(0, (sum, count) => sum + count);

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
          'ข้อมูลคำขอ',
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
              _buildMonthlyProgress(context),
              const SizedBox(height: 20),
              _buildQuantityCard(context),
              _buildLubricantCard(context),
              _buildPlaceTimeCard(context),
              if (message.isNotEmpty) _buildMessageCard(context),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyProgress(BuildContext context) {
    final int totalUsed = currentMonthlyUsed + _totalSelected;
    final int remaining = (maxMonthlyQuota - totalUsed).clamp(
      0,
      maxMonthlyQuota,
    );

    final int totalLubricantUsed =
        currentMonthlyLubricantUsed + lubricantQuantity;
    final int remainingLubricant =
        (maxMonthlyLubricantQuota - totalLubricantUsed).clamp(
          0,
          maxMonthlyLubricantQuota,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สิทธิ์รับฟรีคงเหลือ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ถุงยางอนามัย',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: (maxMonthlyQuota - currentMonthlyUsed).clamp(
                        0,
                        maxMonthlyQuota,
                      ),
                      end: remaining,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Text.rich(
                        TextSpan(
                          text: '$value ',
                          style: const TextStyle(
                            color: Color(0xFFFF8A50),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            height: 1.0,
                          ),
                          children: const [
                            TextSpan(
                              text: 'ชิ้น',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สารหล่อลื่น',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin:
                          (maxMonthlyLubricantQuota -
                                  currentMonthlyLubricantUsed)
                              .clamp(0, maxMonthlyLubricantQuota),
                      end: remainingLubricant,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Text.rich(
                        TextSpan(
                          text: '$value ',
                          style: const TextStyle(
                            color: Color(0xFF4A9FE8),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            height: 1.0,
                          ),
                          children: const [
                            TextSpan(
                              text: 'ชิ้น',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
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
            color: Colors.black.withOpacity(0.04),
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
              color: Colors.white, // header background white
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

  Widget _buildQuantityCard(BuildContext context) {
    if (_totalSelected == 0) return const SizedBox();

    return _buildCard(
      header: const Text(
        'จำนวนถุงยางอนามัย',
        style: TextStyle(
          color: Colors.black, // text black
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        children: quantities.entries.where((entry) => entry.value > 0).map((
          entry,
        ) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ขนาด ${entry.key} มม.',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  '${entry.value} ชิ้น',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8A50), // user data orange
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
            '$_totalSelected ชิ้น',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8A50), // user data orange
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard(BuildContext context) {
    if (lubricantQuantity == 0) return const SizedBox();

    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'เพิ่มเติม',
            style: TextStyle(
              color: Colors.black, // text black
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
            '$lubricantQuantity ชิ้น',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8A50), // user data orange
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceTimeCard(BuildContext context) {
    String dateStr = selectedDate != null
        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year + 543}'
        : '-';
    String timeStr = selectedTime != null
        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')} น.'
        : '-';

    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'สถานที่ วันและเวลารับ',
            style: TextStyle(
              color: Colors.black, // text black
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
              const Text('สถานที่', style: TextStyle(fontSize: 16)),
              Text(
                selectedLocation ?? '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A50), // user data orange
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
                dateStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A50), // user data orange
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
                timeStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A50), // user data orange
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    return _buildCard(
      header: const Row(
        children: [
          Icon(Icons.comment_outlined, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'ฝากข้อความ',
            style: TextStyle(
              color: Colors.black, // text black
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFFF8A50), // user data orange
          ),
        ),
      ),
    );
  }
}
