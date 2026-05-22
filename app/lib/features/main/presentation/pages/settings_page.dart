import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/privacy_policy_page.dart';
import '../../../auth/presentation/pages/profile_edit_page.dart';
import '../../../auth/presentation/pages/change_password_page.dart';
import '../../../auth/presentation/pages/manage_recovery_codes_page.dart';
import '../../../auth/presentation/pages/delete_account_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.navSettings,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session ??
              Supabase.instance.client.auth.currentSession;
          final isLoggedIn = session != null;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoggedIn) ...[
                  _buildSection(l10n.settingsAccountSection),
                  _buildTile(
                    icon: Icons.person_outline,
                    title: l10n.profileTitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.lock_outline,
                    title: l10n.changePasswordTitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.shield_outlined,
                    title: l10n.recoveryCodesManageTitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageRecoveryCodesPage()),
                    ),
                  ),
                  _buildDivider(),
                ] else ...[
                  _buildLoginBanner(context, l10n),
                ],
                _buildSection(l10n.settingsDisplaySection),
                _buildLanguageTile(context, l10n),
                _buildDivider(),
                _buildSection(l10n.settingsAboutSection),
                _buildTile(
                  icon: Icons.description_outlined,
                  title: l10n.privacyPolicyTitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(readOnly: true),
                    ),
                  ),
                ),
                _buildVersionTile(l10n),
                if (isLoggedIn) ...[
                  _buildDivider(),
                  _buildSection(l10n.settingsDangerSection),
                  _buildTile(
                    icon: Icons.logout,
                    title: l10n.logout,
                    titleColor: AppColors.error,
                    iconColor: AppColors.error,
                    showChevron: false,
                    onTap: () => _confirmLogout(context, l10n),
                  ),
                  _buildTile(
                    icon: Icons.delete_outline,
                    title: l10n.deleteAccountTitle,
                    titleColor: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
      child: Text(
        label,
        style: GoogleFonts.googleSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 24, endIndent: 24);

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.googleSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildVersionTile(AppLocalizations l10n) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
      title: Text(
        l10n.appVersion,
        style: GoogleFonts.googleSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Text(
        _version,
        style: GoogleFonts.googleSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, AppLocalizations l10n) {
    final provider = LocaleProvider.of(context);
    final currentCode = provider.locale.languageCode;
    final langLabels = {'th': '🇹🇭 ไทย', 'lo': '🇱🇦 ລາວ', 'my': '🇲🇲 မြန်မာ'};
    final currentLabel = langLabels[currentCode] ?? '🇹🇭 ไทย';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: const Icon(Icons.language, color: AppColors.primary, size: 22),
      title: Text(
        l10n.languageLabel,
        style: GoogleFonts.googleSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLabel,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
      ),
      onTap: () => _showLanguageSheet(context, l10n, provider),
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    AppLocalizations l10n,
    LocaleProvider provider,
  ) {
    final langs = [
      ('th', '🇹🇭', 'ไทย'),
      ('lo', '🇱🇦', 'ລາວ'),
      ('my', '🇲🇲', 'မြန်မာ'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.selectLanguage,
                  style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...langs.map((lang) {
                final (code, flag, name) = lang;
                final isSelected = provider.locale.languageCode == code;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    name,
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.onLocaleChange(Locale(code));
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginBanner(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.avatarCircle,
              radius: 28,
              child: Icon(Icons.person, color: AppColors.avatarIcon, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.pleaseLogin,
              style: GoogleFonts.googleSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.notLoggedInSettingsBody,
              style: GoogleFonts.googleSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GradientButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              label: l10n.loginBtn,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.logout,
          style: GoogleFonts.googleSans(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.logoutConfirmMessage,
          style: GoogleFonts.googleSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: GoogleFonts.googleSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout,
                style: GoogleFonts.googleSans(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.current.loggedOut,
            style: GoogleFonts.googleSans()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
