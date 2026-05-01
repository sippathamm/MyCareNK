import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../messages/presentation/pages/messages_page.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../service/presentation/pages/service_navigator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _homeVisibilityKey = 0;
  final GlobalKey<NavigatorState> _serviceNavigatorKey =
      GlobalKey<NavigatorState>();

  void _onItemTapped(int index) {
    if (_currentIndex == index && index == 1) {
      // If tapping on Service tab while already on it, navigate to the first route
      _serviceNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        if (index == 0 && _currentIndex != 0) {
          // Switching back to Home tab — bump key to replay animations
          _homeVisibilityKey++;
        }
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(visibilityKey: _homeVisibilityKey),
          ServiceNavigator(navigatorKey: _serviceNavigatorKey),
          const ScanPage(),
          const MessagesPage(),
          const Center(child: Text('Settings Screen Placeholder')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            activeIcon: Icon(Icons.grid_view, color: AppColors.primary),
            label: 'บริการ',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryButtonShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_outlined, color: AppColors.white),
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
      ),
    );
  }
}
