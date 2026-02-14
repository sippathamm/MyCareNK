import 'package:flutter/material.dart';
import '../widgets/service_card.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0, // Match HomePage padding
            vertical: 16.0,
          ),
          child: Column(
            children: [
              ServiceCard(
                icon: Icons.location_on,
                title: 'รับถุงยางอนามัย',
                subtitle: 'ค้นหาสถานที่และรับถุงยางอนามัยฟรี',
                onTap: () {
                  // TODO: Navigate to Condom Service
                },
              ),
              const SizedBox(height: 12), // Spacing between cards
              ServiceCard(
                icon: Icons
                    .assignment, // Using assignment as clipboard alternative
                title: 'ประเมินความเสี่ยง HIV',
                subtitle: 'ทำแบบทดสอบเพื่อประเมินความเสี่ยงติดเชื้อ HIV',
                onTap: () {
                  // TODO: Navigate to HIV Assessment
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF8A50),
        unselectedItemColor: const Color(0xFF777777),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 1, // Highlight 'Services'
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'หน้าหลัก',
          ),
          const BottomNavigationBarItem(
            icon: Icon(
              Icons.grid_view,
            ), // Using grid_view as 'Services' icon often
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
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop(); // Go back to Home
          }
        },
      ),
    );
  }
}
