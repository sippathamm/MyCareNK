import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/models/service_center_model.dart';
import '../../../../../core/services/service_center_service.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/request_step_indicator.dart';
import '../widgets/stepper_row_condom.dart';
import '../widgets/stepper_lubricant.dart';
import '../../../../../core/widgets/section_card.dart';
import '../widgets/condom_request_form_widgets.dart';
import 'condom_request_confirm_page.dart';
import 'request_history_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

// ── Date helpers ─────────────────────────────────────────────────────────────

List<DateTime> _buildDateList() {
  final list = <DateTime>[];
  var d = DateTime.now();
  while (list.length < 7) {
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      list.add(d);
    }
    d = d.add(const Duration(days: 1));
  }
  return list;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class CondomRequestPage extends StatefulWidget {
  const CondomRequestPage({super.key});

  @override
  State<CondomRequestPage> createState() => _CondomRequestPageState();
}

class _CondomRequestPageState extends State<CondomRequestPage> {
  final Map<int, int> _quantities = {
    for (final s in AppConstants.condomSizes) s: 0
  };
  int _lubricantQuantity = 0;
  String? _selectedServiceCenter;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _messageController = TextEditingController();
  int _animationVersion = 0;
  StreamSubscription<AuthState>? _authSubscription;
  final List<DateTime> _dates = _buildDateList();

  List<ServiceCenterModel> _centers = [];
  bool _centersLoading = true;
  bool _centersNotLoggedIn = false;

  int _currentMonthlyUsed = AppConstants.maxCondomQuota;
  int _currentMonthlyLubricantUsed = AppConstants.maxLubricantQuota;

  int get _totalSelected =>
      _quantities.values.fold(0, (sum, count) => sum + count);

  bool get _canProceed =>
      _totalSelected > 0 &&
      _selectedServiceCenter != null &&
      _selectedDate != null &&
      _selectedTime != null;

  @override
  void initState() {
    super.initState();
    _loadCenters();
    _fetchMonthlyQuota();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          _currentMonthlyUsed = AppConstants.maxCondomQuota;
          _currentMonthlyLubricantUsed = AppConstants.maxLubricantQuota;
          _animationVersion++;
        });
      } else if (data.event == AuthChangeEvent.signedIn) {
        _fetchMonthlyQuota();
        _loadCenters();
      }
    });
  }

  Future<void> _loadCenters() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (mounted) setState(() { _centersLoading = false; _centersNotLoggedIn = true; });
      return;
    }
    if (mounted) setState(() { _centersLoading = true; _centersNotLoggedIn = false; });
    try {
      final centers = await ServiceCenterService.fetchActive();
      if (mounted) setState(() { _centers = centers; _centersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _centersLoading = false);
    }
  }

  Future<void> _fetchMonthlyQuota() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
      final response = await Supabase.instance.client
          .from('user_monthly_quotas')
          .select('used_condoms, used_lubricants')
          .eq('user_id', user.id)
          .eq('month', monthStart)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _currentMonthlyUsed = (response?['used_condoms'] as int?) ?? 0;
          _currentMonthlyLubricantUsed =
              (response?['used_lubricants'] as int?) ?? 0;
          _animationVersion++;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _navigateToConfirm() {
    if (_totalSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectCondomFirst, style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CondomRequestConfirmPage(
          quantities: _quantities,
          lubricantQuantity: _lubricantQuantity,
          selectedServiceCenter: _selectedServiceCenter,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          message: _messageController.text,
          currentMonthlyUsed: _currentMonthlyUsed,
          maxMonthlyQuota: AppConstants.maxCondomQuota,
          currentMonthlyLubricantUsed: _currentMonthlyLubricantUsed,
          maxMonthlyLubricantQuota: AppConstants.maxLubricantQuota,
        ),
      ),
    );
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
            fontWeight: FontWeight.bold,
          ),
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
            child: buildRequestStepIndicator(context, 0),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonthlyQuotaSummary(
                    currentCondomUsed: _currentMonthlyUsed,
                    selectedCondoms: _totalSelected,
                    currentLubricantUsed: _currentMonthlyLubricantUsed,
                    selectedLubricant: _lubricantQuantity,
                    animationVersion: _animationVersion,
                  ),
                  const SizedBox(height: 20),
                  _buildQuantityCard(),
                  const SizedBox(height: 20),
                  _buildLubricantCard(),
                  const SizedBox(height: 20),
                  SectionCard(
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
                                      (i) => ServiceCenterPickerTile(
                                        center: _centers[i],
                                        index: i,
                                        selected: _selectedServiceCenter ==
                                            _centers[i].name,
                                        onTap: () => setState(() {
                                          if (_selectedServiceCenter !=
                                              _centers[i].name) {
                                            _selectedTime = null;
                                          }
                                          _selectedServiceCenter =
                                              _centers[i].name;
                                        }),
                                      ),
                                    ),
                                  ),
                  ),
                  SectionCard(
                    title: AppLocalizations.of(context).selectDateTitle,
                    icon: Icons.event_outlined,
                    child: PickupDateStrip(
                      center: _selectedCenter,
                      dates: _dates,
                      selectedDate: _selectedDate,
                      onSelect: (d) => setState(() => _selectedDate = d),
                    ),
                  ),
                  SectionCard(
                    title: AppLocalizations.of(context).selectTimeTitle,
                    icon: Icons.schedule_outlined,
                    child: PickupTimePicker(
                      center: _selectedCenter,
                      selectedTime: _selectedTime,
                      onSelect: (t) => setState(() => _selectedTime = t),
                    ),
                  ),
                  SectionCard(
                    title: AppLocalizations.of(context).addMessageTitle,
                    icon: Icons.comment_outlined,
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).addMessageHint,
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
                              color: AppColors.primary, width: 1.5),
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
                    child: GradientButton(
                      onPressed: _canProceed ? _navigateToConfirm : null,
                      label: AppLocalizations.of(context).next,
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

  ServiceCenterModel? get _selectedCenter =>
      _centers.where((c) => c.name == _selectedServiceCenter).firstOrNull;

  // ── Quantity card ───────────────────────────────────────────────────────────

  Widget _buildQuantityCard() {
    return Container(
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
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).condoms,
                    style: GoogleFonts.googleSans(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _quantities.entries.map((entry) {
                  final int totalUsed = _currentMonthlyUsed + _totalSelected;
                  final int remaining =
                      (AppConstants.maxCondomQuota - totalUsed)
                          .clamp(0, AppConstants.maxCondomQuota);
                  final int maxAllowed = entry.value + remaining;
                  return StepperRowCondom(
                    label: '${entry.key}',
                    count: entry.value,
                    max: maxAllowed,
                    onChanged: (val) =>
                        setState(() => _quantities[entry.key] = val),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(AppLocalizations.of(context).total,
                      style: GoogleFonts.googleSans(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const SizedBox(width: 38),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        '$_totalSelected',
                        style: GoogleFonts.googleSans(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: Text(AppLocalizations.of(context).pieces,
                      style: GoogleFonts.googleSans(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lubricant card ──────────────────────────────────────────────────────────

  Widget _buildLubricantCard() {
    final int totalLubricantUsed =
        _currentMonthlyLubricantUsed + _lubricantQuantity;
    final int remainingLubricant =
        (AppConstants.maxLubricantQuota - totalLubricantUsed)
            .clamp(0, AppConstants.maxLubricantQuota);
    final int maxLubricantAllowed = _lubricantQuantity + remainingLubricant;
    return SectionCard(
      title: AppLocalizations.of(context).extra,
      icon: Icons.add_circle_outline,
      margin: EdgeInsets.zero,
      child: StepperLubricant(
        label: AppLocalizations.of(context).lubricant,
        count: _lubricantQuantity,
        max: maxLubricantAllowed,
        onChanged: (val) => setState(() => _lubricantQuantity = val),
      ),
    );
  }
}
