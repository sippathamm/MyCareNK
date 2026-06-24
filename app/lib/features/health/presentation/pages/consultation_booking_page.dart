import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/service_center_model.dart';
import '../../../../core/services/service_center_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../widgets/consultation_booking_widgets.dart';
import 'consultation_history_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _Reason {
  final String key;
  final String label;
  final IconData icon;
  const _Reason(this.key, this.label, this.icon);
}

List<_Reason> _buildReasons(AppLocalizations l10n) => [
  _Reason('pep', l10n.reasonPEP, Icons.emergency),
  _Reason('prep', l10n.reasonPrEP, Icons.medication),
  _Reason('hiv', l10n.reasonHIV, Icons.biotech),
  _Reason('consult', l10n.reasonConsult, Icons.chat_bubble_outline),
];

List<DateTime> _buildAvailableDates() {
  final dates = <DateTime>[];
  var d = DateTime.now();
  while (dates.length < 7) {
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      dates.add(d);
    }
    d = d.add(const Duration(days: 1));
  }
  return dates;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ConsultationBookingPage extends StatefulWidget {
  final String? initialReason;
  final bool reasonLocked;
  const ConsultationBookingPage({super.key, this.initialReason, this.reasonLocked = false});

  @override
  State<ConsultationBookingPage> createState() => _ConsultationBookingPageState();
}

class _ConsultationBookingPageState extends State<ConsultationBookingPage> {
  final List<DateTime> _dates = _buildAvailableDates();
  String _refNum = '';
  bool _isSubmitting = false;

  int _step = 0;
  String? _reason;
  String? _location; // stores center name directly
  String? _dateKey;
  String? _timeSlot;
  final TextEditingController _noteCtrl = TextEditingController();

  List<ServiceCenterModel> _centers = [];
  bool _centersLoading = true;
  bool _centersNotLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _reason = widget.initialReason;
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (mounted) setState(() { _centersLoading = false; _centersNotLoggedIn = true; });
      return;
    }
    if (mounted) setState(() { _centersLoading = true; _centersNotLoggedIn = false; });
    try {
      final centers = await ServiceCenterService.fetchAll();
      if (mounted) setState(() { _centers = centers.where((c) => c.appointmentServiceEnabled).toList(); _centersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _centersLoading = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _reason != null && _location != null && _dateKey != null && _timeSlot != null;

  _Reason? _getSelectedReason(AppLocalizations l10n) =>
      _buildReasons(l10n).where((r) => r.key == _reason).firstOrNull;
  ServiceCenterModel? get _selectedLocation =>
      _centers.where((c) => c.name == _location).firstOrNull;

  DateTime? get _selectedDate => _dates
      .where((d) => d.toIso8601String().substring(0, 10) == _dateKey)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    if (_step == 2) return _buildSuccess();
    if (_step == 1) return _buildConfirm();
    return _buildForm();
  }

  // ── Form ────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(AppLocalizations.of(context).bookingTitle, () => Navigator.of(context).pop()),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: BookingStepIndicator(step: _step),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookingSectionCard(
                    title: AppLocalizations.of(context).bookingServiceReason,
                    icon: Icons.medical_services_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildReasons(AppLocalizations.of(context))
                            .map((r) {
                              final isDisabled = widget.reasonLocked && r.key != _reason;
                              return ReasonTile(
                                icon: r.icon,
                                label: r.label,
                                selected: _reason == r.key,
                                onTap: isDisabled ? null : () => setState(() => _reason = r.key),
                                disabled: isDisabled,
                              );
                            }),
                        if (widget.reasonLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline,
                                    size: 13, color: AppColors.textHint),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).lockedReasonNote,
                                    style: GoogleFonts.googleSans(
                                        fontSize: 12, color: AppColors.textHint),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  BookingSectionCard(
                    title: AppLocalizations.of(context).selectServiceCenterTitle,
                    icon: Icons.local_hospital_outlined,
                    child: _centersLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _centersNotLoggedIn
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(AppLocalizations.of(context).pleaseLogin,
                                      style: GoogleFonts.googleSans(
                                          fontSize: 14, color: AppColors.textHint)),
                                ),
                              )
                            : _centers.isEmpty
                                ? GestureDetector(
                                    onTap: _loadCenters,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Text(AppLocalizations.of(context).cannotLoadData,
                                            style: GoogleFonts.googleSans(
                                                fontSize: 14, color: AppColors.textHint)),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      _centers.length,
                                      (i) => ConsultationLocationTile(
                                        center: _centers[i],
                                        index: i,
                                        selected: _location == _centers[i].name,
                                        onTap: () => setState(() {
                                          if (_location != _centers[i].name) {
                                            _timeSlot = null;
                                          }
                                          _location = _centers[i].name;
                                        }),
                                      ),
                                    ),
                                  ),
                  ),
                  BookingSectionCard(
                    title: AppLocalizations.of(context).bookingAppointmentDate,
                    icon: Icons.event_outlined,
                    child: ConsultationDateStrip(
                      location: _selectedLocation,
                      dates: _dates,
                      dateKey: _dateKey,
                      onSelect: (key) => setState(() => _dateKey = key),
                    ),
                  ),
                  BookingSectionCard(
                    title: AppLocalizations.of(context).bookingAppointmentTime,
                    icon: Icons.schedule_outlined,
                    child: ConsultationTimePicker(
                      location: _selectedLocation,
                      locationName: _location,
                      selectedTime: _timeSlot,
                      onSelect: (t) => setState(() => _timeSlot = t),
                    ),
                  ),
                  BookingSectionCard(
                    title: AppLocalizations.of(context).bookingAdditionalNotes,
                    icon: Icons.notes_outlined,
                    child: TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.googleSans(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).bookingAdditionalNotesHint,
                        hintStyle: GoogleFonts.googleSans(
                            fontSize: 16, color: AppColors.textHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8E8E8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.lubricant, width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _canProceed ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: BookingPrimaryButton(
                      label: AppLocalizations.of(context).next,
                      onPressed: _canProceed ? () => setState(() => _step = 1) : null,
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

  // ── Confirm ─────────────────────────────────────────────────────────────────

  Widget _buildConfirm() {
    final loc = _selectedLocation;
    final rows = [
      (Icons.medical_services_outlined, AppLocalizations.of(context).reasonLabel, _getSelectedReason(AppLocalizations.of(context))?.label ?? ''),
      (Icons.local_hospital_outlined, AppLocalizations.of(context).serviceCenterLabel, loc?.name ?? ''),
      if (loc?.operatingHours != null)
        (Icons.access_time_outlined, AppLocalizations.of(context).operatingHours, loc!.operatingHours!),
      (Icons.event_outlined, AppLocalizations.of(context).dateLabel, _selectedDate != null ? '${_selectedDate!.day} ${AppLocalizations.of(context).monthsFull[_selectedDate!.month]} ${_selectedDate!.year + 543}' : ''),
      (Icons.schedule_outlined, AppLocalizations.of(context).timeLabel, '${_timeSlot ?? ''} ${AppLocalizations.of(context).timeWithUnit}'),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(AppLocalizations.of(context).bookingTitle, () => setState(() => _step = 0)),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: BookingStepIndicator(step: _step),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  BookingSectionCard(
                    title: AppLocalizations.of(context).bookingAppointmentSummary,
                    icon: Icons.event_note_outlined,
                    child: Column(
                      children: [
                        ...rows.map((row) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        Icon(row.$1,
                                            color: AppColors.textMuted,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          row.$2,
                                          style: GoogleFonts.googleSans(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ]),
                                      Flexible(
                                        child: Text(
                                          row.$3,
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
                                  const SizedBox(height: 14),
                                  const Divider(
                                      height: 1, color: Color(0xFFF0F0F0)),
                                ],
                              ),
                            )),
                        if (_noteCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).bookingNoteLabel,
                                    style: GoogleFonts.googleSans(
                                        fontSize: 14,
                                        color: AppColors.textHint)),
                                const SizedBox(height: 4),
                                Text(_noteCtrl.text,
                                    style: GoogleFonts.googleSans(
                                        fontSize: 15,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
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
                            AppLocalizations.of(context).bookingCancelNote,
                            style: GoogleFonts.googleSans(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  BookingPrimaryButton(
                    label: AppLocalizations.of(context).confirmAppointment,
                    onPressed: _isSubmitting ? null : _submitBooking,
                    isLoading: _isSubmitting,
                  ),
                  const SizedBox(height: 10),
                  BookingOutlinedButton(
                    label: AppLocalizations.of(context).edit,
                    onPressed: _isSubmitting ? null : () => setState(() => _step = 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submitBooking() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context).pleaseLogin,
              style: GoogleFonts.googleSans(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: Text(AppLocalizations.of(context).loginToBookDoctor,
              style: GoogleFonts.googleSans(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context).cancel,
                  style: GoogleFonts.googleSans(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final loggedIn = await Navigator.of(context, rootNavigator: true)
                    .push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
                if (loggedIn == true && mounted) _submitBooking();
              },
              child: Text(AppLocalizations.of(context).loginBtn,
                  style: GoogleFonts.googleSans(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ref = await Supabase.instance.client.rpc(
        'create_doctor_appointment',
        params: {
          'p_user_id': userId,
          'p_reason': _reason,
          'p_service_center': _location,
          'p_date': _dateKey,
          'p_time': _timeSlot,
          'p_note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        },
      ) as String;

      if (mounted) setState(() { _refNum = ref; _step = 2; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.current.generalErrorRetry,
              style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Success ─────────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final infoRows = [
      (Icons.local_hospital_outlined, AppLocalizations.of(context).serviceCenterLabel, _selectedLocation?.name ?? ''),
      (Icons.event_outlined, AppLocalizations.of(context).dateLabel, _selectedDate != null ? '${_selectedDate!.day} ${AppLocalizations.of(context).monthsFull[_selectedDate!.month]} ${_selectedDate!.year + 543}' : ''),
      (Icons.schedule_outlined, AppLocalizations.of(context).timeLabel, '${_timeSlot ?? ''} ${AppLocalizations.of(context).timeWithUnit}'),
      (Icons.medical_services_outlined, AppLocalizations.of(context).reasonLabel, _getSelectedReason(AppLocalizations.of(context))?.label ?? ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(
        AppLocalizations.of(context).bookingTitle,
        () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: BookingStepIndicator(step: _step),
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
                border: Border.all(color: AppColors.statusCompleted, width: 3),
              ),
              child: const Icon(Icons.check, color: AppColors.statusCompleted, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).bookingSuccess,
              style: GoogleFonts.googleSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).bookingSuccessMessage,
              style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            BookingSectionCard(
              title: AppLocalizations.of(context).appointmentDetailsTitle,
              icon: Icons.event_note_outlined,
              child: Column(
                children: infoRows
                    .map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.lubricantCardStart,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(row.$1,
                                    color: AppColors.lubricant, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.$2,
                                      style: GoogleFonts.googleSans(
                                          fontSize: 12,
                                          color: AppColors.textHint)),
                                  Text(row.$3,
                                      style: GoogleFonts.googleSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            Text(
              AppLocalizations.of(context).referencePrefix(_refNum),
              style: GoogleFonts.googleSans(fontSize: 14, color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).preTodoTitle,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    AppLocalizations.of(context).bookingInstruction1,
                    AppLocalizations.of(context).bookingInstruction2,
                    AppLocalizations.of(context).bookingInstruction3,
                  ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.statusCompleted, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(t,
                                  style: GoogleFonts.googleSans(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 28),
            BookingPrimaryButton(
              label: AppLocalizations.of(context).backToService,
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            const SizedBox(height: 10),
            BookingOutlinedButton(
              label: AppLocalizations.of(context).appointmentHistoryTitle,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const ConsultationHistoryPage()),
                (route) => route.isFirst,
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String title, VoidCallback onBack) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: GoogleFonts.googleSans(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: AppColors.primary),
          tooltip: AppLocalizations.of(context).appointmentHistoryTitle,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConsultationHistoryPage()),
          ),
        ),
      ],
    );
  }
}
