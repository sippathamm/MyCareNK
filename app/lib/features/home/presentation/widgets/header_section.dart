import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import 'emergency_button.dart';
import '../../../auth/presentation/pages/login_page.dart';

class HeaderSection extends StatefulWidget {
  const HeaderSection({super.key});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  Future<Map<String, dynamic>?>? _profileFuture;
  String? _lastUserId;

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

            if (session == null) {
              return InkWell(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final loggedIn = await Navigator.of(context, rootNavigator: true)
                      .push<bool>(MaterialPageRoute(builder: (context) => const LoginPage()));
                  if (loggedIn == true) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('เข้าสู่ระบบแล้ว',
                            style: GoogleFonts.googleSans()),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.avatarBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: AppColors.avatarCircle,
                    radius: 20,
                    child: Icon(Icons.person, color: AppColors.avatarIcon),
                  ),
                ),
              );
            }

            final user = session.user;

            // Re-fetch only when user ID changes
            if (_lastUserId != user.id || _profileFuture == null) {
              _lastUserId = user.id;
              _profileFuture = Supabase.instance.client
                  .from('user_profiles')
                  .select('username')
                  .eq('user_id', user.id)
                  .maybeSingle();
            }

            return FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, profileSnapshot) {
                final username =
                    profileSnapshot.data?['username'] as String? ??
                    user.userMetadata?['username'] as String? ??
                    'User';

                return PopupMenuButton<String>(
                  tooltip: 'บัญชีผู้ใช้',
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ออกจากระบบแล้ว', style: GoogleFonts.googleSans()),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ออกจากระบบ',
                            style: GoogleFonts.googleSans(
                              color: AppColors.error,
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
                      color: AppColors.avatarBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.avatarCircle,
                          radius: 14,
                          child: Icon(
                            Icons.person,
                            color: AppColors.avatarIcon,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          username,
                          style: GoogleFonts.googleSans(
                            color: AppColors.avatarIcon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.avatarIcon,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
