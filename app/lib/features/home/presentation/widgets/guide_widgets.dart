import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';

enum GuideInfoBoxType { tip, note, important }

enum GuideStatusType { pending, preparing, ready, completed, cancelled }

class GuideSection extends StatelessWidget {
  final int number;
  final String title;
  final List<Widget> children;

  const GuideSection({
    super.key,
    required this.number,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: GoogleFonts.googleSans(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.googleSans(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideStepList extends StatelessWidget {
  final List<String> steps;

  const GuideStepList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 10 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.googleSans(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    step,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class GuideInfoBox extends StatelessWidget {
  final GuideInfoBoxType type;
  final String text;

  const GuideInfoBox({super.key, required this.type, required this.text});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final IconData iconData;

    switch (type) {
      case GuideInfoBoxType.tip:
        bg = AppColors.primaryBackground;
        textColor = AppColors.primaryDark;
        iconData = Icons.lightbulb_outline;
      case GuideInfoBoxType.note:
        bg = AppColors.statusPreparingLight;
        textColor = AppColors.infoNoteText;
        iconData = Icons.info_outline;
      case GuideInfoBoxType.important:
        bg = AppColors.errorLight;
        textColor = AppColors.errorDark;
        iconData = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuideStatusBadge extends StatelessWidget {
  final GuideStatusType status;
  final String label;

  const GuideStatusBadge({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;

    switch (status) {
      case GuideStatusType.pending:
        bg = AppColors.statusPendingLight;
        textColor = AppColors.primaryDark;
      case GuideStatusType.preparing:
        bg = AppColors.statusPreparingLight;
        textColor = AppColors.lubricantDark;
      case GuideStatusType.ready:
        bg = AppColors.statusReadyLight;
        textColor = AppColors.statusReady;
      case GuideStatusType.completed:
        bg = AppColors.statusCompletedLight;
        textColor = AppColors.success;
      case GuideStatusType.cancelled:
        bg = Colors.grey.shade100;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.googleSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class GuideTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const GuideTable({super.key, required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: headers.map((h) {
              return Expanded(
                child: Container(
                  color: AppColors.primaryBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Text(
                    h,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final isLast = i == rows.length - 1;
            return Container(
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row.map((cell) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Text(
                        cell,
                        style: GoogleFonts.googleSans(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class GuideWidgetTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<int>? columnFlex;

  const GuideWidgetTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnFlex,
  });

  @override
  Widget build(BuildContext context) {
    final flex = columnFlex ?? List.filled(headers.length, 1);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: headers.asMap().entries.map((e) {
              return Expanded(
                flex: flex[e.key],
                child: Container(
                  color: AppColors.primaryBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Text(
                    e.value,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final isLast = i == rows.length - 1;
            return Container(
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: row.asMap().entries.map((cellEntry) {
                  return Expanded(
                    flex: flex[cellEntry.key],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: cellEntry.value,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
