import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/models/service_center_model.dart';
import 'quota_progress_bar.dart';

/// Header summary on the condom-request page: this month's remaining condom and
/// lubricant quota with animated counters. Bumping [animationVersion] replays
/// the count-up (e.g. after a quota refetch or sign-out reset).
class MonthlyQuotaSummary extends StatelessWidget {
  final int currentCondomUsed;
  final int selectedCondoms;
  final int currentLubricantUsed;
  final int selectedLubricant;
  final int animationVersion;

  const MonthlyQuotaSummary({
    super.key,
    required this.currentCondomUsed,
    required this.selectedCondoms,
    required this.currentLubricantUsed,
    required this.selectedLubricant,
    required this.animationVersion,
  });

  @override
  Widget build(BuildContext context) {
    final int totalUsed = currentCondomUsed + selectedCondoms;
    final int remaining = (AppConstants.maxCondomQuota - totalUsed)
        .clamp(0, AppConstants.maxCondomQuota);
    final int totalLubricantUsed = currentLubricantUsed + selectedLubricant;
    final int remainingLubricant =
        (AppConstants.maxLubricantQuota - totalLubricantUsed)
            .clamp(0, AppConstants.maxLubricantQuota);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).freeQuotaThisMonth,
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
                    AppLocalizations.of(context).condoms,
                    style: GoogleFonts.googleSans(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  TweenAnimationBuilder<int>(
                    key: ValueKey('condom_num_$animationVersion'),
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
                          text: AppLocalizations.of(context).pieces,
                          style: GoogleFonts.googleSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  QuotaProgressBar(
                    key: ValueKey('condom_bar_$animationVersion'),
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
                    AppLocalizations.of(context).lubricant,
                    style: GoogleFonts.googleSans(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  TweenAnimationBuilder<int>(
                    key: ValueKey('lubricant_num_$animationVersion'),
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
                          text: AppLocalizations.of(context).pieces,
                          style: GoogleFonts.googleSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lubricant),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  QuotaProgressBar(
                    key: ValueKey('lubricant_bar_$animationVersion'),
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
}

/// A single selectable service-center row in the request form's center list.
class ServiceCenterPickerTile extends StatelessWidget {
  final ServiceCenterModel center;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const ServiceCenterPickerTile({
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
          color: selected ? AppColors.primaryCardStart : Colors.white,
          border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE8E8E8),
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
                color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
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
                  if (center.operatingHours != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      center.operatingHours!,
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Horizontal strip of selectable pickup dates. Shows a hint instead when no
/// center is chosen yet or the chosen center has condom service disabled.
class PickupDateStrip extends StatelessWidget {
  final ServiceCenterModel? center;
  final List<DateTime> dates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  const PickupDateStrip({
    super.key,
    required this.center,
    required this.dates,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (center == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            AppLocalizations.of(context).selectServiceCenterFirst,
            style: GoogleFonts.googleSans(
                fontSize: 14, color: AppColors.textHint),
          ),
        ),
      );
    }
    if (!center!.condomServiceEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            AppLocalizations.of(context).noCondomService,
            style: GoogleFonts.googleSans(
                fontSize: 14, color: AppColors.textHint),
          ),
        ),
      );
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = dates[i];
          final l10n = AppLocalizations.of(context);
          final dow = d.weekday == 7 ? 0 : d.weekday;
          final sel = selectedDate != null &&
              selectedDate!.year == d.year &&
              selectedDate!.month == d.month &&
              selectedDate!.day == d.day;
          return GestureDetector(
            onTap: () => onSelect(d),
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
}

/// Morning/afternoon pickup-time chips sourced from the center's [pickupTimes].
/// Shows a hint instead when no center is chosen or condom service is disabled.
class PickupTimePicker extends StatelessWidget {
  final ServiceCenterModel? center;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onSelect;

  const PickupTimePicker({
    super.key,
    required this.center,
    required this.selectedTime,
    required this.onSelect,
  });

  static int _hourOf(String t) => int.tryParse(t.split(':').first) ?? 0;

  @override
  Widget build(BuildContext context) {
    final center = this.center;
    if (center == null || !center.condomServiceEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            center == null
                ? AppLocalizations.of(context).selectServiceCenterFirst
                : AppLocalizations.of(context).noCondomService,
            style: GoogleFonts.googleSans(
                fontSize: 14, color: AppColors.textHint),
          ),
        ),
      );
    }

    Widget chip(String t) {
      final parts = t.split(':');
      final tod =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final sel = selectedTime == tod;
      return GestureDetector(
        onTap: () => onSelect(tod),
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
          child: Builder(builder: (context) => Text(
            '$t ${AppLocalizations.of(context).timeWithUnit}',
            style: GoogleFonts.googleSans(
              fontSize: 15,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: sel ? Colors.white : AppColors.textPrimary,
            ),
          )),
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

    final times = center.pickupTimes;
    final morning = times.where((t) => _hourOf(t) < 12).toList();
    final afternoon = times.where((t) => _hourOf(t) >= 12).toList();

    Widget dash() => Text('–',
        style: GoogleFonts.googleSans(
            fontSize: 15, color: AppColors.textHint));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(AppLocalizations.of(context).morning),
        morning.isNotEmpty
            ? Wrap(spacing: 8, runSpacing: 8, children: morning.map(chip).toList())
            : dash(),
        const SizedBox(height: 14),
        label(AppLocalizations.of(context).afternoon),
        afternoon.isNotEmpty
            ? Wrap(spacing: 8, runSpacing: 8, children: afternoon.map(chip).toList())
            : dash(),
      ],
    );
  }
}
