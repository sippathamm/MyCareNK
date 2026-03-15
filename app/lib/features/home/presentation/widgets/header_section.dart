import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = snapshot.data?.session;

            // If not logged in
            if (session == null) {
              return InkWell(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
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
              );
            }

            // If logged in
            final user = session.user;
            final metadata = user.userMetadata;
            final username = metadata?['username'] ?? 'User';

            return PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ออกจากระบบแล้ว')),
                    );
                  }
                }
              },
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE5FD),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFD1C4E9),
                      radius: 14,
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF7C4DFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF7C4DFF),
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
