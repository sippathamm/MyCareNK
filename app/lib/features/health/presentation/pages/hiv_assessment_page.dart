import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import 'doctor_booking_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

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

List<_Question> _buildQuestions(AppLocalizations l10n) => [
  _Question(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q1Text,
    icon: Icons.health_and_safety,
    options: [
      _Option('ก', l10n.q1OptALabel, l10n.q1OptASub),
      _Option('ข', l10n.q1OptBLabel, l10n.q1OptBSub),
      _Option('ค', l10n.q1OptCLabel, l10n.q1OptCSub),
    ],
  ),
  _Question(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q2Text,
    icon: Icons.warning_amber,
    options: [
      _Option('ก', l10n.q2OptALabel, l10n.q2OptASub),
      _Option('ข', l10n.q2OptBLabel, l10n.q2OptBSub),
      _Option('ค', l10n.q2OptCLabel, l10n.q2OptCSub),
    ],
  ),
  _Question(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q3Text,
    icon: Icons.face,
    options: [
      _Option('ก', l10n.q3OptALabel, l10n.q3OptASub),
      _Option('ข', l10n.q3OptBLabel, l10n.q3OptBSub),
      _Option('ค', l10n.q3OptCLabel, l10n.q3OptCSub),
    ],
  ),
  _Question(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q4Text,
    icon: Icons.people,
    options: [
      _Option('ก', l10n.q4OptALabel, l10n.q4OptASub),
      _Option('ข', l10n.q4OptBLabel, l10n.q4OptBSub),
      _Option('ค', l10n.q4OptCLabel, l10n.q4OptCSub),
    ],
  ),
  _Question(
    section: 2,
    sectionLabel: l10n.sectionHealthBehavior,
    text: l10n.q5Text,
    icon: Icons.medication,
    options: [
      _Option('ก', l10n.q5OptALabel, l10n.q5OptASub),
      _Option('ข', l10n.q5OptBLabel, l10n.q5OptBSub),
      _Option('ค', l10n.q5OptCLabel, l10n.q5OptCSub),
    ],
  ),
  _Question(
    section: 2,
    sectionLabel: l10n.sectionHealthBehavior,
    text: l10n.q6Text,
    icon: Icons.biotech,
    options: [
      _Option('ก', l10n.q6OptALabel, l10n.q6OptASub),
      _Option('ข', l10n.q6OptBLabel, l10n.q6OptBSub),
      _Option('ค', l10n.q6OptCLabel, l10n.q6OptCSub),
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

const _kRiskConfigs = <_RiskLevel, _RiskConfig>{
  _RiskLevel.low: _RiskConfig(
    label: '',
    color: AppColors.success,
    bg: Color(0xFFE8F5E9),
    icon: Icons.check_circle,
    headline: '',
    advice: '',
    pills: [],
    hasCta: false,
  ),
  _RiskLevel.medium: _RiskConfig(
    label: '',
    color: Color(0xFFFF8F00),
    bg: Color(0xFFFFF8E1),
    icon: Icons.warning,
    headline: '',
    advice: '',
    pills: [],
    hasCta: true,
    bookingReason: 'prep',
  ),
  _RiskLevel.high: _RiskConfig(
    label: '',
    color: AppColors.error,
    bg: Color(0xFFFFEBEE),
    icon: Icons.emergency,
    headline: '',
    advice: '',
    pills: [],
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
    final l10n = AppLocalizations.of(context);
    final questions = _buildQuestions(l10n);
    final risk = _isDone ? _calcRisk(_answers) : null;
    final riskCfg = risk != null ? _kRiskConfigs[risk]! : null;
    final cur = _step >= 0 && _step < _totalQ ? questions[_step] : null;

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
          AppLocalizations.of(context).hivAssessmentTitle,
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
                          ? _buildResult(riskCfg!, risk!, l10n, questions)
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
                  cur.section == 1
                      ? AppLocalizations.of(context).sectionBehavior
                      : AppLocalizations.of(context).sectionHealthBehavior,
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
                  AppLocalizations.of(context).assessmentSectionLabel(s),
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
          AppLocalizations.of(context).hivAssessmentFullTitle,
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
              TextSpan(text: AppLocalizations.of(context).assessmentIntroPart1),
              TextSpan(
                text: AppLocalizations.of(context).assessmentIntroHighlight,
                style: GoogleFonts.googleSans(
                  color: AppColors.avatarIcon,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: AppLocalizations.of(context).assessmentIntroPart2),
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
                AppLocalizations.of(context).assessmentContains,
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.avatarIcon,
                ),
              ),
              const SizedBox(height: 8),
              _buildSectionEntry(AppLocalizations.of(context).questionCountLabel(4), AppLocalizations.of(context).assessmentSectionLabel(1), AppLocalizations.of(context).sectionBehavior),
              _buildSectionEntry(AppLocalizations.of(context).questionCountLabel(2), AppLocalizations.of(context).assessmentSectionLabel(2), AppLocalizations.of(context).sectionHealthBehavior),
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
            AppLocalizations.of(context).assessmentDisclaimer,
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryBtn(label: AppLocalizations.of(context).startAssessment, onPressed: _handleNext),
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
                      AppLocalizations.of(context).questionNumber(_step + 1),
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
            label: _step == _totalQ - 1
                ? AppLocalizations.of(context).viewAssessmentResult
                : AppLocalizations.of(context).next,
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

  Widget _buildResult(_RiskConfig cfg, _RiskLevel risk, AppLocalizations l10n, List<_Question> questions) {
    final localizedLabel = risk == _RiskLevel.low
        ? l10n.riskLow
        : risk == _RiskLevel.medium
            ? l10n.riskMedium
            : l10n.riskHigh;
    final localizedHeadline = risk == _RiskLevel.low
        ? l10n.riskLowHeadline
        : risk == _RiskLevel.medium
            ? l10n.riskMediumHeadline
            : l10n.riskHighHeadline;
    final localizedAdvice = risk == _RiskLevel.low
        ? l10n.riskLowAdvice
        : risk == _RiskLevel.medium
            ? l10n.riskMediumAdvice
            : l10n.riskHighAdvice;
    final localizedPills = risk == _RiskLevel.low
        ? l10n.riskLowPills
        : risk == _RiskLevel.medium
            ? l10n.riskMediumPills
            : l10n.riskHighPills;
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
            localizedLabel,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cfg.color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          localizedHeadline,
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
            localizedAdvice,
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
          children: localizedPills
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
        _AnswerSummary(answers: Map.from(_answers), questions: questions),
        const SizedBox(height: 20),
        if (cfg.hasCta) ...[
          _PrimaryBtn(
            label: AppLocalizations.of(context).bookDoctorTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DoctorBookingPage(initialReason: cfg.bookingReason),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _OutlinedBtn(label: AppLocalizations.of(context).reassess, onPressed: _reset),
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
            AppLocalizations.of(context).additionalInfo,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildKnowledgeRow('PrEP', AppLocalizations.of(context).prepMedDesc),
          _buildKnowledgeRow('PEP', AppLocalizations.of(context).pepMedDesc),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).hivScreeningNote,
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
  final List<_Question> questions;
  const _AnswerSummary({required this.answers, required this.questions});

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
                  AppLocalizations.of(context).viewYourAnswers,
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
            final q = widget.questions[e.key];
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
