import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/service_center_model.dart';
import '../../../../core/services/service_center_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'appointment_history_page.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _Reason {
  final String key;
  final String label;
  final IconData icon;
  const _Reason(this.key, this.label, this.icon);
}

class _BookingDate {
  final DateTime date;
  final String dayLabel;
  final String monthLabel;
  final String fullLabel;
  const _BookingDate({
    required this.date,
    required this.dayLabel,
    required this.monthLabel,
    required this.fullLabel,
  });
}

final _kReasons = <_Reason>[
  _Reason('pep', 'รับยา PEP (ฉุกเฉิน)', Icons.emergency),
  _Reason('prep', 'รับยา PrEP', Icons.medication),
  _Reason('hiv', 'ตรวจเลือด HIV', Icons.biotech),
  _Reason('consult', 'ปรึกษาทั่วไป', Icons.chat_bubble_outline),
];

final _kMorningSlots = [
  '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
];

final _kAfternoonSlots = [
  '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00',
];

final _thMonths = [
  '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];
final _thDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

List<_BookingDate> _getAvailableDates() {
  final dates = <_BookingDate>[];
  var d = DateTime.now();
  while (dates.length < 7) {
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      final dow = d.weekday == 7 ? 0 : d.weekday;
      dates.add(_BookingDate(
        date: d,
        dayLabel: _thDays[dow],
        monthLabel: _thMonths[d.month],
        fullLabel: '${d.day} ${_thMonths[d.month]} ${d.year + 543}',
      ));
    }
    d = d.add(const Duration(days: 1));
  }
  return dates;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class DoctorBookingPage extends StatefulWidget {
  final String? initialReason;
  const DoctorBookingPage({super.key, this.initialReason});

  @override
  State<DoctorBookingPage> createState() => _DoctorBookingPageState();
}

class _DoctorBookingPageState extends State<DoctorBookingPage> {
  final List<_BookingDate> _dates = _getAvailableDates();
  String _refNum = '';
  bool _isSubmitting = false;

  int _step = 0;
  String? _reason;
  String? _location; // stores center name directly
  String? _dateKey;
  String? _timeSlot;
  final TextEditingController _noteCtrl = TextEditingController();

  List<ServiceCenterModel> _centers = [];
  bool _centersLoading = true;

  @override
  void initState() {
    super.initState();
    _reason = widget.initialReason;
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final centers = await ServiceCenterService.fetchActive();
      if (mounted) setState(() { _centers = centers; _centersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _centersLoading = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _reason != null && _location != null && _dateKey != null && _timeSlot != null;

  _Reason? get _selectedReason =>
      _kReasons.where((r) => r.key == _reason).firstOrNull;
  ServiceCenterModel? get _selectedLocation =>
      _centers.where((c) => c.name == _location).firstOrNull;
  _BookingDate? get _selectedDate => _dates
      .where((d) => d.date.toIso8601String().substring(0, 10) == _dateKey)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    if (_step == 2) return _buildSuccess();
    if (_step == 1) return _buildConfirm();
    return _buildForm();
  }

  // ── Step indicator ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const labels = ['เลือกบริการ', 'ยืนยัน', 'สำเร็จ'];
    const double nodeSize = 34;
    const double gap = 6;
    final n = labels.length;

    final iconItems = <Widget>[];
    for (int idx = 0; idx < n; idx++) {
      final isDone = idx < _step;
      final isCurrent = idx == _step;
      final active = isDone || isCurrent;
      final isLast = idx == n - 1;
      final showCheck = isDone || (isCurrent && isLast);
      iconItems.add(AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: nodeSize, height: nodeSize,
        decoration: BoxDecoration(color: active ? AppColors.lubricant : const Color(0xFFE8E8E8), shape: BoxShape.circle),
        child: Center(child: showCheck
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text('${idx + 1}', style: GoogleFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textMuted))),
      ));
      if (!isLast) {
        iconItems.addAll([
          const SizedBox(width: gap),
          Expanded(child: Container(height: 3, decoration: BoxDecoration(color: idx < _step ? AppColors.lubricant : const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(width: gap),
        ]);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(children: [
        Row(children: iconItems),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, constraints) {
          final W = constraints.maxWidth;
          final slotSpacing = (W - nodeSize) / (n - 1);
          TextStyle labelStyle(int idx) {
            final active = idx <= _step;
            return GoogleFonts.googleSans(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? AppColors.lubricant : AppColors.textMuted);
          }
          return SizedBox(
            height: 16,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(left: 0, top: 0, child: Text(labels[0], style: labelStyle(0))),
              Positioned(right: 0, top: 0, child: Text(labels[n - 1], style: labelStyle(n - 1))),
              for (int i = 1; i < n - 1; i++)
                Positioned(
                  left: nodeSize / 2 + i * slotSpacing,
                  top: 0,
                  child: FractionalTranslation(translation: const Offset(-0.5, 0), child: Text(labels[i], style: labelStyle(i))),
                ),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar('นัดพบแพทย์', () => Navigator.of(context).pop()),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: _buildStepIndicator(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'เรื่องที่ต้องการพบแพทย์',
                    icon: Icons.medical_services_outlined,
                    child: Column(
                      children: _kReasons.map(_buildReasonTile).toList(),
                    ),
                  ),
                  _SectionCard(
                    title: 'สถานพยาบาล',
                    icon: Icons.local_hospital_outlined,
                    child: _centersLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _centers.isEmpty
                            ? GestureDetector(
                                onTap: _loadCenters,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text('ไม่สามารถโหลดข้อมูลได้ กดเพื่อลองใหม่',
                                        style: GoogleFonts.googleSans(
                                            fontSize: 14, color: AppColors.textHint)),
                                  ),
                                ),
                              )
                            : Column(
                                children: List.generate(
                                  _centers.length,
                                  (i) => _buildLocationTile(_centers[i], i),
                                ),
                              ),
                  ),
                  _SectionCard(
                    title: 'วันที่นัด',
                    icon: Icons.event_outlined,
                    child: _buildDatePicker(),
                  ),
                  _SectionCard(
                    title: 'เวลานัด',
                    icon: Icons.schedule_outlined,
                    child: _buildTimePicker(),
                  ),
                  _SectionCard(
                    title: 'บันทึกเพิ่มเติม (ไม่ระบุได้)',
                    icon: Icons.notes_outlined,
                    child: TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.googleSans(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'เช่น อาการที่มี หรือยาที่ใช้อยู่...',
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
                              color: AppColors.lubricant, width: 1.5),
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
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: AnimatedOpacity(
              opacity: _canProceed ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: _PrimaryBtn(
                label: 'ถัดไป',
                onPressed: _canProceed ? () => setState(() => _step = 1) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(_Reason r) {
    final sel = _reason == r.key;
    return GestureDetector(
      onTap: () => setState(() => _reason = r.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.statusPreparingLight : Colors.white,
          border: Border.all(
            color: sel ? AppColors.lubricant : const Color(0xFFE8E8E8),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sel ? AppColors.lubricant : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(r.icon,
                  color: sel ? Colors.white : AppColors.textMuted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                r.label,
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle, color: AppColors.lubricant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(ServiceCenterModel loc, int index) {
    final sel = _location == loc.name;
    return GestureDetector(
      onTap: () => setState(() => _location = loc.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.statusPreparingLight : Colors.white,
          border: Border.all(
            color: sel ? AppColors.lubricant : const Color(0xFFE8E8E8),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sel ? AppColors.lubricant : const Color(0xFFF5F5F5),
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
                    loc.name,
                    style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (loc.operatingHours != null)
                    Text('${loc.operatingHours} น.',
                        style: GoogleFonts.googleSans(
                            fontSize: 14, color: AppColors.textHint)),
                ],
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle, color: AppColors.lubricant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = _dates[i];
          final key = d.date.toIso8601String().substring(0, 10);
          final sel = _dateKey == key;
          return GestureDetector(
            onTap: () => setState(() => _dateKey = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 60,
              decoration: BoxDecoration(
                color: sel ? AppColors.lubricant : Colors.white,
                border: Border.all(
                  color: sel ? AppColors.lubricant : const Color(0xFFE8E8E8),
                  width: 1.5,
                ),
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

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlotGroup('ช่วงเช้า', _kMorningSlots),
        const SizedBox(height: 14),
        _buildSlotGroup('ช่วงบ่าย', _kAfternoonSlots),
      ],
    );
  }

  Widget _buildSlotGroup(String label, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((t) {
            final sel = _timeSlot == t;
            return GestureDetector(
              onTap: () => setState(() => _timeSlot = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.lubricant : Colors.white,
                  border: Border.all(
                    color: sel ? AppColors.lubricant : const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
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
          }).toList(),
        ),
      ],
    );
  }

  // ── Confirm ─────────────────────────────────────────────────────────────────

  Widget _buildConfirm() {
    final loc = _selectedLocation;
    final rows = [
      (Icons.medical_services_outlined, 'เรื่อง', _selectedReason?.label ?? ''),
      (Icons.local_hospital_outlined, 'สถานพยาบาล', loc?.name ?? ''),
      if (loc?.operatingHours != null)
        (Icons.access_time_outlined, 'เวลาทำการ', '${loc!.operatingHours} น.'),
      (Icons.event_outlined, 'วันที่', _selectedDate?.fullLabel ?? ''),
      (Icons.schedule_outlined, 'เวลา', '${_timeSlot ?? ''} น.'),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar('นัดพบแพทย์', () => setState(() => _step = 0)),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: _buildStepIndicator(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  _SectionCard(
                    title: 'สรุปการนัดหมาย',
                    icon: Icons.event_note_outlined,
                    child: Column(
                      children: [
                        ...rows.map((row) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        Icon(row.$1,
                                            color: AppColors.textMuted,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          row.$2,
                                          style: GoogleFonts.googleSans(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ]),
                                      Flexible(
                                        child: Text(
                                          row.$3,
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.googleSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(
                                      height: 1, color: Color(0xFFF0F0F0)),
                                ],
                              ),
                            )),
                        if (_noteCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('บันทึกเพิ่มเติม',
                                    style: GoogleFonts.googleSans(
                                        fontSize: 14,
                                        color: AppColors.textHint)),
                                const SizedBox(height: 4),
                                Text(_noteCtrl.text,
                                    style: GoogleFonts.googleSans(
                                        fontSize: 15,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'หากต้องการยกเลิกหรือเปลี่ยนแปลงนัด โปรดติดต่อสถานพยาบาลล่วงหน้าอย่างน้อย 24 ชม.',
                            style: GoogleFonts.googleSans(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
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
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              children: [
                _PrimaryBtn(
                  label: 'ยืนยันการนัดหมาย',
                  onPressed: _isSubmitting ? null : _submitBooking,
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: 10),
                _OutlinedBtn(
                  label: 'แก้ไข',
                  onPressed: _isSubmitting ? null : () => setState(() => _step = 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submitBooking() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.white,
          elevation: 24,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('กรุณาเข้าสู่ระบบ',
              style: GoogleFonts.googleSans(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('คุณต้องเข้าสู่ระบบก่อนจึงจะนัดพบแพทย์ได้',
              style: GoogleFonts.googleSans(fontSize: 15, height: 1.6)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            GradientButton(
              height: 46,
              onPressed: () async {
                Navigator.of(ctx).pop();
                final loggedIn = await Navigator.of(context, rootNavigator: true)
                    .push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
                if (loggedIn == true && mounted) _submitBooking();
              },
              label: 'เข้าสู่ระบบ',
              fontSize: 15,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEEEEEE),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: Text('ยกเลิก',
                    style: GoogleFonts.googleSans(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ref = await Supabase.instance.client.rpc(
        'create_doctor_appointment',
        params: {
          'p_user_id': userId,
          'p_reason': _reason,
          'p_service_center': _location,
          'p_date': _dateKey,
          'p_time': _timeSlot,
          'p_note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        },
      ) as String;

      if (mounted) setState(() { _refNum = ref; _step = 2; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
              style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Success ─────────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final infoRows = [
      (Icons.local_hospital_outlined, 'สถานพยาบาล', _selectedLocation?.name ?? ''),
      (Icons.event_outlined, 'วันที่', _selectedDate?.fullLabel ?? ''),
      (Icons.schedule_outlined, 'เวลา', '${_timeSlot ?? ''} น.'),
      (Icons.medical_services_outlined, 'เรื่อง', _selectedReason?.label ?? ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(
        'นัดพบแพทย์',
        () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: _buildStepIndicator(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.statusCompletedLight,
                border: Border.all(color: AppColors.statusCompleted, width: 3),
              ),
              child: const Icon(Icons.check, color: AppColors.statusCompleted, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'นัดหมายสำเร็จ!',
              style: GoogleFonts.googleSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'เราได้รับคำขอนัดหมายของคุณแล้ว',
              style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'รายละเอียดการนัดหมาย',
              icon: Icons.event_note_outlined,
              child: Column(
                children: infoRows
                    .map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.lubricantCardStart,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(row.$1,
                                    color: AppColors.lubricant, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.$2,
                                      style: GoogleFonts.googleSans(
                                          fontSize: 12,
                                          color: AppColors.textHint)),
                                  Text(row.$3,
                                      style: GoogleFonts.googleSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            Text(
              'รหัสอ้างอิง: $_refNum',
              style: GoogleFonts.googleSans(fontSize: 14, color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สิ่งที่ควรทำก่อนวันนัด',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    'งดอาหาร 4–6 ชม. ก่อนตรวจเลือด (ถ้ามี)',
                    'นำบัตรประชาชนมาด้วย',
                    'มาก่อนเวลานัด 15 นาที',
                  ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.statusCompleted, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(t,
                                  style: GoogleFonts.googleSans(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _PrimaryBtn(
              label: 'กลับหน้าบริการ',
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            const SizedBox(height: 10),
            _OutlinedBtn(
              label: 'ดูประวัติการนัด',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const AppointmentHistoryPage()),
                (route) => route.isFirst,
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String title, VoidCallback onBack) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: GoogleFonts.googleSans(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: AppColors.primary),
          tooltip: 'ประวัติการนัด',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AppointmentHistoryPage()),
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lubricantDark, AppColors.statusPreparing],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.googleSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _PrimaryBtn({required this.label, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onPressed,
      label: label,
      isLoading: isLoading,
      gradientColors: GradientButton.lubricantGradient,
    );
  }
}

class _OutlinedBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _OutlinedBtn({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.lubricant, width: 1.5),
          foregroundColor: AppColors.lubricant,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label,
            style: GoogleFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
