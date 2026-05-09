import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../widgets/stepper_row_condom.dart';
import '../widgets/stepper_lubricant.dart';
import 'condom_request_confirm_page.dart';
import 'request_history_page.dart';

// ── Date helpers ─────────────────────────────────────────────────────────────

const _thMonths = [
  '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];
const _thDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

class _PickDate {
  final DateTime date;
  final String dayLabel;
  final String monthLabel;
  const _PickDate(this.date, this.dayLabel, this.monthLabel);
}

class _ServiceCenter {
  final String name;
  final String hours;
  const _ServiceCenter(this.name, this.hours);
}

const _kServiceCenters = [
  _ServiceCenter('รพ.โพนพิสัย', 'จ–ศ 08:00–16:00'),
  _ServiceCenter('รพ.สต.วัดหลวง', 'จ–ศ 08:00–16:00'),
  _ServiceCenter('อบต.วัดหลวง', 'จ–ศ 08:30–16:30'),
  _ServiceCenter('สสจ.หนองคาย', 'จ–ศ 08:00–17:00'),
];

List<_PickDate> _buildDateList() {
  final list = <_PickDate>[];
  var d = DateTime.now();
  while (list.length < 7) {
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      final dow = d.weekday == 7 ? 0 : d.weekday;
      list.add(_PickDate(d, _thDays[dow], _thMonths[d.month]));
    }
    d = d.add(const Duration(days: 1));
  }
  return list;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class CondomRequestPage extends StatefulWidget {
  const CondomRequestPage({super.key});

  @override
  State<CondomRequestPage> createState() => _CondomRequestPageState();
}

class _CondomRequestPageState extends State<CondomRequestPage> {
  final Map<int, int> _quantities = {49: 0, 52: 0, 54: 0, 56: 0};
  int _lubricantQuantity = 0;
  String? _selectedServiceCenter;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _messageController = TextEditingController();
  int _animationVersion = 0;
  StreamSubscription<AuthState>? _authSubscription;
  final List<_PickDate> _dates = _buildDateList();

  int _currentMonthlyUsed = AppConstants.maxCondomQuota;
  int _currentMonthlyLubricantUsed = AppConstants.maxLubricantQuota;

  int get _totalSelected =>
      _quantities.values.fold(0, (sum, count) => sum + count);

  bool get _canProceed =>
      _totalSelected > 0 &&
      _selectedServiceCenter != null &&
      _selectedDate != null &&
      _selectedTime != null;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyQuota();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          _currentMonthlyUsed = AppConstants.maxCondomQuota;
          _currentMonthlyLubricantUsed = AppConstants.maxLubricantQuota;
          _animationVersion++;
        });
      } else if (data.event == AuthChangeEvent.signedIn) {
        _fetchMonthlyQuota();
      }
    });
  }

  Future<void> _fetchMonthlyQuota() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
      final response = await Supabase.instance.client
          .from('user_monthly_quotas')
          .select('used_condoms, used_lubricants')
          .eq('user_id', user.id)
          .eq('month', monthStart)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _currentMonthlyUsed = (response?['used_condoms'] as int?) ?? 0;
          _currentMonthlyLubricantUsed =
              (response?['used_lubricants'] as int?) ?? 0;
          _animationVersion++;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _navigateToConfirm() {
    if (_totalSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกถุงยางอนามัยอย่างน้อย 1 ชิ้น', style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CondomRequestConfirmPage(
          quantities: _quantities,
          lubricantQuantity: _lubricantQuantity,
          selectedServiceCenter: _selectedServiceCenter,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          message: _messageController.text,
          currentMonthlyUsed: _currentMonthlyUsed,
          maxMonthlyQuota: AppConstants.maxCondomQuota,
          currentMonthlyLubricantUsed: _currentMonthlyLubricantUsed,
          maxMonthlyLubricantQuota: AppConstants.maxLubricantQuota,
        ),
      ),
    );
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
          'รับถุงยางอนามัย',
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            tooltip: 'ประวัติคำขอ',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RequestHistoryPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: _buildStepIndicator(0),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthlyProgress(),
                  const SizedBox(height: 20),
                  _buildQuantityCard(),
                  const SizedBox(height: 20),
                  _buildLubricantCard(),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'สถานบริการ',
                    icon: Icons.local_hospital_outlined,
                    child: Column(
                      children: List.generate(
                        _kServiceCenters.length,
                        (i) => _buildLocationTile(_kServiceCenters[i], i),
                      ),
                    ),
                  ),
                  _buildSectionCard(
                    title: 'วันที่รับ',
                    icon: Icons.event_outlined,
                    child: _buildDatePicker(),
                  ),
                  _buildSectionCard(
                    title: 'เวลารับ',
                    icon: Icons.schedule_outlined,
                    child: _buildTimePicker(),
                  ),
                  _buildSectionCard(
                    title: 'ฝากข้อความ (ไม่ระบุได้)',
                    icon: Icons.comment_outlined,
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความที่นี่...',
                        hintStyle: GoogleFonts.googleSans(
                            fontSize: 16, color: AppColors.textHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8E8E8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: AnimatedOpacity(
              opacity: _canProceed ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: GradientButton(
                onPressed: _canProceed ? _navigateToConfirm : null,
                label: 'ถัดไป',
              ),
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
                      : Text(
                          '${idx + 1}',
                          style: GoogleFonts.googleSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: GoogleFonts.googleSans(
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
                    style: GoogleFonts.googleSans(
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

  // ── Location tiles ──────────────────────────────────────────────────────────

  Widget _buildLocationTile(_ServiceCenter center, int index) {
    final sel = _selectedServiceCenter == center.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedServiceCenter = center.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryCardStart : Colors.white,
          border: Border.all(
              color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
              width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.googleSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${center.hours} น.',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Widget _buildDatePicker() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = _dates[i];
          final sel = _selectedDate != null &&
              _selectedDate!.year == d.date.year &&
              _selectedDate!.month == d.date.month &&
              _selectedDate!.day == d.date.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = d.date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 60,
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                border: Border.all(
                    color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
                    width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    d.dayLabel,
                    style: GoogleFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: sel
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textHint,
                    ),
                  ),
                  Text(
                    '${d.date.day}',
                    style: GoogleFonts.googleSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    d.monthLabel,
                    style: GoogleFonts.googleSans(
                      fontSize: 11,
                      color: sel
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Time picker ─────────────────────────────────────────────────────────────

  Widget _buildTimePicker() {
    Widget chip(String t) {
      final parts = t.split(':');
      final tod =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final sel = _selectedTime == tod;
      return GestureDetector(
        onTap: () => setState(() => _selectedTime = tod),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.white,
            border: Border.all(
                color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
                width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$t น.',
            style: GoogleFonts.googleSans(
              fontSize: 15,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: sel ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        );

    final morning = AppConstants.pickupTimes
        .where((t) => int.parse(t.split(':')[0]) < 12)
        .toList();
    final afternoon = AppConstants.pickupTimes
        .where((t) => int.parse(t.split(':')[0]) >= 12)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty) ...[
          label('ช่วงเช้า'),
          Wrap(spacing: 8, runSpacing: 8, children: morning.map(chip).toList()),
        ],
        if (afternoon.isNotEmpty) ...[
          const SizedBox(height: 14),
          label('ช่วงบ่าย'),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: afternoon.map(chip).toList()),
        ],
      ],
    );
  }

  // ── Monthly progress ────────────────────────────────────────────────────────

  Widget _buildMonthlyProgress() {
    final int totalUsed = _currentMonthlyUsed + _totalSelected;
    final int remaining =
        (AppConstants.maxCondomQuota - totalUsed).clamp(0, AppConstants.maxCondomQuota);
    final int totalLubricantUsed =
        _currentMonthlyLubricantUsed + _lubricantQuantity;
    final int remainingLubricant =
        (AppConstants.maxLubricantQuota - totalLubricantUsed)
            .clamp(0, AppConstants.maxLubricantQuota);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สิทธิ์รับฟรีเดือนนี้',
          style: GoogleFonts.googleSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ถุงยางอนามัย',
                    style: GoogleFonts.googleSans(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  TweenAnimationBuilder<int>(
                    key: ValueKey('condom_num_$_animationVersion'),
                    tween: IntTween(begin: 0, end: remaining),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$value ',
                          style: GoogleFonts.googleSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
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
                  const SizedBox(height: 8),
                  _buildProgressBar(
                    key: 'condom_bar_$_animationVersion',
                    color: AppColors.primary,
                    current: remaining,
                    total: AppConstants.maxCondomQuota,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เจลหล่อลื่น',
                    style: GoogleFonts.googleSans(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  TweenAnimationBuilder<int>(
                    key: ValueKey('lubricant_num_$_animationVersion'),
                    tween: IntTween(begin: 0, end: remainingLubricant),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$value ',
                          style: GoogleFonts.googleSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lubricant),
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
                  const SizedBox(height: 8),
                  _buildProgressBar(
                    key: 'lubricant_bar_$_animationVersion',
                    color: AppColors.lubricant,
                    current: remainingLubricant,
                    total: AppConstants.maxLubricantQuota,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String key,
    required Color color,
    required int current,
    required int total,
  }) {
    final double pct = total > 0 ? (current / total).clamp(0.0, 1.0) : 0;
    return TweenAnimationBuilder<double>(
      key: ValueKey(key),
      tween: Tween<double>(begin: 0, end: pct),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Stack(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 6,
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quantity card ───────────────────────────────────────────────────────────

  Widget _buildQuantityCard() {
    return Container(
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
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      color: AppColors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ถุงยางอนามัย',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _quantities.entries.map((entry) {
                  final int totalUsed = _currentMonthlyUsed + _totalSelected;
                  final int remaining =
                      (AppConstants.maxCondomQuota - totalUsed)
                          .clamp(0, AppConstants.maxCondomQuota);
                  final int maxAllowed = entry.value + remaining;
                  return StepperRowCondom(
                    label: '${entry.key}',
                    count: entry.value,
                    max: maxAllowed,
                    onChanged: (val) =>
                        setState(() => _quantities[entry.key] = val),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('รวม',
                      style: GoogleFonts.googleSans(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const SizedBox(width: 38),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        '$_totalSelected',
                        style: GoogleFonts.googleSans(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: Text('ชิ้น',
                          style: GoogleFonts.googleSans(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lubricant card ──────────────────────────────────────────────────────────

  Widget _buildLubricantCard() {
    return Container(
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
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      color: AppColors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'เพิ่มเติม',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(builder: (context) {
                final int totalLubricantUsed =
                    _currentMonthlyLubricantUsed + _lubricantQuantity;
                final int remainingLubricant =
                    (AppConstants.maxLubricantQuota - totalLubricantUsed)
                        .clamp(0, AppConstants.maxLubricantQuota);
                final int maxLubricantAllowed =
                    _lubricantQuantity + remainingLubricant;
                return StepperLubricant(
                  label: 'เจลหล่อลื่น',
                  count: _lubricantQuantity,
                  max: maxLubricantAllowed,
                  onChanged: (val) =>
                      setState(() => _lubricantQuantity = val),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
