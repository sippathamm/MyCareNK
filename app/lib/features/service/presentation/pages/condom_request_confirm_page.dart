import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import 'condom_request_success_page.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';

class CondomRequestConfirmPage extends StatefulWidget {
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

  const CondomRequestConfirmPage({
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
  });

  @override
  State<CondomRequestConfirmPage> createState() =>
      _CondomRequestConfirmPageState();
}

class _CondomRequestConfirmPageState extends State<CondomRequestConfirmPage> {
  bool _isLoading = false;

  int get _totalSelected =>
      widget.quantities.values.fold(0, (sum, count) => sum + count);

  Future<void> _submitRequest() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำรายการ')),
      );
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = session.user.id;
      final quantitiesJson = widget.quantities.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      String? dateString;
      if (widget.selectedDate != null) {
        dateString =
            "${widget.selectedDate!.year.toString().padLeft(4, '0')}-${widget.selectedDate!.month.toString().padLeft(2, '0')}-${widget.selectedDate!.day.toString().padLeft(2, '0')}";
      }

      String? timeString;
      if (widget.selectedTime != null) {
        timeString =
            "${widget.selectedTime!.hour.toString().padLeft(2, '0')}:${widget.selectedTime!.minute.toString().padLeft(2, '0')}:00";
      }

      // Generate an 8-character alphanumeric reference number.
      const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final Random random = Random();
      final String refNumber = List.generate(
        8,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      await Supabase.instance.client.from('condom_requests').insert({
        'user_id': userId,
        'condom_quantities': quantitiesJson,
        'lubricant_quantity': widget.lubricantQuantity,
        'selected_service_center': widget.selectedServiceCenter,
        'selected_date': dateString,
        'selected_time': timeString,
        'message': widget.message,
        'reference_number': refNumber,
        'request_status': 'pending',
      });

      // Update user's monthly quota usage
      final now = DateTime.now();
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().substring(0, 10);

      // Fetch existing row first (to compute new totals for upsert)
      final existingQuota = await Supabase.instance.client
          .from('user_monthly_quotas')
          .select('used_condoms, used_lubricants')
          .eq('user_id', userId)
          .eq('month', monthStart)
          .maybeSingle();

      final int newUsedCondoms =
          ((existingQuota?['used_condoms'] as int?) ?? 0) + _totalSelected;
      final int newUsedLubricants =
          ((existingQuota?['used_lubricants'] as int?) ?? 0) +
          widget.lubricantQuantity;

      await Supabase.instance.client.from('user_monthly_quotas').upsert({
        'user_id': userId,
        'month': monthStart,
        'used_condoms': newUsedCondoms,
        'used_lubricants': newUsedLubricants,
      }, onConflict: 'user_id, month');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CondomRequestSuccessPage(
              quantities: widget.quantities,
              lubricantQuantity: widget.lubricantQuantity,
              selectedServiceCenter: widget.selectedServiceCenter,
              selectedDate: widget.selectedDate,
              selectedTime: widget.selectedTime,
              message: widget.message,
              currentMonthlyUsed: widget.currentMonthlyUsed,
              maxMonthlyQuota: widget.maxMonthlyQuota,
              currentMonthlyLubricantUsed: widget.currentMonthlyLubricantUsed,
              maxMonthlyLubricantQuota: widget.maxMonthlyLubricantQuota,
              referenceNumber: refNumber,
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Error saving condom request: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'ยืนยันข้อมูล',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
              if (widget.message.isNotEmpty) _buildMessageCard(context),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    final int totalUsed = widget.currentMonthlyUsed + _totalSelected;
    final int remaining = (widget.maxMonthlyQuota - totalUsed).clamp(
      0,
      widget.maxMonthlyQuota,
    );

    final int totalLubricantUsed =
        widget.currentMonthlyLubricantUsed + widget.lubricantQuantity;
    final int remainingLubricant =
        (widget.maxMonthlyLubricantQuota - totalLubricantUsed).clamp(
          0,
          widget.maxMonthlyLubricantQuota,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สิทธิ์รับฟรีคงเหลือ',
          style: GoogleFonts.googleSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ถุงยางอนามัย',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin:
                          (widget.maxMonthlyQuota - widget.currentMonthlyUsed)
                              .clamp(0, widget.maxMonthlyQuota),
                      end: remaining,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$value ',
                              style: GoogleFonts.googleSans(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            TextSpan(
                              text: 'ชิ้น',
                              style: GoogleFonts.googleSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
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
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin:
                          (widget.maxMonthlyLubricantQuota -
                                  widget.currentMonthlyLubricantUsed)
                              .clamp(0, widget.maxMonthlyLubricantQuota),
                      end: remainingLubricant,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$value ',
                              style: GoogleFonts.googleSans(
                                color: AppColors.lubricant,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            TextSpan(
                              text: 'ซอง',
                              style: GoogleFonts.googleSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lubricant,
                              ),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
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

  Widget _buildQuantityCard(BuildContext context) {
    if (_totalSelected == 0) return const SizedBox();

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
        children: widget.quantities.entries
            .where((entry) => entry.value > 0)
            .map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ขนาด ${entry.key} มม.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${entry.value} ชิ้น',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            })
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
            '$_totalSelected ชิ้น',
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

  Widget _buildLubricantCard(BuildContext context) {
    if (widget.lubricantQuantity == 0) return const SizedBox();

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
            '${widget.lubricantQuantity} ซอง',
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

  Widget _buildPlaceTimeCard(BuildContext context) {
    String dateStr = widget.selectedDate != null
        ? '${widget.selectedDate!.day} ${formatMonthTH(widget.selectedDate!.month)} ${widget.selectedDate!.year + 543}'
        : '-';
    String timeStr = widget.selectedTime != null
        ? '${widget.selectedTime!.hour.toString().padLeft(2, '0')}:${widget.selectedTime!.minute.toString().padLeft(2, '0')} น.'
        : '-';

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
                widget.selectedServiceCenter ?? '-',
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
                dateStr,
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
                timeStr,
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

  Widget _buildMessageCard(BuildContext context) {
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
          widget.message,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
