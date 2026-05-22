import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/gradient_button.dart';
import 'request_history_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

class CondomRequestSuccessPage extends StatelessWidget {
  final Map<int, int> quantities;
  final int lubricantQuantity;
  final String? selectedServiceCenter;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String message;
  final String referenceNumber;

  const CondomRequestSuccessPage({
    super.key,
    required this.quantities,
    required this.lubricantQuantity,
    this.selectedServiceCenter,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.referenceNumber,
  });

  int get _totalSelected =>
      quantities.values.fold(0, (sum, c) => sum + c);

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return '-';
    return '${date.day} ${l10n.monthsFull[date.month]} ${date.year + 543}';
  }

  String _formatTime(TimeOfDay? time, AppLocalizations l10n) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${l10n.timeWithUnit}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final infoRows = [
      (Icons.local_hospital_outlined, l10n.serviceCenterLabel, selectedServiceCenter ?? '-'),
      (Icons.event_outlined, l10n.dateLabel, _formatDate(selectedDate, l10n)),
      (Icons.schedule_outlined, l10n.timeLabel, _formatTime(selectedTime, l10n)),
      if (_totalSelected > 0)
        (Icons.inventory_2_outlined, l10n.condoms, '$_totalSelected ${l10n.pieces}'),
      if (lubricantQuantity > 0)
        (Icons.add_circle_outline, l10n.lubricant, '$lubricantQuantity ${l10n.pieces}'),
      if (message.isNotEmpty)
        (Icons.comment_outlined, l10n.messageLabel, message),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          l10n.requestPageTitle,
          style: GoogleFonts.googleSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            tooltip: l10n.requestHistory,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RequestHistoryPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: _buildStepIndicator(2, context),
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
                      border: Border.all(
                          color: AppColors.statusCompleted, width: 3),
                    ),
                    child: const Icon(Icons.check,
                        color: AppColors.statusCompleted, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.requestSuccessTitle,
                    style: GoogleFonts.googleSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.requestSuccessMessage,
                    style: GoogleFonts.googleSans(
                        fontSize: 15, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.cardShadowMedium,
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryDark, AppColors.primary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_note_outlined,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.requestDetails,
                                    style: GoogleFonts.googleSans(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: infoRows
                                  .map((row) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryCardStart,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(row.$1,
                                                  color: AppColors.primary,
                                                  size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(row.$2,
                                                      style: GoogleFonts.googleSans(
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .textHint)),
                                                  Text(row.$3,
                                                      style: GoogleFonts.googleSans(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.referencePrefix(referenceNumber),
                    style: GoogleFonts.googleSans(
                        fontSize: 14, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    label: l10n.backToService,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RequestHistoryPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(l10n.viewRequestHistory,
                          style: GoogleFonts.googleSans(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildStepIndicator(int step, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.stepForm, l10n.stepConfirm, l10n.stepSuccess];
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
        decoration: BoxDecoration(color: active ? AppColors.primary : const Color(0xFFE8E8E8), shape: BoxShape.circle),
        child: Center(child: showCheck
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text('${idx + 1}', style: GoogleFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textMuted))),
      ));
      if (!isLast) {
        iconItems.addAll([
          const SizedBox(width: gap),
          Expanded(child: Container(height: 3, decoration: BoxDecoration(color: idx < step ? AppColors.primary : const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)))),
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
            return GoogleFonts.googleSans(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? AppColors.primary : AppColors.textMuted);
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
