import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/gradient_button.dart';
import 'condom_request_success_page.dart';
import 'request_history_page.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

class CondomRequestConfirmPage extends StatefulWidget {
  final Map<int, int> quantities;
  final int lubricantQuantity;
  final String? selectedServiceCenter;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String message;
  final int currentMonthlyUsed;
  final int maxMonthlyQuota;
  final int currentMonthlyLubricantUsed;
  final int maxMonthlyLubricantQuota;

  const CondomRequestConfirmPage({
    super.key,
    required this.quantities,
    required this.lubricantQuantity,
    this.selectedServiceCenter,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.currentMonthlyUsed,
    required this.maxMonthlyQuota,
    required this.currentMonthlyLubricantUsed,
    required this.maxMonthlyLubricantQuota,
  });

  @override
  State<CondomRequestConfirmPage> createState() =>
      _CondomRequestConfirmPageState();
}

class _CondomRequestConfirmPageState extends State<CondomRequestConfirmPage> {
  bool _isLoading = false;

  int get _totalSelected =>
      widget.quantities.values.fold(0, (sum, count) => sum + count);

  Future<void> _submitRequest() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      final loggedIn = await Navigator.of(context, rootNavigator: true)
          .push<bool>(MaterialPageRoute(builder: (context) => const LoginPage()));
      if (loggedIn == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.current.loggedIn, style: GoogleFonts.googleSans()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = session.user.id;
      final quantitiesJson =
          widget.quantities.map((key, value) => MapEntry(key.toString(), value));

      String? dateString;
      if (widget.selectedDate != null) {
        dateString =
            '${widget.selectedDate!.year.toString().padLeft(4, '0')}-'
            '${widget.selectedDate!.month.toString().padLeft(2, '0')}-'
            '${widget.selectedDate!.day.toString().padLeft(2, '0')}';
      }

      String? timeString;
      if (widget.selectedTime != null) {
        timeString =
            '${widget.selectedTime!.hour.toString().padLeft(2, '0')}:'
            '${widget.selectedTime!.minute.toString().padLeft(2, '0')}:00';
      }

      final String refNumber = await Supabase.instance.client.rpc(
        'create_condom_request',
        params: {
          'p_user_id': userId,
          'p_condom_quantities': quantitiesJson,
          'p_lubricant_quantity': widget.lubricantQuantity,
          'p_selected_service_center': widget.selectedServiceCenter,
          'p_selected_date': dateString,
          'p_selected_time': timeString,
          'p_message': widget.message.isNotEmpty ? widget.message : null,
        },
      ) as String;

      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);

      final existingQuota = await Supabase.instance.client
          .from('user_monthly_quotas')
          .select('used_condoms, used_lubricants')
          .eq('user_id', userId)
          .eq('month', monthStart)
          .maybeSingle();

      final int newUsedCondoms =
          ((existingQuota?['used_condoms'] as int?) ?? 0) + _totalSelected;
      final int newUsedLubricants =
          ((existingQuota?['used_lubricants'] as int?) ?? 0) +
              widget.lubricantQuantity;

      await Supabase.instance.client.from('user_monthly_quotas').upsert({
        'user_id': userId,
        'month': monthStart,
        'used_condoms': newUsedCondoms,
        'used_lubricants': newUsedLubricants,
      }, onConflict: 'user_id, month');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CondomRequestSuccessPage(
              quantities: widget.quantities,
              lubricantQuantity: widget.lubricantQuantity,
              selectedServiceCenter: widget.selectedServiceCenter,
              selectedDate: widget.selectedDate,
              selectedTime: widget.selectedTime,
              message: widget.message,
              referenceNumber: refNumber,
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Error saving condom request: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.current.errorOccurred, style: GoogleFonts.googleSans()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).requestPageTitle,
          style: GoogleFonts.googleSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            tooltip: AppLocalizations.of(context).requestHistory,
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
            child: _buildStepIndicator(1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  _buildMonthlyProgress(),
                  const SizedBox(height: 20),
                  if (_totalSelected > 0) _buildQuantityCard(),
                  if (widget.lubricantQuantity > 0) _buildLubricantCard(),
                  _buildPlaceTimeCard(),
                  if (widget.message.isNotEmpty) _buildMessageCard(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).checkInfoMessage,
                            style: GoogleFonts.googleSans(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.5),
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
                GradientButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  label: AppLocalizations.of(context).confirm,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(AppLocalizations.of(context).edit,
                        style: GoogleFonts.googleSans(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator(int step) {
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

  // ── Section card ────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.googleSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  // ── Monthly progress ────────────────────────────────────────────────────────

  Widget _buildMonthlyProgress() {
    final int totalUsed = widget.currentMonthlyUsed + _totalSelected;
    final int remaining =
        (widget.maxMonthlyQuota - totalUsed).clamp(0, widget.maxMonthlyQuota);
    final int totalLubricantUsed =
        widget.currentMonthlyLubricantUsed + widget.lubricantQuantity;
    final int remainingLubricant =
        (widget.maxMonthlyLubricantQuota - totalLubricantUsed)
            .clamp(0, widget.maxMonthlyLubricantQuota);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).remainingQuota,
          style: GoogleFonts.googleSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).condoms,
                      style: GoogleFonts.googleSans(
                          fontSize: 14, color: AppColors.textSecondary)),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: (widget.maxMonthlyQuota - widget.currentMonthlyUsed)
                          .clamp(0, widget.maxMonthlyQuota),
                      end: remaining,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$value ',
                          style: GoogleFonts.googleSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 28),
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
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).lubricant,
                      style: GoogleFonts.googleSans(
                          fontSize: 14, color: AppColors.textSecondary)),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: (widget.maxMonthlyLubricantQuota -
                              widget.currentMonthlyLubricantUsed)
                          .clamp(0, widget.maxMonthlyLubricantQuota),
                      end: remainingLubricant,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$value ',
                          style: GoogleFonts.googleSans(
                              color: AppColors.lubricant,
                              fontWeight: FontWeight.bold,
                              fontSize: 28),
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
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Summary cards ───────────────────────────────────────────────────────────

  Widget _buildQuantityCard() {
    return _buildSectionCard(
      title: AppLocalizations.of(context).condoms,
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          ...widget.quantities.entries
              .where((e) => e.value > 0)
              .map((e) {
                final l10n = AppLocalizations.of(context);
                return _buildInfoRow('${l10n.sizeLabel} ${e.key} ${l10n.sizeMm}', '${e.value} ${l10n.pieces}');
              }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).total,
                  style: GoogleFonts.googleSans(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '$_totalSelected ${AppLocalizations.of(context).pieces}',
                style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard() {
    return _buildSectionCard(
      title: AppLocalizations.of(context).extra,
      icon: Icons.add_circle_outline,
      child: _buildInfoRow(AppLocalizations.of(context).lubricant, '${widget.lubricantQuantity} ${AppLocalizations.of(context).pieces}'),
    );
  }

  Widget _buildPlaceTimeCard() {
    final l10n = AppLocalizations.of(context);
    final dateStr = widget.selectedDate != null
        ? '${widget.selectedDate!.day} ${l10n.monthsFull[widget.selectedDate!.month]} ${widget.selectedDate!.year + 543}'
        : '-';
    final timeStr = widget.selectedTime != null
        ? '${widget.selectedTime!.hour.toString().padLeft(2, '0')}:${widget.selectedTime!.minute.toString().padLeft(2, '0')} ${l10n.timeWithUnit}'
        : '-';

    return _buildSectionCard(
      title: l10n.serviceAndDateTime,
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          _buildInfoRow(l10n.serviceCenterLabel, widget.selectedServiceCenter ?? '-'),
          _buildInfoRow(l10n.dateLabel, dateStr),
          _buildInfoRow(l10n.timeLabel, timeStr),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return _buildSectionCard(
      title: AppLocalizations.of(context).messageLabel,
      icon: Icons.comment_outlined,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(widget.message,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }

}
