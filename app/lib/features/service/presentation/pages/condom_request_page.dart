import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../widgets/stepper_row_condom.dart';
import '../widgets/stepper_lubricant.dart';
import 'condom_request_confirm_page.dart';

class CondomRequestPage extends StatefulWidget {
  const CondomRequestPage({super.key});

  @override
  State<CondomRequestPage> createState() => _CondomRequestPageState();
}

class _CondomRequestPageState extends State<CondomRequestPage> {
  // State
  final Map<int, int> _quantities = {49: 0, 52: 0, 54: 0, 56: 0};

  int _lubricantQuantity = 0;
  String? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _messageController = TextEditingController();
  int _animationVersion = 0;
  StreamSubscription<AuthState>? _authSubscription;

  // Quota constants
  static const int _maxMonthlyQuota = 60;
  static const int _maxMonthlyLubricantQuota = 30;

  // Fetched from Supabase
  int _currentMonthlyUsed = _maxMonthlyQuota;
  int _currentMonthlyLubricantUsed = _maxMonthlyLubricantQuota;

  int get _totalSelected =>
      _quantities.values.fold(0, (sum, count) => sum + count);

  @override
  void initState() {
    super.initState();
    _fetchMonthlyQuota();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          _currentMonthlyUsed = _maxMonthlyQuota;
          _currentMonthlyLubricantUsed = _maxMonthlyLubricantQuota;
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
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().substring(0, 10);

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
    } catch (_) {
      // On error quietly keep 0 – user still sees full quota available
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _quantities.updateAll((key, value) => 0);
      _lubricantQuantity = 0;
      _selectedLocation = null;
      _selectedDate = null;
      _selectedTime = null;
      _messageController.clear();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8A50),
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

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
          'รับถุงยางอนามัย',
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
              // Monthly Progress
              _buildMonthlyProgress(),
              const SizedBox(height: 20),

              // Quantity Card
              _buildQuantityCard(),

              // Lubricant Card
              _buildLubricantCard(),

              // Place & Time Card
              _buildPlaceTimeCard(),

              // Message Card
              _buildMessageCard(),

              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    // Check if user is logged in
                    final session =
                        Supabase.instance.client.auth.currentSession;
                    if (session == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                      return;
                    }

                    if (_totalSelected == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'กรุณาเลือกถุงยางอนามัยอย่างน้อย 1 ชิ้น',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedLocation == null ||
                        _selectedDate == null ||
                        _selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาเลือกจุดบริการ วันที่ และเวลา'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CondomRequestConfirmPage(
                          quantities: _quantities,
                          lubricantQuantity: _lubricantQuantity,
                          selectedLocation: _selectedLocation,
                          selectedDate: _selectedDate,
                          selectedTime: _selectedTime,
                          message: _messageController.text,
                          currentMonthlyUsed: _currentMonthlyUsed,
                          maxMonthlyQuota: _maxMonthlyQuota,
                          currentMonthlyLubricantUsed:
                              _currentMonthlyLubricantUsed,
                          maxMonthlyLubricantQuota: _maxMonthlyLubricantQuota,
                        ),
                      ),
                    );
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

              const SizedBox(height: 16),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF4D4D)),
                    foregroundColor: const Color(0xFFFF4D4D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'ล้างข้อมูล',
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

  Widget _buildMonthlyProgress() {
    // ถุงยางอนามัย
    final int totalUsed = _currentMonthlyUsed + _totalSelected;
    final int remaining = (_maxMonthlyQuota - totalUsed).clamp(
      0,
      _maxMonthlyQuota,
    );

    // สารหล่อลื่น
    final int totalLubricantUsed =
        _currentMonthlyLubricantUsed + _lubricantQuantity;
    final int remainingLubricant =
        (_maxMonthlyLubricantQuota - totalLubricantUsed).clamp(
          0,
          _maxMonthlyLubricantQuota,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สิทธิ์รับฟรีเดือนนี้',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Condom Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ถุงยางอนามัย',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    key: ValueKey('condom_num_$_animationVersion'),
                    tween: IntTween(begin: 0, end: remaining),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$value ',
                            style: GoogleFonts.prompt(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF8A50),
                            ),
                          ),
                          TextSpan(
                            text: 'ชิ้น',
                            style: GoogleFonts.prompt(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFF8A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildClassicAnimatedProgressBar(
                    animationKey: 'condom_bar_$_animationVersion',
                    color: const Color(0xFFFF8A50),
                    current: remaining,
                    total: _maxMonthlyQuota,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Lubricant Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สารหล่อลื่น',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    key: ValueKey('lubricant_num_$_animationVersion'),
                    tween: IntTween(begin: 0, end: remainingLubricant),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$value ',
                            style: GoogleFonts.prompt(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A9FE8),
                            ),
                          ),
                          TextSpan(
                            text: 'ซอง',
                            style: GoogleFonts.prompt(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4A9FE8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildClassicAnimatedProgressBar(
                    animationKey: 'lubricant_bar_$_animationVersion',
                    color: const Color(0xFF4A9FE8),
                    current: remainingLubricant,
                    total: _maxMonthlyLubricantQuota,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassicAnimatedProgressBar({
    required String animationKey,
    required Color color,
    required int current,
    required int total,
  }) {
    final double percentage = total > 0 ? (current / total).clamp(0.0, 1.0) : 0;

    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween<double>(begin: 0, end: percentage),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Stack(
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
              builder: (context, constraints) {
                return Container(
                  height: 6,
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: const Color(0xFFFF8A50),
              width: double.infinity,
              child: const Text(
                'จำนวนถุงยางอนามัย',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: _quantities.entries.map((entry) {
                  // Calculate max allowed for this row: current value + remaining quota
                  final int totalUsed = _currentMonthlyUsed + _totalSelected;
                  final int remainingForThisRow = (_maxMonthlyQuota - totalUsed)
                      .clamp(0, _maxMonthlyQuota);
                  final int maxAllowed = entry.value + remainingForThisRow;

                  return StepperRowCondom(
                    label: '${entry.key}',
                    count: entry.value,
                    max: maxAllowed,
                    onChanged: (val) {
                      setState(() => _quantities[entry.key] = val);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'รวม',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Align with StepperRow: Button(26) + Space(12) = 38
                  const SizedBox(width: 38),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        '$_totalSelected',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Gap
                  const SizedBox(width: 14),
                  // Right Unit (Matches Right Button width)
                  const SizedBox(
                    width: 26,
                    child: Center(
                      child: Text(
                        'ชิ้น',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildLubricantCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: const Color(0xFFFF8A50),
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'เพิ่มเติม',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  final int totalLubricantUsed =
                      _currentMonthlyLubricantUsed + _lubricantQuantity;
                  final int remainingLubricant =
                      (_maxMonthlyLubricantQuota - totalLubricantUsed).clamp(
                        0,
                        _maxMonthlyLubricantQuota,
                      );
                  final int maxLubricantAllowed =
                      _lubricantQuantity + remainingLubricant;

                  return StepperLubricant(
                    label: 'สารหล่อลื่น',
                    count: _lubricantQuantity,
                    max: maxLubricantAllowed,
                    onChanged: (val) {
                      setState(() => _lubricantQuantity = val);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceTimeCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: const Color(0xFFFF8A50),
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'จุดบริการ วันและเวลารับ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('จุดบริการ'),
                        value: _selectedLocation,
                        items:
                            [
                                  'รพ.โพนพิสัย',
                                  'รพ.สต.วัดหลวง',
                                  'อบต.วัดหลวง',
                                  'สสจ.หนองคาย',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedLocation = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Row
                  Row(
                    children: [
                      // Date Picker
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(
                                text: _selectedDate == null
                                    ? ''
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              ),
                              decoration: InputDecoration(
                                labelText: 'วันที่',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: const Icon(Icons.calendar_month),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Time Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TimeOfDay>(
                              isExpanded: true,
                              hint: const Text('เลือกเวลา'),
                              value: _selectedTime,
                              items: const [
                                DropdownMenuItem(
                                  value: TimeOfDay(hour: 10, minute: 0),
                                  child: Text('10:00 น.'),
                                ),
                                DropdownMenuItem(
                                  value: TimeOfDay(hour: 14, minute: 0),
                                  child: Text('14:00 น.'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedTime = val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: const Color(0xFFFF8A50),
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.comment_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'ฝากข้อความ (ไม่ระบุได้)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความที่นี่...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
