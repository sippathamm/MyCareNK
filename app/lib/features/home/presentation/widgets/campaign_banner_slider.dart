import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/pages/register_step1_page.dart';
import 'campaign_banner.dart';

class CampaignBannerSlider extends StatefulWidget {
  const CampaignBannerSlider({super.key});

  @override
  State<CampaignBannerSlider> createState() => _CampaignBannerSliderState();
}

class _CampaignBannerSliderState extends State<CampaignBannerSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  bool _isLoggedIn = false;
  Timer? _autoScrollTimer;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = Supabase.instance.client.auth.currentUser != null;
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients || _isLoggedIn) return;
      final next = (_currentPage + 1) % 2;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _authSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: const CampaignBanner(),
              ),
              if (!_isLoggedIn)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: const _RegisterBanner(),
                ),
            ],
          ),
        ),
        if (!_isLoggedIn) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => _SliderDot(active: i == _currentPage),
            ),
          ),
        ],
      ],
    );
  }
}

class _SliderDot extends StatelessWidget {
  final bool active;
  const _SliderDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active ? const Color(0xFF6A1B9A) : Colors.grey.shade300,
      ),
    );
  }
}

class _RegisterBanner extends StatelessWidget {
  const _RegisterBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE07A42), Color(0xFFFF9F6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE07A42).withAlpha(70),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterStep1Page()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Watermark icon — replaces circles for a distinct look
                Positioned(
                  right: -12,
                  top: -12,
                  child: Icon(
                    Icons.how_to_reg_rounded,
                    size: 96,
                    color: Colors.white.withAlpha(22),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Rounded-square container — distinct from the HIV banner's circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.campaignRegisterTitle,
                              style: GoogleFonts.googleSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.campaignRegisterSubtitle,
                              style: GoogleFonts.googleSans(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
