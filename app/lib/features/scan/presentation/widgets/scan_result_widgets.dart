import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../service/data/models/condom_request_model.dart';

/// A label/value row with a trailing divider, used inside the result cards.
class ScanInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const ScanInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.googleSans(
                      fontSize: 14, color: AppColors.textSecondary)),
              Flexible(
                child: Text(
                  value,
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}

/// Rounded card with a primary-gradient header bar, used to group result info.
class ScanInfoCard extends StatelessWidget {
  final Widget header;
  final Widget content;
  final bool showDivider;
  final Widget? footer;
  const ScanInfoCard({
    super.key,
    required this.header,
    required this.content,
    this.showDivider = false,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: header,
            ),
            Padding(padding: const EdgeInsets.all(16), child: content),
            if (showDivider) const Divider(height: 1),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded status pill.
class ScanStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const ScanStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.googleSans(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Icon-in-circle + title row used as the header for non-preview result states.
class ScanSheetHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  const ScanSheetHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.googleSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Reference number + pickup-status icon + last-updated timestamp shown at the
/// top of the request preview.
class ScanPreviewHeader extends StatelessWidget {
  final CondomRequestModel request;
  const ScanPreviewHeader({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dt = request.updatedAt.toUtc().add(const Duration(hours: 7));
    final dateStr =
        '${dt.day} ${l10n.monthsFull[dt.month - 1]} ${dt.year + 543}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${l10n.timeWithUnit}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.referenceNumber,
              style: GoogleFonts.googleSans(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              request.referenceNumber,
              style: GoogleFonts.googleSans(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.statusReadyLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.statusReady,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.googleSans(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

/// Four-node pending→preparing→ready→completed progress tracker.
class ScanStatusTracker extends StatelessWidget {
  final CondomRequestModel request;
  const ScanStatusTracker({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: AppLocalizations.of(context).statusPending, status: RequestStatus.pending,   color: AppColors.primary),
      (label: AppLocalizations.of(context).statusPreparing, status: RequestStatus.preparing,  color: AppColors.statusPreparing),
      (label: AppLocalizations.of(context).statusReady, status: RequestStatus.ready,      color: AppColors.statusReady),
      (label: AppLocalizations.of(context).statusCompleted, status: RequestStatus.completed,  color: AppColors.statusCompleted),
    ];
    final currentIdx = steps.indexWhere((s) => s.status == request.status);
    const double nodeSize = 28;
    const double gap = 6;
    final n = steps.length;

    final iconItems = <Widget>[];
    for (int idx = 0; idx < n; idx++) {
      final step = steps[idx];
      final isDone = idx < currentIdx;
      final isCurrent = idx == currentIdx;
      final isLast = idx == n - 1;
      final showCheck = isDone || (isCurrent && isLast);
      iconItems.add(AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: nodeSize, height: nodeSize,
        decoration: BoxDecoration(
          color: (isDone || isCurrent) ? step.color : const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: showCheck
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text('${idx + 1}',
                  style: GoogleFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (isDone || isCurrent) ? Colors.white : AppColors.textMuted)),
        ),
      ));
      if (!isLast) {
        iconItems.addAll([
          const SizedBox(width: gap),
          Expanded(child: Container(height: 3, decoration: BoxDecoration(color: isDone ? step.color : const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(width: gap),
        ]);
      }
    }

    return Column(children: [
      Row(children: iconItems),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (context, constraints) {
        final W = constraints.maxWidth;
        final slotSpacing = (W - nodeSize) / (n - 1);
        TextStyle labelStyle(int idx) {
          final isDone = idx < currentIdx;
          final isCurrent = idx == currentIdx;
          return GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? steps[idx].color : isDone ? AppColors.textSecondary : AppColors.textMuted,
          );
        }
        return SizedBox(
          height: 16,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 0, top: 0, child: Text(steps[0].label, style: labelStyle(0))),
            Positioned(right: 0, top: 0, child: Text(steps[n - 1].label, style: labelStyle(n - 1))),
            for (int i = 1; i < n - 1; i++)
              Positioned(
                left: nodeSize / 2 + i * slotSpacing,
                top: 0,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: Text(steps[i].label, style: labelStyle(i)),
                ),
              ),
          ]),
        );
      }),
    ]);
  }
}

/// Condom-quantity breakdown card. Renders nothing when no condoms requested.
class ScanQuantityCard extends StatelessWidget {
  final CondomRequestModel request;
  const ScanQuantityCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final total = request.condomQuantities.values.fold(0, (s, v) => s + v);
    if (total == 0) return const SizedBox();

    final l10n = AppLocalizations.of(context);
    return ScanInfoCard(
      header: Row(children: [
        const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(l10n.condoms,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          ...request.condomQuantities.entries
              .where((e) => e.value > 0)
              .map((e) => ScanInfoRow(
                  label: '${l10n.sizeLabel} ${e.key} ${l10n.sizeMm}',
                  value: '${e.value} ${l10n.pieces}')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total,
                  style: GoogleFonts.googleSans(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('$total ${l10n.pieces}',
                  style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lubricant card. Renders nothing when no lubricant requested.
class ScanLubricantCard extends StatelessWidget {
  final CondomRequestModel request;
  const ScanLubricantCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    if (request.lubricantQuantity == 0) return const SizedBox();

    final l10n = AppLocalizations.of(context);
    return ScanInfoCard(
      header: Row(children: [
        const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(l10n.extra,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: ScanInfoRow(
          label: l10n.lubricant,
          value: '${request.lubricantQuantity} ${l10n.pieces}'),
    );
  }
}

/// Pickup service center / date / time card.
class ScanLocationCard extends StatelessWidget {
  final CondomRequestModel request;
  const ScanLocationCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String outputDate = request.selectedDate ?? '-';
    if (request.selectedDate != null && request.selectedDate!.contains('-')) {
      try {
        final d = DateTime.parse(request.selectedDate!);
        outputDate = '${d.day} ${l10n.monthsFull[d.month - 1]} ${d.year + 543}';
      } catch (_) {}
    }

    String outputTime = '-';
    if (request.selectedTime != null && request.selectedTime!.contains(':')) {
      final parts = request.selectedTime!.split(':');
      if (parts.length >= 2) outputTime = '${parts[0]}:${parts[1]} ${l10n.timeWithUnit}';
    }

    return ScanInfoCard(
      header: Row(children: [
        const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(l10n.pickupSectionTitle,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          ScanInfoRow(
              label: l10n.serviceCenterLabel,
              value: request.selectedServiceCenter ?? '-'),
          ScanInfoRow(label: l10n.dateLabel, value: outputDate),
          ScanInfoRow(label: l10n.timeLabel, value: outputTime),
        ],
      ),
    );
  }
}

/// Optional user-message card. Renders nothing when the message is empty.
class ScanMessageCard extends StatelessWidget {
  final CondomRequestModel request;
  const ScanMessageCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    if (request.message.isEmpty) return const SizedBox();

    return ScanInfoCard(
      header: Row(children: [
        const Icon(Icons.comment_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).messageLabel,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(request.message,
            style: GoogleFonts.googleSans(
                fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }
}
