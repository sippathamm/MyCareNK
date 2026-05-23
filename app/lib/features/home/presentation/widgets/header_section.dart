import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/pages/login_page.dart';

class HeaderSection extends StatefulWidget {
  final VoidCallback? onGoToSettings;

  const HeaderSection({super.key, this.onGoToSettings});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  Future<Map<String, dynamic>?>? _profileFuture;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = snapshot.data?.session ??
                Supabase.instance.client.auth.currentSession;

            if (session == null) {
              return InkWell(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final loggedIn = await Navigator.of(context, rootNavigator: true)
                      .push<bool>(MaterialPageRoute(
                          builder: (context) => const LoginPage()));
                  if (loggedIn == true) {
                    final l10n = AppLocalizations.current;
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text(l10n.loggedIn, style: GoogleFonts.googleSans()),
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

                return InkWell(
                  onTap: widget.onGoToSettings,
                  borderRadius: BorderRadius.circular(24),
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
