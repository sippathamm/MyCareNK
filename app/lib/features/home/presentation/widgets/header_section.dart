import 'package:flutter/material.dart';
import 'emergency_button.dart';
import '../../../auth/presentation/pages/login_page.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const EmergencyButton(),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFEFE5FD), // Light purple background
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFD1C4E9),
              radius: 20,
              child: Icon(Icons.person, color: Color(0xFF7C4DFF)),
            ),
          ),
        ),
      ],
    );
  }
}
