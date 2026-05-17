import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';

class MonthlyFreeCard extends StatefulWidget {
  /// Incrementing this key from the parent re-triggers all animations.
  final int refreshKey;

  const MonthlyFreeCard({super.key, this.refreshKey = 0});

  @override
  State<MonthlyFreeCard> createState() => _MonthlyFreeCardState();
}

class _MonthlyFreeCardState extends State<MonthlyFreeCard> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  int _usedCondoms = AppConstants.maxCondomQuota;
  int _usedLubricants = AppConstants.maxLubricantQuota;
  int? _daysUntilReset;
  bool _isLoading = true;
  bool _isLoggedIn = true;

  // Bumped whenever data arrives or parent refreshKey changes —
  // used as ValueKey so TweenAnimationBuilder replays from 0.
  int _animationVersion = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _quotaSubscription;

  @override
  void initState() {
    super.initState();
    _fetchDaysUntilReset();
    _subscribeToQuota();
  }

  @override
  void didUpdateWidget(MonthlyFreeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _animationVersion++);
      _fetchDaysUntilReset();
      _subscribeToQuota();
    }
  }

  Future<void> _fetchDaysUntilReset() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _daysUntilReset = null);
      return;
    }
    try {
      final response = await Supabase.instance.client.rpc('get_days_until_reset');
      if (mounted) setState(() => _daysUntilReset = response as int?);
    } catch (e) {
      debugPrint('Error fetching days until reset: $e');
    }
  }

  void _subscribeToQuota() {
    _quotaSubscription?.cancel();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
          _animationVersion++;
        });
      }
      return;
    }
    _isLoggedIn = true;

    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);

    _quotaSubscription = Supabase.instance.client
        .from('user_monthly_quotas')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen(
          (rows) {
            final currentRow =
                rows.where((r) => r['month'] == monthStart).firstOrNull;
            if (mounted) {
              setState(() {
                _usedCondoms = (currentRow?['used_condoms'] as int?) ?? 0;
                _usedLubricants = (currentRow?['used_lubricants'] as int?) ?? 0;
                _isLoading = false;
                _animationVersion++;
              });
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _usedCondoms = AppConstants.maxCondomQuota;
                _usedLubricants = AppConstants.maxLubricantQuota;
                _isLoading = false;
                _animationVersion++;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _quotaSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final int remainingCondoms =
        (AppConstants.maxCondomQuota - _usedCondoms).clamp(0, AppConstants.maxCondomQuota);
    final int remainingLubricants =
        (AppConstants.maxLubricantQuota - _usedLubricants).clamp(
          0,
          AppConstants.maxLubricantQuota,
        );

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildCondomCard(remainingCondoms),
              _buildLubricantCard(remainingLubricants),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCondomCard(int remaining) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryCardStart, AppColors.primaryCardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryCardShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ถุงยางอนามัย',
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'สิทธิ์รับฟรีเดือนนี้',
            style: GoogleFonts.googleSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (_isLoggedIn)
            TweenAnimationBuilder<int>(
              key: ValueKey('condom_num_$_animationVersion'),
              tween: IntTween(begin: 0, end: remaining),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$value ',
                      style: GoogleFonts.googleSans(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'ชิ้น',
                      style: GoogleFonts.googleSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              '–',
              style: GoogleFonts.googleSans(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          const SizedBox(height: 8),
          _buildAnimatedProgressBar(
            animationKey: 'condom_bar_$_animationVersion',
            color: AppColors.primary,
            current: _isLoggedIn ? remaining : 0,
            total: AppConstants.maxCondomQuota,
          ),
          const SizedBox(height: 12),
          Text(
            _isLoggedIn
                ? (_daysUntilReset != null
                    ? 'จะรีเซ็ตในอีก $_daysUntilReset วัน'
                    : 'จะรีเซ็ตในอีก – วัน')
                : 'เข้าสู่ระบบเพื่อดูสิทธิ์ของคุณ',
            style: GoogleFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard(int remaining) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.lubricantCardStart, AppColors.lubricantCardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.lubricantShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เจลหล่อลื่น',
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'สิทธิ์รับฟรีเดือนนี้',
            style: GoogleFonts.googleSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (_isLoggedIn)
            TweenAnimationBuilder<int>(
              key: ValueKey('lubricant_num_$_animationVersion'),
              tween: IntTween(begin: 0, end: remaining),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$value ',
                      style: GoogleFonts.googleSans(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lubricant,
                      ),
                    ),
                    TextSpan(
                      text: 'ชิ้น',
                      style: GoogleFonts.googleSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.lubricant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              '–',
              style: GoogleFonts.googleSans(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.lubricant.withValues(alpha: 0.4),
              ),
            ),
          const SizedBox(height: 8),
          _buildAnimatedProgressBar(
            animationKey: 'lubricant_bar_$_animationVersion',
            color: AppColors.lubricant,
            current: _isLoggedIn ? remaining : 0,
            total: AppConstants.maxLubricantQuota,
          ),
          const SizedBox(height: 12),
          Text(
            _isLoggedIn
                ? (_daysUntilReset != null
                    ? 'จะรีเซ็ตในอีก $_daysUntilReset วัน'
                    : 'จะรีเซ็ตในอีก – วัน')
                : 'เข้าสู่ระบบเพื่อดูสิทธิ์ของคุณ',
            style: GoogleFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressBar({
    required String animationKey,
    required Color color,
    required int current,
    required int total,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth * 0.7;
        final double percentage = total > 0 ? current / total : 0;

        return TweenAnimationBuilder<double>(
          key: ValueKey(animationKey),
          tween: Tween<double>(begin: 0, end: percentage),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: totalWidth,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: totalWidth * value,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
