import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

enum RiskLevel { low, medium, high }

class AssessmentOption {
  final String key;
  final String label;
  final String sub;
  const AssessmentOption(this.key, this.label, [this.sub = '']);
}

class AssessmentQuestion {
  final int section;
  final String sectionLabel;
  final String text;
  final IconData icon;
  final List<AssessmentOption> options;
  const AssessmentQuestion({
    required this.section,
    required this.sectionLabel,
    required this.text,
    required this.icon,
    required this.options,
  });
}

List<AssessmentQuestion> buildAssessmentQuestions(AppLocalizations l10n) => [
  AssessmentQuestion(
    section: 0,
    sectionLabel: l10n.sectionPreScreening,
    text: l10n.q0Text,
    icon: Icons.emergency,
    options: [
      AssessmentOption('no', l10n.q0OptNoLabel, l10n.q0OptNoSub),
      AssessmentOption('yes', l10n.q0OptYesLabel, l10n.q0OptYesSub),
      AssessmentOption('unsure', l10n.q0OptUnsureLabel, l10n.q0OptUnsureSub),
    ],
  ),
  AssessmentQuestion(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q1Text,
    icon: Icons.health_and_safety,
    options: [
      AssessmentOption('ก', l10n.q1OptALabel, l10n.q1OptASub),
      AssessmentOption('ข', l10n.q1OptBLabel, l10n.q1OptBSub),
      AssessmentOption('ค', l10n.q1OptCLabel, l10n.q1OptCSub),
    ],
  ),
  AssessmentQuestion(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q2Text,
    icon: Icons.warning_amber,
    options: [
      AssessmentOption('ก', l10n.q2OptALabel, l10n.q2OptASub),
      AssessmentOption('ข', l10n.q2OptBLabel, l10n.q2OptBSub),
      AssessmentOption('ค', l10n.q2OptCLabel, l10n.q2OptCSub),
    ],
  ),
  AssessmentQuestion(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q3Text,
    icon: Icons.face,
    options: [
      AssessmentOption('ก', l10n.q3OptALabel, l10n.q3OptASub),
      AssessmentOption('ข', l10n.q3OptBLabel, l10n.q3OptBSub),
      AssessmentOption('ค', l10n.q3OptCLabel, l10n.q3OptCSub),
    ],
  ),
  AssessmentQuestion(
    section: 1,
    sectionLabel: l10n.sectionBehavior,
    text: l10n.q4Text,
    icon: Icons.people,
    options: [
      AssessmentOption('ก', l10n.q4OptALabel, l10n.q4OptASub),
      AssessmentOption('ข', l10n.q4OptBLabel, l10n.q4OptBSub),
      AssessmentOption('ค', l10n.q4OptCLabel, l10n.q4OptCSub),
    ],
  ),
  AssessmentQuestion(
    section: 2,
    sectionLabel: l10n.sectionHealthBehavior,
    text: l10n.q5Text,
    icon: Icons.medication,
    options: [
      AssessmentOption('ก', l10n.q5OptALabel, l10n.q5OptASub),
      AssessmentOption('ข', l10n.q5OptBLabel, l10n.q5OptBSub),
      AssessmentOption('ค', l10n.q5OptCLabel, l10n.q5OptCSub),
    ],
  ),
  AssessmentQuestion(
    section: 2,
    sectionLabel: l10n.sectionHealthBehavior,
    text: l10n.q6Text,
    icon: Icons.biotech,
    options: [
      AssessmentOption('ก', l10n.q6OptALabel, l10n.q6OptASub),
      AssessmentOption('ข', l10n.q6OptBLabel, l10n.q6OptBSub),
      AssessmentOption('ค', l10n.q6OptCLabel, l10n.q6OptCSub),
    ],
  ),
];

RiskLevel calcRisk(Map<int, String> answers) {
  if (answers[0] == 'yes') return RiskLevel.high;
  final vals = answers.entries.where((e) => e.key > 0).map((e) => e.value).toList();
  if (vals.contains('ค')) return RiskLevel.high;
  if (vals.where((v) => v == 'ข').length >= 2) return RiskLevel.medium;
  return RiskLevel.low;
}

/// Visual styling + booking behavior for each risk level. Result copy (label,
/// headline, advice, pills) is localized at render time, so it lives in l10n
/// rather than here.
class RiskConfig {
  final Color color;
  final Color bg;
  final IconData icon;
  final bool hasCta;
  final String? bookingReason;
  const RiskConfig({
    required this.color,
    required this.bg,
    required this.icon,
    required this.hasCta,
    this.bookingReason,
  });
}

const kRiskConfigs = <RiskLevel, RiskConfig>{
  RiskLevel.low: RiskConfig(
    color: AppColors.success,
    bg: Color(0xFFE8F5E9),
    icon: Icons.check_circle,
    hasCta: false,
  ),
  RiskLevel.medium: RiskConfig(
    color: Color(0xFFFF8F00),
    bg: Color(0xFFFFF8E1),
    icon: Icons.warning,
    hasCta: true,
    bookingReason: 'prep',
  ),
  RiskLevel.high: RiskConfig(
    color: AppColors.error,
    bg: Color(0xFFFFEBEE),
    icon: Icons.emergency,
    hasCta: true,
    bookingReason: 'pep',
  ),
};
