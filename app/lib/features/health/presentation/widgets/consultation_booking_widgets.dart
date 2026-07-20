import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/service_center_model.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_card.dart';

/// The three-node progress header (select → confirm → success) shown above
/// every step of the consultation booking flow. [step] is the zero-based active step.
class BookingStepIndicator extends StatelessWidget {
  final int step;
  const BookingStepIndicator({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.bookingSelectService, l10n.stepConfirm, l10n.stepSuccess];
    const double nodeSize = 34;
    const double gap = 6;
    final n = labels.length;

    final iconItems = <Widget>[];
    for (int idx = 0; idx < n; idx++) {
      final isDone = idx < step;
      final isCurrent = idx == step;
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
          Expanded(child: Container(height: 3, decoration: BoxDecoration(color: idx < step ? AppColors.lubricant : const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)))),
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
            final active = idx <= step;
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
}

/// The shared [SectionCard] with the lubricant-themed gradient header used
/// throughout the consultation booking flow.
class BookingSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const BookingSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      headerColors: const [AppColors.lubricantDark, AppColors.statusPreparing],
      child: child,
    );
  }
}

/// Lubricant-gradient primary button used by the booking flow.
class BookingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const BookingPrimaryButton(
      {super.key, required this.label, this.onPressed, this.isLoading = false});

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

/// Lubricant-outlined secondary button used by the booking flow.
class BookingOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const BookingOutlinedButton({super.key, required this.label, this.onPressed});

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

/// Selectable reason tile (icon + label + check) in the booking form.
class ReasonTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;
  const ReasonTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF5F5F5)
              : selected
                  ? AppColors.statusPreparingLight
                  : Colors.white,
          border: Border.all(
            color: disabled
                ? const Color(0xFFE0E0E0)
                : selected
                    ? AppColors.lubricant
                    : const Color(0xFFE8E8E8),
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
                color: disabled
                    ? const Color(0xFFEAEAEA)
                    : selected
                        ? AppColors.lubricant
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: disabled
                      ? const Color(0xFFBDBDBD)
                      : selected
                          ? Colors.white
                          : AppColors.textMuted,
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: disabled ? const Color(0xFFBDBDBD) : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.lubricant, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Selectable service-center tile (numbered + name + operating hours) in the
/// booking form.
class ConsultationLocationTile extends StatelessWidget {
  final ServiceCenterModel center;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const ConsultationLocationTile({
    super.key,
    required this.center,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.statusPreparingLight : Colors.white,
          border: Border.all(
            color: selected ? AppColors.lubricant : const Color(0xFFE8E8E8),
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
                color: selected ? AppColors.lubricant : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.googleSans(
                    fontSize: 15,
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
                    center.name,
                    style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (center.operatingHours != null)
                    Text(center.operatingHours!,
                        style: GoogleFonts.googleSans(
                            fontSize: 14, color: AppColors.textHint)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.lubricant, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Horizontal date strip for the booking form. Shows a placeholder message when
/// no center is selected or the center does not offer consultations.
class ConsultationDateStrip extends StatelessWidget {
  final ServiceCenterModel? location;
  final List<DateTime> dates;
  final String? dateKey;
  final ValueChanged<String> onSelect;
  const ConsultationDateStrip({
    super.key,
    required this.location,
    required this.dates,
    required this.dateKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loc = location;
    if (loc == null) {
      return _placeholder(l10n.selectServiceCenterFirst);
    }
    if (!loc.consultationServiceEnabled) {
      return _placeholder(l10n.noConsultationService);
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = dates[i];
          final dow = d.weekday == 7 ? 0 : d.weekday;
          final key = d.toIso8601String().substring(0, 10);
          final sel = dateKey == key;
          return GestureDetector(
            onTap: () => onSelect(key),
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
                    l10n.daysShort[dow],
                    style: GoogleFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: sel
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textHint,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: GoogleFonts.googleSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    l10n.monthsShort[d.month],
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

  Widget _placeholder(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(text,
              style:
                  GoogleFonts.googleSans(fontSize: 14, color: AppColors.textHint)),
        ),
      );
}

/// Morning/afternoon time-slot picker for the booking form. Shows a placeholder
/// message when no center is selected or the center does not offer consultations.
class ConsultationTimePicker extends StatelessWidget {
  final ServiceCenterModel? location;
  final String? locationName;
  final String? selectedTime;
  final ValueChanged<String> onSelect;
  const ConsultationTimePicker({
    super.key,
    required this.location,
    required this.locationName,
    required this.selectedTime,
    required this.onSelect,
  });

  static int _hourOf(String t) => int.tryParse(t.split(':').first) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loc = location;
    final times = loc?.consultationTimes ?? [];
    if (loc == null || !loc.consultationServiceEnabled || times.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            locationName == null
                ? l10n.selectServiceCenterFirst
                : l10n.noConsultationService,
            style:
                GoogleFonts.googleSans(fontSize: 14, color: AppColors.textHint),
          ),
        ),
      );
    }
    final morning = times.where((t) => _hourOf(t) < 12).toList();
    final afternoon = times.where((t) => _hourOf(t) >= 12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slotGroup(context, l10n.morning, morning),
        const SizedBox(height: 14),
        _slotGroup(context, l10n.afternoon, afternoon),
      ],
    );
  }

  Widget _slotGroup(BuildContext context, String label, List<String> slots) {
    final l10n = AppLocalizations.of(context);
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
        if (slots.isEmpty)
          Text('–',
              style: GoogleFonts.googleSans(
                  fontSize: 15, color: AppColors.textHint))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((t) {
              final sel = selectedTime == t;
              return GestureDetector(
                onTap: () => onSelect(t),
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
                    '$t ${l10n.timeWithUnit}',
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
}
