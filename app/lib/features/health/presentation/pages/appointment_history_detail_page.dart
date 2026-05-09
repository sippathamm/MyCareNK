import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/doctor_appointment_model.dart';

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
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        elevation: 24,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ยืนยันการยกเลิกนัดหมาย',
            style: GoogleFonts.googleSans(
                fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(
          'คุณต้องการยกเลิกการนัดหมายนี้ใช่หรือไม่?\nการยกเลิกไม่สามารถเปลี่ยนแปลงได้',
          style: GoogleFonts.googleSans(fontSize: 15, height: 1.6),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          GradientButton(
            height: 46,
            onPressed: () => Navigator.of(ctx).pop(true),
            label: 'ยืนยันยกเลิก',
            gradientColors: GradientButton.errorGradient,
            fontSize: 15,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text('ไม่ยกเลิก',
                  style: GoogleFonts.googleSans(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
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
        content: Text('ยกเลิกนัดหมายเรียบร้อยแล้ว',
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาดในการยกเลิกนัดหมาย',
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
          'รายละเอียดการนัดหมาย',
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
        '${updated.day} ${_monthTH(updated.month)} ${updated.year + 543} '
        '${updated.hour.toString().padLeft(2, '0')}:'
        '${updated.minute.toString().padLeft(2, '0')} น.';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัสอ้างอิง',
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
                      content: Text('คัดลอกรหัสอ้างอิงแล้ว',
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

    if (isCancelled) {
      return Row(
        children: [
          _buildStepNode(
              color: AppColors.primary,
              icon: Icons.check,
              label: 'รอยืนยัน',
              isCurrent: false,
              isDone: true),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildStepNode(
              color: Colors.grey,
              icon: Icons.close,
              label: status == 'cancelled_by_staff'
                  ? 'ยกเลิกโดยเจ้าหน้าที่'
                  : 'ยกเลิกโดยคุณ',
              isCurrent: true,
              isDone: false,
              labelColor: Colors.grey[600]),
        ],
      );
    }

    final steps = [
      (label: 'รอยืนยัน',   value: 'pending',   color: AppColors.primary),
      (label: 'ยืนยันแล้ว',  value: 'confirmed', color: AppColors.statusReady),
      (label: 'เสร็จสิ้น',   value: 'completed', color: AppColors.statusCompleted),
    ];
    final currentIdx = steps.indexWhere((s) => s.value == status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftIdx = i ~/ 2;
          final done = leftIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: done ? steps[leftIdx].color : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final idx = i ~/ 2;
        final isDone = idx < currentIdx;
        final isCurrent = idx == currentIdx;
        return _buildStepNode(
          color: (isDone || isCurrent)
              ? steps[idx].color
              : const Color(0xFFE8E8E8),
          icon: isDone ? Icons.check : null,
          number: isDone ? null : idx + 1,
          label: steps[idx].label,
          isCurrent: isCurrent,
          isDone: isDone,
          labelColor: isCurrent
              ? steps[idx].color
              : isDone
                  ? AppColors.textSecondary
                  : AppColors.textMuted,
        );
      }),
    );
  }

  Widget _buildStepNode({
    required Color color,
    IconData? icon,
    int? number,
    required String label,
    required bool isCurrent,
    required bool isDone,
    Color? labelColor,
  }) {
    return Column(
      children: [
        AnimatedContainer(
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
                      color: (isCurrent || isDone)
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: labelColor ?? AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required Widget header,
    required Widget content,
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lubricantDark, AppColors.lubricant],
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
        Text('เรื่องที่ต้องการพบแพทย์',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          _buildInfoRow(
              'เรื่อง', DoctorAppointmentModel.reasonLabel(_data.reason)),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final date = _data.selectedDate;
    final dateStr =
        '${date.day} ${_monthTH(date.month)} ${date.year + 543}';

    return _buildCard(
      header: Row(children: [
        const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('สถานพยาบาล วันที่ และเวลารับ',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        children: [
          _buildInfoRow('สถานพยาบาล', _data.selectedServiceCenter),
          _buildInfoRow('วันที่', dateStr),
          _buildInfoRow('เวลา', '${_data.selectedTime} น.'),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return _buildCard(
      header: Row(children: [
        const Icon(Icons.notes_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('บันทึกเพิ่มเติม',
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
      header: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('เหตุผลที่ยกเลิก',
            style: GoogleFonts.googleSans(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Align(
        alignment: Alignment.centerLeft,
        child: Text(_data.cancelReason!,
            style: GoogleFonts.googleSans(
                fontSize: 16, color: AppColors.error)),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final canCancel = _data.appointmentStatus == 'pending';

    return Column(
      children: [
        GradientButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'ตกลง',
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
                  : Text('ยกเลิกนัด',
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

  String _monthTH(int month) {
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return months[month];
  }
}
