import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import 'doctor_booking_page.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

enum _RiskLevel { low, medium, high }

class _Option {
  final String key;
  final String label;
  final String sub;
  const _Option(this.key, this.label, [this.sub = '']);
}

class _Question {
  final int section;
  final String sectionLabel;
  final String text;
  final IconData icon;
  final List<_Option> options;
  const _Question({
    required this.section,
    required this.sectionLabel,
    required this.text,
    required this.icon,
    required this.options,
  });
}

final _kQuestions = <_Question>[
  _Question(
    section: 1,
    sectionLabel: 'พฤติกรรมทางเพศ',
    text: 'คุณใช้ถุงยางอนามัยเมื่อมีเพศสัมพันธ์บ่อยแค่ไหน?',
    icon: Icons.health_and_safety,
    options: [
      _Option('ก', 'ใช้ทุกครั้ง', 'ทั้งทางช่องคลอดและทางทวารหนัก'),
      _Option('ข', 'ใช้เกือบทุกครั้ง', 'มีพลาดหรือผิดพลาดบางครั้ง'),
      _Option('ค', 'ไม่ได้ใช้เป็นประจำ', 'ไม่สวมถุงยางอนามัยบ่อยครั้ง'),
    ],
  ),
  _Question(
    section: 1,
    sectionLabel: 'พฤติกรรมทางเพศ',
    text: 'คุณเคยมีถุงยางอนามัยแตกหรือหลุดระหว่างมีเพศสัมพันธ์หรือไม่?',
    icon: Icons.warning_amber,
    options: [
      _Option('ก', 'ไม่เคยเกิดขึ้น', 'ไม่มีอุบัติเหตุดังกล่าว'),
      _Option('ข', 'เคยเกิดขึ้น แต่รับยา PEP ทันที', 'ดำเนินการป้องกันเสมอ'),
      _Option('ค', 'เคยเกิดขึ้นและไม่ได้ป้องกัน', 'ไม่ได้รับยาหรือดำเนินการใดๆ'),
    ],
  ),
  _Question(
    section: 1,
    sectionLabel: 'พฤติกรรมทางเพศ',
    text: 'คุณเคยทำออรัลเซ็กซ์โดยไม่ป้องกันหรือไม่?',
    icon: Icons.face,
    options: [
      _Option('ก', 'ไม่เคย', 'ใช้ถุงยางอนามัยทุกครั้งหรือไม่มีแผลในปาก'),
      _Option('ข', 'เคย แต่ไม่มีการหลั่งในปาก', 'ไม่มีการสัมผัสของเหลวโดยตรง'),
      _Option('ค', 'เคย และมีการหลั่งหรือแผลในปาก', 'มีการสัมผัสของเหลวหรือเลือดโดยตรง'),
    ],
  ),
  _Question(
    section: 1,
    sectionLabel: 'พฤติกรรมทางเพศ',
    text: 'คุณเคยมีเพศสัมพันธ์กับคู่นอนที่มีความเสี่ยงหรือไม่?',
    icon: Icons.people,
    options: [
      _Option('ก', 'ไม่เคย', 'คู่นอนผลเลือดเป็นลบหรือป้องกันทุกครั้ง'),
      _Option('ข', 'ไม่ทราบสถานะ', 'ไม่ทราบผลตรวจหรือสถานะการติดเชื้อของคู่นอน'),
      _Option('ค', 'เคย และคู่นอนเสี่ยงสูง', 'ทราบว่าติดเชื้อหรือไม่ได้รักษา'),
    ],
  ),
  _Question(
    section: 2,
    sectionLabel: 'พฤติกรรมสุขภาพและโรคติดต่อ',
    text: 'คุณใช้สารเสพติดหรือไม่?',
    icon: Icons.medication,
    options: [
      _Option('ก', 'ไม่ใช้เลย', 'ไม่มีการใช้สารเสพติดใดๆ'),
      _Option('ข', 'ใช้ชนิดกิน / สูบ / ดม', 'อาจทำให้ขาดสติหรือละเลยการป้องกัน'),
      _Option('ค', 'ใช้ชนิดฉีด', 'และใช้เข็มร่วมกับผู้อื่น'),
    ],
  ),
  _Question(
    section: 2,
    sectionLabel: 'พฤติกรรมสุขภาพและโรคติดต่อ',
    text: 'คุณเคยเป็นโรคติดต่อทางเพศสัมพันธ์ (STIs) หรือไม่?',
    icon: Icons.biotech,
    options: [
      _Option('ก', 'ไม่เคย', 'ไม่มีอาการผิดปกติใดๆ'),
      _Option('ข', 'เคย แต่รักษาหายขาดแล้ว', 'ได้รับการรักษาจนครบถ้วน'),
      _Option('ค', 'มีอาการอยู่และยังไม่รักษา', 'ปัจจุบันยังมีอาการผิดปกติ'),
    ],
  ),
];

_RiskLevel _calcRisk(Map<int, String> answers) {
  final vals = answers.values.toList();
  if (vals.contains('ค')) return _RiskLevel.high;
  if (vals.where((v) => v == 'ข').length >= 2) return _RiskLevel.medium;
  return _RiskLevel.low;
}

// ─── Risk config ─────────────────────────────────────────────────────────────

class _RiskConfig {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  final String headline;
  final String advice;
  final List<String> pills;
  final bool hasCta;
  final String? bookingReason;
  const _RiskConfig({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
    required this.headline,
    required this.advice,
    required this.pills,
    required this.hasCta,
    this.bookingReason,
  });
}

final _kRiskConfigs = <_RiskLevel, _RiskConfig>{
  _RiskLevel.low: _RiskConfig(
    label: 'ความเสี่ยงต่ำ',
    color: AppColors.success,
    bg: Color(0xFFE8F5E9),
    icon: Icons.check_circle,
    headline: 'อยู่ในเกณฑ์ดีเยี่ยม',
    advice:
        'ควรรักษามาตรฐานการป้องกันอย่างต่อเนื่อง และแนะนำให้ตรวจเลือดทุก 6 เดือนเพื่อสุขภาวะที่ยั่งยืน',
    pills: ['ตรวจเลือดทุก 6 เดือน', 'รักษามาตรฐานต่อไป'],
    hasCta: false,
  ),
  _RiskLevel.medium: _RiskConfig(
    label: 'ความเสี่ยงปานกลาง',
    color: Color(0xFFFF8F00),
    bg: Color(0xFFFFF8E1),
    icon: Icons.warning,
    headline: 'ควรเฝ้าระวัง',
    advice:
        'เริ่มมีความเสี่ยงในการรับเชื้อ แนะนำให้ปรึกษาแพทย์เพื่อพิจารณาการใช้ยา PrEP และตรวจหาเชื้อทุก 3 เดือน',
    pills: ['ปรึกษาแพทย์เรื่อง PrEP', 'ตรวจหาเชื้อทุก 3 เดือน'],
    hasCta: true,
    bookingReason: 'prep',
  ),
  _RiskLevel.high: _RiskConfig(
    label: 'ความเสี่ยงสูง',
    color: AppColors.error,
    bg: Color(0xFFFFEBEE),
    icon: Icons.emergency,
    headline: 'เร่งด่วน — ควรพบแพทย์ทันที',
    advice:
        'มีความเสี่ยงสูงในการรับเชื้อ ควรพบแพทย์เพื่อตรวจเลือดโดยเร็ว หรือหากเพิ่งเสี่ยงมาไม่เกิน 72 ชั่วโมง ให้ขอรับยา PEP ทันที',
    pills: ['พบแพทย์เพื่อตรวจเลือด', 'ขอรับยา PEP ภายใน 72 ชม.'],
    hasCta: true,
    bookingReason: 'pep',
  ),
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class HivAssessmentPage extends StatefulWidget {
  const HivAssessmentPage({super.key});

  @override
  State<HivAssessmentPage> createState() => _HivAssessmentPageState();
}

class _HivAssessmentPageState extends State<HivAssessmentPage> {
  int _step = -1;
  final Map<int, String> _answers = {};
  String? _selected;
  int _animDir = 1;

  static const int _totalQ = 6;

  bool get _isDone => _step >= _totalQ;
  _Question? get _current =>
      _step >= 0 && _step < _totalQ ? _kQuestions[_step] : null;

  bool _visible = true;

  void _slide(int nextStep, int dir) {
    setState(() {
      _animDir = dir;
      _visible = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _step = nextStep;
        _selected = _answers[nextStep];
        _visible = true;
      });
    });
  }

  void _handleNext() {
    if (_step == -1) {
      _slide(0, 1);
      return;
    }
    if (_selected == null) return;
    _answers[_step] = _selected!;
    _slide(_step + 1, 1);
  }

  void _handleBack() {
    if (_step <= 0) {
      Navigator.of(context).pop();
      return;
    }
    _slide(_step - 1, -1);
  }

  void _reset() {
    _answers.clear();
    _slide(-1, -1);
  }

  @override
  Widget build(BuildContext context) {
    final risk = _isDone ? _calcRisk(_answers) : null;
    final riskCfg = risk != null ? _kRiskConfigs[risk]! : null;
    final cur = _current;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed:
              _isDone ? () => Navigator.of(context).pop() : _handleBack,
        ),
        title: Text(
          'ประเมินความเสี่ยงการติดเชื้อ HIV',
          style: GoogleFonts.googleSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_step >= 0 && !_isDone && cur != null) _buildProgress(cur),
          Expanded(
            child: AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedSlide(
                offset: _visible
                    ? Offset.zero
                    : Offset(_animDir * 0.06, 0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _step == -1
                      ? _buildIntro()
                      : _isDone
                          ? _buildResult(riskCfg!)
                          : _buildQuestion(cur!),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(_Question cur) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  cur.sectionLabel,
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_step + 1}/$_totalQ',
                style: GoogleFonts.googleSans(
                    fontSize: 14, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_step + 1) / _totalQ,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.avatarIcon),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [1, 2].map((s) {
              final active = cur.section == s;
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.avatarIcon
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ส่วนที่ $s',
                  style: GoogleFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 28),
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.avatarBackground,
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.biotech, color: AppColors.avatarIcon, size: 44),
        ),
        const SizedBox(height: 20),
        Text(
          'แบบประเมินความเสี่ยงการติดเชื้อ HIV',
          style: GoogleFonts.googleSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.googleSans(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
            children: [
              const TextSpan(text: 'โปรดพิจารณาพฤติกรรมของคุณในช่วง '),
              TextSpan(
                text: '3–6 เดือนที่ผ่านมา',
                style: GoogleFonts.googleSans(
                  color: AppColors.avatarIcon,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text:
                    ' และเลือกคำตอบที่ตรงกับความเป็นจริงมากที่สุด'
                    '\nเพื่อให้ได้ผลการประเมินที่แม่นยำ',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.avatarBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'แบบประเมินประกอบด้วย',
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.avatarIcon,
                ),
              ),
              const SizedBox(height: 8),
              _buildSectionEntry(
                  '4 ข้อ', 'ส่วนที่ 1', 'พฤติกรรมทางเพศ'),
              _buildSectionEntry(
                  '2 ข้อ', 'ส่วนที่ 2', 'พฤติกรรมสุขภาพและโรคติดต่อ'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ไม่มีการเก็บข้อมูลของคุณ ใช้เพื่อการประเมินความเสี่ยงเท่านั้น',
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryBtn(label: 'เริ่มทำแบบประเมิน', onPressed: _handleNext),
      ],
    );
  }

  Widget _buildSectionEntry(String count, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.avatarIcon,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: GoogleFonts.googleSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.googleSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.googleSans(
                    fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(_Question q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.avatarBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.avatarIcon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(q.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อที่ ${_step + 1}',
                      style: GoogleFonts.googleSans(
                        fontSize: 13,
                        color: AppColors.avatarIcon,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.text,
                      style: GoogleFonts.googleSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...q.options.map((opt) => _buildOption(opt)),
        const SizedBox(height: 24),
        AnimatedOpacity(
          opacity: _selected != null ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 150),
          child: _PrimaryBtn(
            label:
                _step == _totalQ - 1 ? 'ดูผลประเมิน' : 'ถัดไป',
            onPressed: _selected != null ? _handleNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(_Option opt) {
    final isSelected = _selected == opt.key;
    return GestureDetector(
      onTap: () => setState(() => _selected = opt.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.avatarBackground : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.avatarIcon
                : const Color(0xFFE0E0E0),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.avatarIconShadow
                  : const Color(0x0A000000),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.avatarIcon
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  opt.key,
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? Colors.white : AppColors.textMuted,
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
                    opt.label,
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  if (opt.sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      opt.sub,
                      style: GoogleFonts.googleSans(
                        fontSize: 13,
                        color: AppColors.textHint,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle,
                  color: AppColors.avatarIcon, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(_RiskConfig cfg) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: cfg.bg,
              shape: BoxShape.circle,
              border: Border.all(color: cfg.color, width: 4),
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          decoration: BoxDecoration(
            color: cfg.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            cfg.label,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cfg.color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          cfg.headline,
          style: GoogleFonts.googleSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            cfg.advice,
            style: GoogleFonts.googleSans(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: cfg.pills
              .map(
                (p) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: cfg.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    p,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cfg.color,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _buildKnowledgeBox(),
        const SizedBox(height: 20),
        _AnswerSummary(answers: Map.from(_answers)),
        const SizedBox(height: 20),
        if (cfg.hasCta) ...[
          _PrimaryBtn(
            label: 'นัดพบแพทย์',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DoctorBookingPage(initialReason: cfg.bookingReason),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _OutlinedBtn(label: 'ทำแบบประเมินใหม่', onPressed: _reset),
      ],
    );
  }

  Widget _buildKnowledgeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลเพิ่มเติม',
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildKnowledgeRow(
            'PrEP',
            'ยาสำหรับรับประทานก่อนสัมผัสความเสี่ยง ช่วยป้องกันการติดเชื้อ HIV ได้เกือบ 100%',
          ),
          _buildKnowledgeRow(
            'PEP',
            'ยาป้องกันฉุกเฉิน ต้องรับประทานให้เร็วที่สุดภายใน 72 ชั่วโมง หลังสัมผัสความเสี่ยง เพื่อยับยั้งการติดเชื้อเข้าสู่ร่างกาย',
          ),
          const SizedBox(height: 4),
          Text(
            'นอกจากการตรวจ HIV ควรตรวจคัดกรองมะเร็งปากมดลูกและซิฟิลิสเป็นประจำ เนื่องจากรอยโรคเหล่านี้ส่งผลให้เชื้อ HIV เข้าสู่ร่างกายได้ง่ายขึ้นหากเกิดบาดแผล',
            style: GoogleFonts.googleSans(
              fontSize: 12,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeRow(String term, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$term ',
                  style: GoogleFonts.googleSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.avatarIcon,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}

// ─── Answer Summary ───────────────────────────────────────────────────────────

class _AnswerSummary extends StatefulWidget {
  final Map<int, String> answers;
  const _AnswerSummary({required this.answers});

  @override
  State<_AnswerSummary> createState() => _AnswerSummaryState();
}

class _AnswerSummaryState extends State<_AnswerSummary> {
  bool _expanded = false;

  Color _answerColor(String key) {
    if (key == 'ก') return AppColors.success;
    if (key == 'ข') return const Color(0xFFFF8F00);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ดูคำตอบของคุณ',
                  style: GoogleFonts.googleSans(
                      fontSize: 14, color: AppColors.textHint),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _expanded
              ? Column(
                  children: widget.answers.entries.map((e) {
            final q = _kQuestions[e.key];
            final opt = q.options.firstWhere(
              (o) => o.key == e.value,
              orElse: () => q.options.first,
            );
            final col = _answerColor(e.value);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        e.value,
                        style: GoogleFonts.googleSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          opt.label,
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Shared button widgets ────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PrimaryBtn({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onPressed,
      label: label,
      gradientColors: GradientButton.healthGradient,
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
          side: const BorderSide(color: AppColors.avatarIcon, width: 2),
          foregroundColor: AppColors.avatarIcon,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          label,
          style: GoogleFonts.googleSans(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
