import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/doctor_appointment_model.dart';
import '../../../../../core/l10n/app_localizations.dart';

class AppointmentHistoryDetailPage extends StatefulWidget {
  final DoctorAppointmentModel data;
  const AppointmentHistoryDetailPage({super.key, required this.data});

  @override
  State<AppointmentHistoryDetailPage> createState() =>
      _AppointmentHistoryDetailPageState();
}

class _AppointmentHistoryDetailPageState
    extends State<AppointmentHistoryDetailPage> {
  bool _isCancelling = false;
  late DoctorAppointmentModel _data;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  // ── Realtime ────────────────────────────────────────────────────────────────

  void _setupRealtime() {
    _subscription = Supabase.instance.client
        .channel('public:doctor_appointments:${_data.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'doctor_appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _data.id,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchData();
            }
          },
        )
        .subscribe();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    try {
      final response = await Supabase.instance.client
          .from('doctor_appointments')
          .select()
          .eq('id', _data.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _data = DoctorAppointmentModel.fromMap(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointment: $e');
    }
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).cancelAppointmentTitle,
            style: GoogleFonts.googleSans(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text(
          AppLocalizations.of(context).cancelAppointmentMessage,
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
            child: Text(AppLocalizations.of(context).cancelApptBtn,
                style: GoogleFonts.googleSans(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) _doCancelAppointment();
  }

  Future<void> _doCancelAppointment() async {
    setState(() => _isCancelling = true);
    try {
      await Supabase.instance.client
          .from('doctor_appointments')
          .update({'appointment_status': 'cancelled_by_user'})
          .eq('id', _data.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.current.cancelApptSuccess,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.current.cancelApptError,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).appointmentDetailsTitle,
          style: GoogleFonts.googleSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatusTracker(),
                const SizedBox(height: 32),
                _buildReasonCard(),
                _buildLocationCard(),
                if (_data.note != null && _data.note!.isNotEmpty)
                  _buildNoteCard(),
                if ((_data.appointmentStatus == 'cancelled_by_staff') &&
                    _data.cancelReason != null &&
                    _data.cancelReason!.isNotEmpty)
                  _buildCancelReasonCard(),
                const SizedBox(height: 48),
                _buildBottomButtons(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final cfg = _statusConfig(_data.appointmentStatus);
    final updated = _data.updatedAt.toUtc().add(const Duration(hours: 7));
    final dateStr =
        '${updated.day} ${AppLocalizations.of(context).monthsFull[updated.month]} ${updated.year + 543} '
        '${updated.hour.toString().padLeft(2, '0')}:'
        '${updated.minute.toString().padLeft(2, '0')} ${AppLocalizations.of(context).timeWithUnit}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).referenceNumber,
                style: GoogleFonts.googleSans(
                    color: Colors.grey[500], fontSize: 12)),
            Row(
              children: [
                Text(
                  _data.referenceNumber,
                  style: GoogleFonts.googleSans(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _data.referenceNumber));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.current.copiedApptRefCode,
                          style: GoogleFonts.googleSans()),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
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
              decoration:
                  BoxDecoration(color: cfg.iconBg, shape: BoxShape.circle),
              child: Icon(cfg.icon, color: cfg.iconColor, size: 16),
            ),
            const SizedBox(height: 4),
            Text(dateStr,
                style: GoogleFonts.googleSans(
                    color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTracker() {
    final status = _data.appointmentStatus;
    final isCancelled =
        status == 'cancelled_by_user' || status == 'cancelled_by_staff';
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

    Widget circle(Color color, IconData? icon, int? number, bool active) =>
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 14)
                : Text('${number ?? ''}',
                    style: GoogleFonts.googleSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textMuted)),
          ),
        );

    if (isCancelled) {
      final cancelLabel =
          status == 'cancelled_by_staff'
              ? AppLocalizations.of(context).statusCancelledByStaff
              : AppLocalizations.of(context).statusCancelledByUser;
      return Column(children: [
        Row(children: [
          circle(AppColors.primary, Icons.check, null, true),
          const SizedBox(width: gap),
          connector(const Color(0xFFE8E8E8)),
          const SizedBox(width: gap),
          circle(Colors.grey, Icons.close, null, true),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Text(AppLocalizations.of(context).statusPendingAppt,
              style: GoogleFonts.googleSans(
                  fontSize: 11, color: AppColors.textSecondary)),
          const Expanded(child: SizedBox()),
          Text(cancelLabel,
              style: GoogleFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600)),
        ]),
      ]);
    }

    final steps = [
      (label: AppLocalizations.of(context).statusPendingAppt,  value: 'pending',   color: AppColors.primary),
      (label: AppLocalizations.of(context).statusConfirmedAppt, value: 'confirmed', color: AppColors.statusReady),
      (label: AppLocalizations.of(context).statusCompleted,     value: 'completed', color: AppColors.statusCompleted),
    ];
    final currentIdx = steps.indexWhere((s) => s.value == status);
    final n = steps.length;

    final iconItems = <Widget>[];
    for (int idx = 0; idx < n; idx++) {
      final step = steps[idx];
      final isDone = idx < currentIdx;
      final isCurrent = idx == currentIdx;
      final isLast = idx == n - 1;
      final showCheck = isDone || (isCurrent && isLast);
      iconItems.add(circle(
        (isDone || isCurrent) ? step.color : const Color(0xFFE8E8E8),
        showCheck ? Icons.check : null,
        showCheck ? null : idx + 1,
        isDone || isCurrent,
      ));
      if (!isLast) {
        iconItems.addAll([
          const SizedBox(width: gap),
          connector(isDone ? step.color : const Color(0xFFE8E8E8)),
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
            color: isCurrent
                ? steps[idx].color
                : isDone
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
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

  Widget _buildCard({
    required Widget header,
    required Widget content,
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
              offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors ?? [AppColors.lubricantDark, AppColors.lubricant],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: header,
            ),
            Padding(padding: const EdgeInsets.all(16), child: content),
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
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.googleSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return _buildCard(
      header: Row(children: [
        const Icon(Icons.medical_services_outlined,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).apptSubjectSection,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          _buildInfoRow(AppLocalizations.of(context).reasonLabel, DoctorAppointmentModel.reasonLabel(_data.reason)),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final date = _data.selectedDate;
    final dateStr =
        '${date.day} ${AppLocalizations.of(context).monthsFull[date.month]} ${date.year + 543}';

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).apptServiceDateTime,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          _buildInfoRow(AppLocalizations.of(context).serviceCenterLabel, _data.selectedServiceCenter),
          _buildInfoRow(AppLocalizations.of(context).dateLabel, dateStr),
          _buildInfoRow(AppLocalizations.of(context).timeLabel, '${_data.selectedTime} ${AppLocalizations.of(context).timeWithUnit}'),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return _buildCard(
      header: Row(children: [
        const Icon(Icons.notes_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).additionalNotesSection,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(_data.note!,
            style: GoogleFonts.googleSans(
                fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildCancelReasonCard() {
    return _buildCard(
      headerColors: [AppColors.errorDark, AppColors.error],
      header: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).cancelReasonSection,
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(_data.cancelReason!,
            style: GoogleFonts.googleSans(
                fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final canCancel = _data.appointmentStatus == 'pending';

    return Column(
      children: [
        GradientButton(
          onPressed: () => Navigator.of(context).pop(),
          label: AppLocalizations.of(context).ok,
          gradientColors: GradientButton.lubricantGradient,
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
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : Text(AppLocalizations.of(context).cancelApptBtn,
                      style: GoogleFonts.googleSans(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  ({Color iconBg, Color iconColor, IconData icon}) _statusConfig(
      String status) {
    switch (status) {
      case 'pending':
        return (
          iconBg: AppColors.statusPendingLight,
          iconColor: AppColors.primary,
          icon: Icons.schedule_outlined,
        );
      case 'confirmed':
        return (
          iconBg: AppColors.statusReadyLight,
          iconColor: AppColors.statusReady,
          icon: Icons.event_available_outlined,
        );
      case 'completed':
        return (
          iconBg: AppColors.statusCompletedLight,
          iconColor: AppColors.statusCompleted,
          icon: Icons.check_circle_outline,
        );
      default:
        return (
          iconBg: Colors.grey.shade200,
          iconColor: Colors.grey.shade600,
          icon: Icons.cancel_outlined,
        );
    }
  }

}
