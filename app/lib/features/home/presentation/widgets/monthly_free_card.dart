import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyFreeCard extends StatefulWidget {
  const MonthlyFreeCard({super.key});

  @override
  State<MonthlyFreeCard> createState() => _MonthlyFreeCardState();
}

class _MonthlyFreeCardState extends State<MonthlyFreeCard> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [_buildCondomCard(), _buildLubricantCard()],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => Container(
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

  Widget _buildCondomCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEF1D2), // Top-left
            Color(0xFFFBCFB8), // Bottom-right
          ],
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
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '15 ',
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
          const SizedBox(height: 8),
          _buildAnimatedProgressBar(
            color: const Color(0xFFFF8A50),
            current: 15,
            total: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC0DEFB), // Top-left
            Color(0xFF86C0FA), // Bottom-right
          ],
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
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '15 ',
                  style: GoogleFonts.prompt(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A9FE8),
                  ),
                ),
                TextSpan(
                  text: 'ชิ้น',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A9FE8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildAnimatedProgressBar(
            color: const Color(0xFF4A9FE8),
            current: 15,
            total: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressBar({
    required Color color,
    required int current,
    required int total,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth * 0.7;
        final double percentage = current / total;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percentage),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
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
