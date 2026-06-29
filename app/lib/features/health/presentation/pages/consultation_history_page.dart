import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/consultation_model.dart';
import '../widgets/consultation_status_visuals.dart';
import 'consultation_history_detail_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

// ─── Filter descriptor ────────────────────────────────────────────────────────

typedef _Filter = ({String? key, String label, Color color});

const Color _kCancelledColor = Color(0xFF757575);

List<_Filter> _buildFilters(AppLocalizations l10n) => [
  (key: null,        label: l10n.all,                 color: AppColors.primary),
  (key: 'pending',   label: l10n.statusPendingAppt,   color: AppColors.primary),
  (key: 'confirmed', label: l10n.statusConfirmedAppt, color: AppColors.statusReady),
  (key: 'completed', label: l10n.statusCompleted,     color: AppColors.statusCompleted),
  (key: 'cancelled', label: l10n.statusCancelled,     color: _kCancelledColor),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class ConsultationHistoryPage extends StatefulWidget {
  const ConsultationHistoryPage({super.key});

  @override
  State<ConsultationHistoryPage> createState() => _ConsultationHistoryPageState();
}

class _ConsultationHistoryPageState extends State<ConsultationHistoryPage> {
  List<ConsultationModel> _appointments = [];
  bool _isLoading = true;
  bool _isLoggedIn = true;
  String _searchQuery = '';
  String? _selectedStatus; // null = all; 'cancelled' = both cancelled values
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  // ── Realtime ────────────────────────────────────────────────────────────────

  void _setupRealtime() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    _subscription = Supabase.instance.client
        .channel('public:consultations:user_id=eq.${session.user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'consultations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: session.user.id,
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
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) setState(() { _isLoggedIn = false; _isLoading = false; });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('consultations')
          .select()
          .eq('user_id', session.user.id)
          .order('created_at', ascending: false);

      final appointments = response
          .map((e) => ConsultationModel.fromMap(e))
          .toList();

      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Filtered list ───────────────────────────────────────────────────────────

  List<ConsultationModel> get _filtered {
    return _appointments.where((a) {
      if (_selectedStatus != null) {
        if (_selectedStatus == 'cancelled') {
          if (a.consultationStatus != 'cancelled_by_user' &&
              a.consultationStatus != 'cancelled_by_staff') {
            return false;
          }
        } else {
          if (a.consultationStatus != _selectedStatus) { return false; }
        }
      }
      if (_searchQuery.isNotEmpty &&
          !a.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
          AppLocalizations.of(context).appointmentHistoryTitle,
          style: GoogleFonts.googleSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 16),
            _buildFilterRow(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading && _appointments.isEmpty
                  ? _buildSkeleton()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: (!_isLoggedIn ||
                                _appointments.isEmpty ||
                                filtered.isEmpty)
                            ? 1
                            : filtered.length,
                        itemBuilder: (context, index) {
                          if (!_isLoggedIn) return _buildEmptyState(Icons.lock_outline, AppLocalizations.of(context).pleaseLogin);
                          if (_appointments.isEmpty) return _buildEmptyState(Icons.event_busy_outlined, AppLocalizations.of(context).noAppointments);
                          if (filtered.isEmpty) return _buildEmptyState(Icons.search_off_outlined, AppLocalizations.of(context).noMatchingAppts);
                          return _buildAppointmentCard(filtered[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 18, width: 160, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            Container(height: 28, width: 72, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchApptRefCode,
          hintStyle: GoogleFonts.googleSans(color: Colors.grey[600], fontSize: 14),
          suffixIcon: const Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _buildFilters(AppLocalizations.of(context))
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(f),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip(_Filter f) {
    final isSelected = _selectedStatus == f.key;
    return Material(
      color: isSelected ? f.color : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: f.color),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = f.key),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            f.label,
            style: GoogleFonts.googleSans(
              color: isSelected ? AppColors.white : f.color,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.googleSans(fontSize: 16, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(ConsultationModel data) {
    final visuals = ConsultationStatusVisuals.of(data.consultationStatus);
    final statusLabel = _statusLabel(data.consultationStatus);
    final date = data.selectedDate;
    final dateStr =
        '${date.day} ${AppLocalizations.of(context).monthsFull[date.month]} ${date.year + 543}, ${data.selectedTime} ${AppLocalizations.of(context).timeWithUnit}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header row ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: visuals.lightBg, shape: BoxShape.circle),
                  child: Icon(visuals.icon, color: visuals.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).referenceNumber,
                          style: GoogleFonts.googleSans(
                              color: Colors.grey[500], fontSize: 12)),
                      Text(data.referenceNumber,
                          style: GoogleFonts.googleSans(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: visuals.color,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel,
                      style: GoogleFonts.googleSans(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1)),
            // ── Info rows ──
            _infoRow(Icons.event_outlined, dateStr),
            const SizedBox(height: 8),
            _infoRow(Icons.local_hospital_outlined, data.selectedServiceCenter),
            // ── Detail button ──
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(overlayColor: visuals.color.withValues(alpha: 0.12)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConsultationHistoryDetailPage(data: data),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context).details,
                        style: GoogleFonts.googleSans(
                            color: visuals.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    Icon(Icons.chevron_right,
                        size: 16, color: visuals.color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.googleSans(
                  color: Colors.grey[500], fontSize: 14)),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'pending':
        return l10n.statusPendingAppt;
      case 'confirmed':
        return l10n.statusConfirmedAppt;
      case 'completed':
        return l10n.statusCompleted;
      case 'cancelled_by_staff':
        return l10n.statusCancelledByStaff;
      default: // cancelled_by_user
        return l10n.statusCancelledByUser;
    }
  }
}
