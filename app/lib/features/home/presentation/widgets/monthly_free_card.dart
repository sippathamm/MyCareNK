import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static const int maxCondomQuota = 60;
  static const int maxLubricantQuota = 30;

  int _usedCondoms = maxCondomQuota;
  int _usedLubricants = maxLubricantQuota;
  int? _daysUntilReset;
  bool _isLoading = true;

  // Version bumped whenever new data arrives OR parent refreshKey changes.
  // Used as ValueKey so TweenAnimationBuilder replays from 0 each time.
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
    // Parent incremented refreshKey (e.g. pull-to-refresh or route return)
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _animationVersion++);
      _fetchDaysUntilReset();
      _subscribeToQuota();
    }
  }

  Future<void> _fetchDaysUntilReset() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _daysUntilReset = null);
      }
      return;
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'get_days_until_reset',
      );
      if (mounted) {
        setState(() {
          _daysUntilReset = response as int?;
        });
      }
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
          _usedCondoms = maxCondomQuota;
          _usedLubricants = maxLubricantQuota;
          _isLoading = false;
          _animationVersion++;
        });
      }
      return;
    }

    final now = DateTime.now();
    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().substring(0, 10);

    _quotaSubscription = Supabase.instance.client
        .from('user_monthly_quotas')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen(
          (rows) {
            final currentRow = rows
                .where((r) => r['month'] == monthStart)
                .firstOrNull;
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
                _usedCondoms = maxCondomQuota;
                _usedLubricants = maxLubricantQuota;
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

    final int remainingCondoms = (maxCondomQuota - _usedCondoms).clamp(
      0,
      maxCondomQuota,
    );
    final int remainingLubricants = (maxLubricantQuota - _usedLubricants).clamp(
      0,
      maxLubricantQuota,
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
                    ? const Color(0xFFFF8A50)
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
          colors: [Color(0xFFFEF1D2), Color(0xFFFBCFB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ถุงยางอนามัย',
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
          Text(
            'สิทธิ์รับฟรีเดือนนี้',
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          // Animated number counter
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
                    style: GoogleFonts.prompt(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF8A50),
                    ),
                  ),
                  TextSpan(
                    text: 'ชิ้น',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFF8A50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildAnimatedProgressBar(
            animationKey: 'condom_bar_$_animationVersion',
            color: const Color(0xFFFF8A50),
            current: remaining,
            total: maxCondomQuota,
          ),
          const SizedBox(height: 12),
          Text(
            _daysUntilReset != null
                ? 'จะรีเซ็ตในอีก $_daysUntilReset วัน'
                : 'จะรีเซ็ตในอีก -- วัน',
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666).withOpacity(0.8),
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
          colors: [Color(0xFFC0DEFB), Color(0xFF86C0FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สารหล่อลื่น',
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
          Text(
            'สิทธิ์รับฟรีเดือนนี้',
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          // Animated number counter
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
                    style: GoogleFonts.prompt(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A9FE8),
                    ),
                  ),
                  TextSpan(
                    text: 'ซอง',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A9FE8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildAnimatedProgressBar(
            animationKey: 'lubricant_bar_$_animationVersion',
            color: const Color(0xFF4A9FE8),
            current: remaining,
            total: maxLubricantQuota,
          ),
          const SizedBox(height: 12),
          Text(
            _daysUntilReset != null
                ? 'จะรีเซ็ตในอีก $_daysUntilReset วัน'
                : 'จะรีเซ็ตในอีก -- วัน',
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666).withOpacity(0.8),
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
                    color: Colors.white.withOpacity(0.3),
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
