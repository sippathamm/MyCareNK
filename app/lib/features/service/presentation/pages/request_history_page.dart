import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'request_history_detail_page.dart';

import '../../data/models/condom_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../widgets/request_status_visuals.dart';

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  // null = ทั้งหมด, otherwise filter by status group
  Set<RequestStatus>? _selectedFilterSet;
  String _searchQuery = '';

  List<CondomRequestModel> _requests = [];
  bool _isLoading = true;
  bool _isLoggedIn = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    _subscription = Supabase.instance.client
        .channel('public:condom_requests:user_id=eq.${session.user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'condom_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: session.user.id,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchHistory();
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchHistory() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('condom_requests')
          .select()
          .eq('user_id', session.user.id)
          .order('created_at', ascending: false);

      final List<CondomRequestModel> loadedRequests = (response as List)
          .map((item) => CondomRequestModel.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _requests = loadedRequests;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _requests.where((req) {
      if (_selectedFilterSet != null && !_selectedFilterSet!.contains(req.status)) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !req.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

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
          AppLocalizations.of(context).requestHistoryTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
              child: _isLoading && _requests.isEmpty
                  ? _buildSkeleton()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchHistory,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: (!_isLoggedIn || _requests.isEmpty || filteredRequests.isEmpty) ? 1 : filteredRequests.length,
                        itemBuilder: (context, index) {
                          if (!_isLoggedIn) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(AppLocalizations.of(context).pleaseLogin, style: GoogleFonts.googleSans(fontSize: 16, color: Colors.grey[400])),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (_requests.isEmpty) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(AppLocalizations.of(context).noRequests, style: GoogleFonts.googleSans(fontSize: 16, color: Colors.grey[400])),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (filteredRequests.isEmpty) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(AppLocalizations.of(context).noMatchingRequests, style: GoogleFonts.googleSans(fontSize: 16, color: Colors.grey[400])),
                                  ],
                                ),
                              ),
                            );
                          }
                          return _buildRequestCard(filteredRequests[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchRefCode,
          hintStyle: GoogleFonts.googleSans(color: Colors.grey[600], fontSize: 14),
          suffixIcon: const Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
        children: [
          _buildFilterChip(AppLocalizations.of(context).all, null, AppColors.primary),
          const SizedBox(width: 8),
          _buildFilterChip(AppLocalizations.of(context).statusPending, {RequestStatus.pending}, AppColors.primary),
          const SizedBox(width: 8),
          _buildFilterChip(AppLocalizations.of(context).statusPreparing, {RequestStatus.preparing}, AppColors.statusPreparing),
          const SizedBox(width: 8),
          _buildFilterChip(AppLocalizations.of(context).statusReady, {RequestStatus.ready}, AppColors.statusReady),
          const SizedBox(width: 8),
          _buildFilterChip(AppLocalizations.of(context).statusCompleted, {RequestStatus.completed}, AppColors.statusCompleted),
          const SizedBox(width: 8),
          _buildFilterChip(AppLocalizations.of(context).statusCancelled, {RequestStatus.cancelledByUser, RequestStatus.cancelledByStaff}, Colors.grey[600]!),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Set<RequestStatus>? filterSet, Color primaryColor) {
    final bool isSelected = _selectedFilterSet == filterSet ||
        (filterSet == null && _selectedFilterSet == null) ||
        (filterSet != null && _selectedFilterSet != null && filterSet.containsAll(_selectedFilterSet!) && _selectedFilterSet!.containsAll(filterSet));

    return Material(
      color: isSelected ? primaryColor : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterSet = filterSet;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.googleSans(
              color: isSelected ? AppColors.white : primaryColor,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(CondomRequestModel data) {
    final l10n = AppLocalizations.of(context);
    final visuals = RequestStatusVisuals.of(data.status);
    final Color iconBgColor = visuals.lightBg;
    final Color iconColor = visuals.color;
    final Color statusBgColor = visuals.color;
    const Color statusTextColor = AppColors.white;
    final IconData statusIcon = visuals.icon;
    final String statusText = data.status.isCancelled
        ? (data.status == RequestStatus.cancelledByStaff
            ? l10n.statusCancelledByStaff
            : l10n.statusCancelledByUser)
        : switch (data.status) {
            RequestStatus.preparing => l10n.statusPreparing,
            RequestStatus.ready => l10n.statusReady,
            RequestStatus.completed => l10n.statusCompleted,
            _ => l10n.statusPending,
          };

    // Format selectedDate and selectedTime
    String outputDate = data.selectedDate ?? '-';
    if (data.selectedDate != null && data.selectedDate!.contains('-')) {
      try {
        final parsedDate = DateTime.parse(data.selectedDate!);
        outputDate = '${parsedDate.day} ${AppLocalizations.of(context).monthsFull[parsedDate.month - 1]} ${parsedDate.year + 543}';
      } catch (e) {
        outputDate = data.selectedDate!;
      }
    }

    String outputTime = data.selectedTime ?? '-';
    if (data.selectedTime != null && data.selectedTime!.contains(':')) {
       final splitted = data.selectedTime!.split(':');
       if(splitted.length >= 2) {
          outputTime = '${splitted[0]}:${splitted[1]} ${AppLocalizations.of(context).timeWithUnit}';
       }
    }
    final dateStr = '$outputDate, $outputTime';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).referenceNumber,
                        style: GoogleFonts.googleSans(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        data.referenceNumber,
                        style: GoogleFonts.googleSans(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.googleSans(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.googleSans(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  data.selectedServiceCenter ?? '-',
                  style: GoogleFonts.googleSans(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(overlayColor: statusBgColor),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RequestHistoryDetailPage(data: data),
                    ),
                  );
                  // Refresh history after return to get updated statuses (like cancelled)
                  _fetchHistory();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).details,
                      style: TextStyle(
                        color: statusBgColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: statusBgColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
