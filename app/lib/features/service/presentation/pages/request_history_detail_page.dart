import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/condom_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../widgets/info_row.dart';
import '../widgets/request_status_visuals.dart';
import '../../../../../core/l10n/app_localizations.dart';

class RequestHistoryDetailPage extends StatefulWidget {
  final CondomRequestModel data;

  const RequestHistoryDetailPage({super.key, required this.data});

  @override
  State<RequestHistoryDetailPage> createState() => _RequestHistoryDetailPageState();
}

class _RequestHistoryDetailPageState extends State<RequestHistoryDetailPage> {
  bool _isCancelling = false;
  late CondomRequestModel _currentData;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _currentData = widget.data;
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await Supabase.instance.client
          .from('condom_requests')
          .select()
          .eq('id', _currentData.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentData = CondomRequestModel.fromJson(response);
        });
      }
    } catch (_) {
      // Realtime channel will retry; keep showing the snapshot we already have.
    }
  }

  void _setupRealtime() {
    _subscription = Supabase.instance.client
        .channel('public:condom_requests:${_currentData.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'condom_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentData.id,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchData();
            }
          },
        )
        .subscribe();
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
          AppLocalizations.of(context).requestDetails,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderId(context),
                const SizedBox(height: 24),
                _buildStatusTracker(),
                const SizedBox(height: 32),
                _buildQuantityCard(),
                _buildLubricantCard(),
                _buildLocationCard(),
                _buildMessageCard(),
                _buildCancelReasonCard(),
                const SizedBox(height: 48),
                _buildBottomButtons(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderId(BuildContext context) {
    final visuals = RequestStatusVisuals.of(_currentData.status);
    final IconData icon = visuals.icon;
    final Color iconColor = visuals.color;
    final Color iconBgColor = visuals.lightBg;

    // Format Date
    final formattedDate = _currentData.updatedAt.toUtc().add(const Duration(hours: 7));
    final l10n = AppLocalizations.of(context);
    final dateStr = '${formattedDate.day} ${l10n.monthsFull[formattedDate.month - 1]} ${formattedDate.year + 543} ${formattedDate.hour.toString().padLeft(2, '0')}:${formattedDate.minute.toString().padLeft(2, '0')} ${l10n.timeWithUnit}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).referenceNumber,
              style: GoogleFonts.googleSans(color: Colors.grey[500], fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  _currentData.referenceNumber,
                  style: GoogleFonts.googleSans(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentData.referenceNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).copiedRefCode,
                          style: GoogleFonts.googleSans(),
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
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

  Widget _buildStatusTracker() {
    final status = _currentData.status;
    const double nodeSize = 28;
    const double gap = 6;

    Widget connector(Color color) => Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    Text labelText(String text, Color color, bool bold) => Text(
          text,
          style: GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color,
          ),
        );

    if (status.isCancelled) {
      return Column(children: [
        Row(children: [
          _buildStepCircle(color: AppColors.primary, icon: Icons.check, isDone: true, isCurrent: false),
          const SizedBox(width: gap),
          connector(const Color(0xFFE8E8E8)),
          const SizedBox(width: gap),
          _buildStepCircle(color: Colors.grey, icon: Icons.close, isDone: false, isCurrent: true),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          labelText(AppLocalizations.of(context).statusPending, AppColors.textSecondary, false),
          const Expanded(child: SizedBox()),
          labelText(AppLocalizations.of(context).statusCancelled, Colors.grey.shade600, true),
        ]),
      ]);
    }

    final steps = [
      (label: AppLocalizations.of(context).statusPending, status: RequestStatus.pending,   color: AppColors.primary),
      (label: AppLocalizations.of(context).statusPreparing, status: RequestStatus.preparing,  color: AppColors.statusPreparing),
      (label: AppLocalizations.of(context).statusReady, status: RequestStatus.ready,      color: AppColors.statusReady),
      (label: AppLocalizations.of(context).statusCompleted, status: RequestStatus.completed,  color: AppColors.statusCompleted),
    ];
    final currentIdx = steps.indexWhere((s) => s.status == status);
    final n = steps.length;

    final iconItems = <Widget>[];
    for (int idx = 0; idx < n; idx++) {
      final step = steps[idx];
      final isDone = idx < currentIdx;
      final isCurrent = idx == currentIdx;
      iconItems.add(_buildStepCircle(
        color: (isDone || isCurrent) ? step.color : const Color(0xFFE8E8E8),
        icon: (isDone || (isCurrent && idx == n - 1)) ? Icons.check : null,
        number: (isDone || (isCurrent && idx == n - 1)) ? null : idx + 1,
        isDone: isDone,
        isCurrent: isCurrent,
      ));
      if (idx < n - 1) {
        final connColor = isDone ? step.color : const Color(0xFFE8E8E8);
        iconItems.addAll([const SizedBox(width: gap), connector(connColor), const SizedBox(width: gap)]);
      }
    }

    return Column(children: [
      Row(children: iconItems),
      const SizedBox(height: 4),
      // LayoutBuilder + Stack: pixel-perfect label positioning
      // icon[i] center = nodeSize/2 + i * (W - nodeSize)/(n-1) with equal Expanded connectors
      // First label: Positioned(left:0) → left edge flush with icon0 left
      // Middle labels: Positioned(left: center) + FractionalTranslation(-0.5,0) → centered exactly at icon center
      // Last label: Positioned(right:0) → right edge flush with iconN right
      LayoutBuilder(builder: (context, constraints) {
        final W = constraints.maxWidth;
        final slotSpacing = (W - nodeSize) / (n - 1);

        TextStyle style(int idx) {
          final isDone = idx < currentIdx;
          final isCurrent = idx == currentIdx;
          return GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? steps[idx].color : isDone ? AppColors.textSecondary : AppColors.textMuted,
          );
        }

        final positioned = <Widget>[
          Positioned(left: 0, top: 0, child: Text(steps[0].label, style: style(0))),
          Positioned(right: 0, top: 0, child: Text(steps[n - 1].label, style: style(n - 1))),
          for (int i = 1; i < n - 1; i++)
            Positioned(
              left: nodeSize / 2 + i * slotSpacing,
              top: 0,
              child: FractionalTranslation(
                translation: const Offset(-0.5, 0),
                child: Text(steps[i].label, style: style(i)),
              ),
            ),
        ];

        return SizedBox(
          height: 16,
          child: Stack(clipBehavior: Clip.none, children: positioned),
        );
      }),
    ]);
  }

  Widget _buildStepCircle({
    required Color color,
    IconData? icon,
    int? number,
    required bool isCurrent,
    required bool isDone,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 14)
            : Text(
                '${number ?? ''}',
                style: GoogleFonts.googleSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: (isCurrent || isDone) ? Colors.white : AppColors.textMuted,
                ),
              ),
      ),
    );
  }

  Widget _buildCard({
    required Widget header,
    required Widget content,
    bool showDivider = false,
    Widget? footer,
    List<Color>? headerColors,
  }) {
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors ?? [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: header,
            ),
            Padding(padding: const EdgeInsets.all(16.0), child: content),
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

  Widget _buildQuantityCard() {
    final totalCondoms = _currentData.condomQuantities.values.fold(0, (sum, val) => sum + val);
    if (totalCondoms == 0) return const SizedBox();

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).condoms,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          ..._currentData.condomQuantities.entries
              .where((e) => e.value > 0)
              .map((e) => InfoRow('${AppLocalizations.of(context).sizeLabel} ${e.key} ${AppLocalizations.of(context).sizeMm}', '${e.value} ${AppLocalizations.of(context).pieces}')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).total,
                  style: GoogleFonts.googleSans(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '$totalCondoms ${AppLocalizations.of(context).pieces}',
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
    if (_currentData.lubricantQuantity == 0) return const SizedBox();

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).extra,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: InfoRow(AppLocalizations.of(context).lubricant, '${_currentData.lubricantQuantity} ${AppLocalizations.of(context).pieces}'),
    );
  }

  Widget _buildLocationCard() {
    String outputDate = _currentData.selectedDate ?? '-';
    if (_currentData.selectedDate != null && _currentData.selectedDate!.contains('-')) {
      try {
        final parsedDate = DateTime.parse(_currentData.selectedDate!);
        outputDate = '${parsedDate.day} ${AppLocalizations.of(context).monthsFull[parsedDate.month - 1]} ${parsedDate.year + 543}';
      } catch (e) {
        outputDate = _currentData.selectedDate!;
      }
    }

    String outputTime = _currentData.selectedTime ?? '-';
    if (_currentData.selectedTime != null && _currentData.selectedTime!.contains(':')) {
      final splitted = _currentData.selectedTime!.split(':');
      if (splitted.length >= 2) {
        outputTime = '${splitted[0]}:${splitted[1]} ${AppLocalizations.of(context).timeWithUnit}';
      }
    }

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).serviceAndDateTime,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          InfoRow(AppLocalizations.of(context).serviceCenterLabel, _currentData.selectedServiceCenter ?? '-'),
          InfoRow(AppLocalizations.of(context).dateLabel, outputDate),
          InfoRow(AppLocalizations.of(context).timeLabel, outputTime),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    if (_currentData.message.isEmpty) return const SizedBox();

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.comment_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).messageLabel,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentData.message,
          style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildCancelReasonCard() {
    if (_currentData.status != RequestStatus.cancelledByStaff) return const SizedBox();
    if (_currentData.cancelReason == null || _currentData.cancelReason!.isEmpty) return const SizedBox();

    return _buildCard(
      headerColors: [AppColors.errorDark, AppColors.error],
      header: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).cancelReason,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentData.cancelReason!,
          style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Future<void> _doCancelRequest() async {
    setState(() => _isCancelling = true);
    try {
      await Supabase.instance.client
          .from('condom_requests')
          .update({'request_status': 'cancelled_by_user'})
          .eq('id', _currentData.id);

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final userId = session.user.id;
        final createdAt = _currentData.createdAt.toLocal();
        final monthStart = DateTime(createdAt.year, createdAt.month, 1)
            .toIso8601String()
            .substring(0, 10);

        final existingQuota = await Supabase.instance.client
            .from('user_monthly_quotas')
            .select('used_condoms, used_lubricants')
            .eq('user_id', userId)
            .eq('month', monthStart)
            .maybeSingle();

        if (existingQuota != null) {
          final totalCondomsToRefund = _currentData.condomQuantities.values
              .fold(0, (sum, val) => sum + val);
          final lubricantToRefund = _currentData.lubricantQuantity;
          final newUsedCondoms =
              (((existingQuota['used_condoms'] as int?) ?? 0) - totalCondomsToRefund)
                  .clamp(0, 9999);
          final newUsedLubricants =
              (((existingQuota['used_lubricants'] as int?) ?? 0) - lubricantToRefund)
                  .clamp(0, 9999);

          await Supabase.instance.client.from('user_monthly_quotas').upsert({
            'user_id': userId,
            'month': monthStart,
            'used_condoms': newUsedCondoms,
            'used_lubricants': newUsedLubricants,
          }, onConflict: 'user_id, month');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.current.cancelSuccess, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.current.cancelError, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).cancelRequestTitle,
          style: GoogleFonts.googleSans(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).cancelRequestMessage,
          style: GoogleFonts.googleSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).keepRequest,
                style: GoogleFonts.googleSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context).confirmCancel,
                style: GoogleFonts.googleSans(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) _doCancelRequest();
  }

  Widget _buildBottomButtons(BuildContext context) {
    final canCancel = _currentData.status == RequestStatus.pending;

    return Column(
      children: [
        GradientButton(
          onPressed: () => Navigator.of(context).pop(),
          label: AppLocalizations.of(context).ok,
        ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _confirmCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : Text(
                      AppLocalizations.of(context).cancelRequestSectionTitle,
                      style: GoogleFonts.googleSans(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ],
    );
  }

}
