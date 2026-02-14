import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../service/presentation/pages/service_navigator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _serviceNavigatorKey =
      GlobalKey<NavigatorState>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const HomePage(),
      ServiceNavigator(navigatorKey: _serviceNavigatorKey),
      const Center(child: Text('Scan Screen Placeholder')), // Placeholder
      const Center(child: Text('Message Screen Placeholder')), // Placeholder
      const Center(child: Text('Settings Screen Placeholder')), // Placeholder
    ]);
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index && index == 1) {
      // If tapping on Service tab while already on it, navigate to the first route
      _serviceNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF8A50),
        unselectedItemColor: const Color(0xFF777777),
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
            activeIcon: Icon(Icons.grid_view, color: Color(0xFFFF8A50)),
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
      ),
    );
  }
}
