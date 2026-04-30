import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _Reason {
  final String key;
  final String label;
  final IconData icon;
  const _Reason(this.key, this.label, this.icon);
}

class _Location {
  final String key;
  final String label;
  final String hours;
  const _Location(this.key, this.label, this.hours);
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

final _kLocations = <_Location>[
  _Location('phonphisai', 'รพ.โพนพิสัย', 'จ–ศ 08:00–16:00'),
  _Location('wat', 'รพ.สต.วัดหลวง', 'จ–ศ 08:00–16:00'),
  _Location('abt', 'อบต.วัดหลวง', 'จ–ศ 08:30–16:30'),
  _Location('ssj', 'สสจ.หนองคาย', 'จ–ศ 08:00–17:00'),
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
  late final String _refNum;

  int _step = 0;
  String? _reason;
  String? _location;
  String? _dateKey;
  String? _timeSlot;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason = widget.initialReason;
    _refNum = 'NK-APT-${10000 + Random().nextInt(90000)}';
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
  _Location? get _selectedLocation =>
      _kLocations.where((l) => l.key == _location).firstOrNull;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftIdx = i ~/ 2;
            final done = leftIdx < _step;
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
          final isDone = idx < _step;
          final isCurrent = idx == _step;
          final color = (isDone || isCurrent) ? AppColors.primary : const Color(0xFFE8E8E8);
          final textColor = (isDone || isCurrent) ? Colors.white : AppColors.textMuted;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: (isDone || isCurrent) ? FontWeight.w700 : FontWeight.w400,
                  color: (isDone || isCurrent) ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
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
                    child: Column(
                      children: List.generate(
                        _kLocations.length,
                        (i) => _buildLocationTile(_kLocations[i], i),
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
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'เช่น อาการที่มี หรือยาที่ใช้อยู่...',
                        hintStyle: const TextStyle(
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
          color: sel ? AppColors.primaryCardStart : Colors.white,
          border: Border.all(
            color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
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
                color: sel ? AppColors.primary : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(r.icon,
                  color: sel ? Colors.white : AppColors.textMuted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                r.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(_Location loc, int index) {
    final sel = _location == loc.key;
    return GestureDetector(
      onTap: () => setState(() => _location = loc.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryCardStart : Colors.white,
          border: Border.all(
            color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
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
                color: sel ? AppColors.primary : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
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
                    loc.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text('${loc.hours} น.',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textHint)),
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
                color: sel ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    d.dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: sel
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textHint,
                    ),
                  ),
                  Text(
                    '${d.date.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    d.monthLabel,
                    style: TextStyle(
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
          style: const TextStyle(
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
                  color: sel ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: sel ? AppColors.primary : const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$t น.',
                  style: TextStyle(
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
    final rows = [
      (Icons.medical_services_outlined, 'เรื่อง', _selectedReason?.label ?? ''),
      (Icons.local_hospital_outlined, 'สถานพยาบาล', _selectedLocation?.label ?? ''),
      (Icons.access_time_outlined, 'เวลาทำการ', '${_selectedLocation?.hours ?? ''} น.'),
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
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ]),
                                      Flexible(
                                        child: Text(
                                          row.$3,
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
                                const Text('บันทึกเพิ่มเติม',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textHint)),
                                const SizedBox(height: 4),
                                Text(_noteCtrl.text,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
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
                            'หากต้องการยกเลิกหรือเปลี่ยนแปลงนัด โปรดติดต่อสถานพยาบาลล่วงหน้าอย่างน้อย 24 ชม.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5D4037),
                              height: 1.6,
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
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              children: [
                _PrimaryBtn(
                  label: 'ยืนยันการนัดหมาย',
                  onPressed: () => setState(() => _step = 2),
                ),
                const SizedBox(height: 10),
                _OutlinedBtn(
                  label: 'แก้ไข',
                  onPressed: () => setState(() => _step = 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Success ─────────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final infoRows = [
      (Icons.local_hospital_outlined, 'สถานพยาบาล', _selectedLocation?.label ?? ''),
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
      body: SingleChildScrollView(
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
              child: const Icon(Icons.check, color: AppColors.success, size: 52),
            ),
            const SizedBox(height: 20),
            const Text(
              'นัดหมายสำเร็จ!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'เราได้รับคำขอนัดหมายของคุณแล้ว',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
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
                                  color: AppColors.primaryCardStart,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(row.$1,
                                    color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.$2,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint)),
                                  Text(row.$3,
                                      style: const TextStyle(
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
              'หมายเลขอ้างอิง: $_refNum',
              style: const TextStyle(fontSize: 14, color: AppColors.textHint),
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
                  const Text(
                    'สิ่งที่ควรทำก่อนวันนัด',
                    style: TextStyle(
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
                                color: AppColors.success, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(t,
                                  style: const TextStyle(
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
              label: 'กลับหน้าหลัก',
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            const SizedBox(height: 10),
            _OutlinedBtn(
              label: 'ดูประวัติการนัด',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ประวัติการนัดหมาย — เร็วๆ นี้'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String title, VoidCallback onBack) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppColors.primary,
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
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
              color: AppColors.primary,
              width: double.infinity,
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
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
  const _PrimaryBtn({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              onPressed != null ? AppColors.primary : Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
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
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
