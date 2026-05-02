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
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = session.user.id;
      final quantitiesJson =
          widget.quantities.map((key, value) => MapEntry(key.toString(), value));

      String? dateString;
      if (widget.selectedDate != null) {
        dateString =
            '${widget.selectedDate!.year.toString().padLeft(4, '0')}-'
            '${widget.selectedDate!.month.toString().padLeft(2, '0')}-'
            '${widget.selectedDate!.day.toString().padLeft(2, '0')}';
      }

      String? timeString;
      if (widget.selectedTime != null) {
        timeString =
            '${widget.selectedTime!.hour.toString().padLeft(2, '0')}:'
            '${widget.selectedTime!.minute.toString().padLeft(2, '0')}:00';
      }

      const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final Random random = Random();
      final String refNumber =
          List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();

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

      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);

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
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
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
            child: _buildStepIndicator(1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  _buildMonthlyProgress(),
                  const SizedBox(height: 20),
                  if (_totalSelected > 0) _buildQuantityCard(),
                  if (widget.lubricantQuantity > 0) _buildLubricantCard(),
                  _buildPlaceTimeCard(),
                  if (widget.message.isNotEmpty) _buildMessageCard(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFFF8F00), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนยืนยัน หากต้องการแก้ไขให้กดปุ่ม "แก้ไข"',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5D4037),
                                height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2),
                          )
                        : const Text('ยืนยัน',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('แก้ไข',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ──────────────────────────────────────────────────────────

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
                              color:
                                  active ? Colors.white : AppColors.textMuted)),
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

  // ── Section card ────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
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
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
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

  // ── Monthly progress ────────────────────────────────────────────────────────

  Widget _buildMonthlyProgress() {
    final int totalUsed = widget.currentMonthlyUsed + _totalSelected;
    final int remaining =
        (widget.maxMonthlyQuota - totalUsed).clamp(0, widget.maxMonthlyQuota);
    final int totalLubricantUsed =
        widget.currentMonthlyLubricantUsed + widget.lubricantQuantity;
    final int remainingLubricant =
        (widget.maxMonthlyLubricantQuota - totalLubricantUsed)
            .clamp(0, widget.maxMonthlyLubricantQuota);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สิทธิ์รับฟรีคงเหลือ',
          style: GoogleFonts.googleSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ถุงยางอนามัย',
                      style: GoogleFonts.googleSans(
                          fontSize: 14, color: AppColors.textSecondary)),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: (widget.maxMonthlyQuota - widget.currentMonthlyUsed)
                          .clamp(0, widget.maxMonthlyQuota),
                      end: remaining,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$value ',
                          style: GoogleFonts.googleSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 28),
                        ),
                        TextSpan(
                          text: 'ชิ้น',
                          style: GoogleFonts.googleSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เจลหล่อลื่น',
                      style: GoogleFonts.googleSans(
                          fontSize: 14, color: AppColors.textSecondary)),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: (widget.maxMonthlyLubricantQuota -
                              widget.currentMonthlyLubricantUsed)
                          .clamp(0, widget.maxMonthlyLubricantQuota),
                      end: remainingLubricant,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$value ',
                          style: GoogleFonts.googleSans(
                              color: AppColors.lubricant,
                              fontWeight: FontWeight.bold,
                              fontSize: 28),
                        ),
                        TextSpan(
                          text: 'ชิ้น',
                          style: GoogleFonts.googleSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lubricant),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Summary cards ───────────────────────────────────────────────────────────

  Widget _buildQuantityCard() {
    return _buildSectionCard(
      title: 'ถุงยางอนามัย',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          ...widget.quantities.entries
              .where((e) => e.value > 0)
              .map((e) => _buildInfoRow('ขนาด ${e.key} มม.', '${e.value} ชิ้น')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รวม',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '$_totalSelected ชิ้น',
                style: const TextStyle(
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
    return _buildSectionCard(
      title: 'เพิ่มเติม',
      icon: Icons.add_circle_outline,
      child: _buildInfoRow('เจลหล่อลื่น', '${widget.lubricantQuantity} ชิ้น'),
    );
  }

  Widget _buildPlaceTimeCard() {
    final dateStr = widget.selectedDate != null
        ? '${widget.selectedDate!.day} ${_monthTH(widget.selectedDate!.month)} ${widget.selectedDate!.year + 543}'
        : '-';
    final timeStr = widget.selectedTime != null
        ? '${widget.selectedTime!.hour.toString().padLeft(2, '0')}:${widget.selectedTime!.minute.toString().padLeft(2, '0')} น.'
        : '-';

    return _buildSectionCard(
      title: 'สถานบริการ วันที่และเวลารับ',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          _buildInfoRow('สถานบริการ', widget.selectedServiceCenter ?? '-'),
          _buildInfoRow('วันที่', dateStr),
          _buildInfoRow('เวลา', timeStr),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return _buildSectionCard(
      title: 'ฝากข้อความ',
      icon: Icons.comment_outlined,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(widget.message,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }

  String _monthTH(int m) {
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return months[m];
  }
}
