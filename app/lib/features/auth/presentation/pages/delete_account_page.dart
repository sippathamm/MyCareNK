import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'login_page.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _confirmed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    if (password.isEmpty || !_confirmed) return;

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email ?? '',
        password: password,
      );

      await Supabase.instance.client.rpc('delete_own_account');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.deleteAccountSuccess, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on AuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).changePasswordWrongCurrent,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).deleteAccountError,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDelete = _confirmed && _passwordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.deleteAccountTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _confirmed,
                    onChanged: (v) => setState(() => _confirmed = v ?? false),
                    activeColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _confirmed = !_confirmed),
                      child: Text(
                        l10n.deleteAccountConfirmCheck,
                        style: GoogleFonts.googleSans(
                            fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GradientButton(
                onPressed: (canDelete && !_isLoading) ? _deleteAccount : null,
                label: l10n.deleteAccountTitle,
                isLoading: _isLoading,
                gradientColors: GradientButton.errorGradient,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.deleteAccountWarning,
                        style: GoogleFonts.googleSans(
                          fontSize: 14,
                          color: AppColors.error,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.changePasswordCurrentHint,
                    hintStyle:
                        GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
