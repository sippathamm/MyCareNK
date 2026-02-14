import 'package:flutter/material.dart';
import '../../../../features/service/presentation/pages/service_screen.dart';
import '../widgets/header_section.dart';
import '../widgets/monthly_free_card.dart';
import '../widgets/shortcut_menu.dart';
import '../widgets/knowledge_section.dart';
import '../widgets/campaign_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderSection(),
                const SizedBox(height: 24),
                const MonthlyFreeCard(),
                const SizedBox(height: 24),
                const ShortcutMenu(),
                const SizedBox(height: 24),
                const KnowledgeSection(),
                const SizedBox(height: 24),
                const CampaignBanner(),
                const SizedBox(height: 24), // Extra spacing at bottom
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF8A50),
        unselectedItemColor: const Color(0xFF777777),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 0, // Highlight Home
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'บริการ',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66FF8A50),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            ),
            label: 'สแกน',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'ข้อความ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'ตั้งค่า',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ServiceScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            final labels = ['หน้าหลัก', 'บริการ', 'สแกน', 'ข้อความ', 'ตั้งค่า'];
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('"${labels[index]}" ถูกกด')));
          }
        },
      ),
    );
  }
}
