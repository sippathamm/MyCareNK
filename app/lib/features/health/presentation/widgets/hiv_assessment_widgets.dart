import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/hiv_assessment_data.dart';

/// Landing view shown before the assessment starts: title, intro copy, the
/// section breakdown box, and the disclaimer.
class AssessmentIntro extends StatelessWidget {
  const AssessmentIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          l10n.hivAssessmentFullTitle,
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
              TextSpan(text: l10n.assessmentIntroPart1),
              TextSpan(
                text: l10n.assessmentIntroHighlight,
                style: GoogleFonts.googleSans(
                  color: AppColors.avatarIcon,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: l10n.assessmentIntroPart2),
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
                l10n.assessmentContains,
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.avatarIcon,
                ),
              ),
              const SizedBox(height: 8),
              _sectionEntry(l10n.questionCountLabel(4),
                  l10n.assessmentSectionLabel(1), l10n.sectionBehavior),
              _sectionEntry(l10n.questionCountLabel(2),
                  l10n.assessmentSectionLabel(2), l10n.sectionHealthBehavior),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.assessmentDisclaimer,
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionEntry(String count, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}

/// A single selectable answer option (key chip + label + optional sub-label).
class AssessmentOptionTile extends StatelessWidget {
  final AssessmentOption option;
  final bool selected;
  final VoidCallback onTap;
  const AssessmentOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.avatarBackground : Colors.white,
          border: Border.all(
            color: selected ? AppColors.avatarIcon : const Color(0xFFE0E0E0),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.avatarIconShadow
                  : const Color(0x0A000000),
              blurRadius: selected ? 10 : 4,
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
                color:
                    selected ? AppColors.avatarIcon : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  option.key,
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textMuted,
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
                    option.label,
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  if (option.sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      option.sub,
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
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle,
                  color: AppColors.avatarIcon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Collapsible "view your answers" panel shown on the result screen.
class AnswerSummary extends StatefulWidget {
  final Map<int, String> answers;
  final List<AssessmentQuestion> questions;
  const AnswerSummary({super.key, required this.answers, required this.questions});

  @override
  State<AnswerSummary> createState() => _AnswerSummaryState();
}

class _AnswerSummaryState extends State<AnswerSummary> {
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

/// Health-gradient primary button used by the assessment flow.
class AssessmentPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const AssessmentPrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onPressed,
      label: label,
      gradientColors: GradientButton.healthGradient,
    );
  }
}

/// Health-outlined secondary button used by the assessment flow.
class AssessmentOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const AssessmentOutlinedButton({super.key, required this.label, this.onPressed});

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
