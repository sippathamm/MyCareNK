import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/recovery_service.dart';
import 'registration_success_page.dart';
import '../../../../core/l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final String username;
  final String password;
  final String? gender;
  final DateTime? dateOfBirth;
  final String nationality;
  final bool readOnly;

  const PrivacyPolicyPage({
    super.key,
    this.username = '',
    this.password = '',
    this.gender,
    this.dateOfBirth,
    this.nationality = '',
    this.readOnly = false,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _hasAgreed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasScrolledToBottom) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 32) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final username = widget.username;
      final password = widget.password;
      const domain = '@mycarenk.local';
      final proxyEmail = '$username$domain';

      final response = await Supabase.instance.client.auth.signUp(
        email: proxyEmail,
        password: password,
      );

      await Supabase.instance.client.auth.signInWithPassword(
        email: proxyEmail,
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        await Supabase.instance.client.from('user_profiles').upsert({
          'user_id': userId,
          'username': username,
          'gender': widget.gender,
          'nationality': widget.nationality,
          'date_of_birth':
              widget.dateOfBirth!.toIso8601String().split('T')[0],
        });
      }

      if (!mounted) return;

      final recoveryService = RecoveryService();
      final recoveryCodes = RecoveryService.generateRecoveryCodes();
      try {
        await recoveryService.saveRecoveryCodes(recoveryCodes);
      } catch (e) {
        debugPrint('เกิดข้อผิดพลาดในการบันทึกรหัสกู้คืน: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegistrationSuccessPage(recoveryCodes: recoveryCodes),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (msg.toLowerCase().contains('breach') ||
          msg.toLowerCase().contains('found in a')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            AppLocalizations.of(context).passwordLeaked,
            style: GoogleFonts.googleSans(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.of(context).pop();
        return;
      }
      if (msg.toLowerCase().contains('already registered') ||
          msg.toLowerCase().contains('already exists')) {
        msg = AppLocalizations.of(context).usernameExists;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).createAccountError,
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
          AppLocalizations.of(context).privacyPolicyTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: _buildContent(),
            ),
          ),
          if (!widget.readOnly) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntro(l10n),
        const SizedBox(height: 28),
        _buildSection(number: '1', title: l10n.privacySection1Title, body: l10n.privacySection1Body),
        const SizedBox(height: 24),
        _buildSection(number: '2', title: l10n.privacySection2Title, body: l10n.privacySection2Body),
        const SizedBox(height: 24),
        _buildSection(number: '3', title: l10n.privacySection3Title, body: l10n.privacySection3Body),
        const SizedBox(height: 24),
        _buildSection(number: '4', title: l10n.privacySection4Title, body: l10n.privacySection4Body),
        const SizedBox(height: 28),
        _buildContact(l10n),
      ],
    );
  }

  Widget _buildIntro(AppLocalizations l10n) {
    return Text(
      l10n.privacyPolicyIntro,
      style: GoogleFonts.googleSans(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.7,
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryCardStart,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Text(
            body,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContact(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCardStart,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.contact_support_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.privacyContactText,
              style: GoogleFonts.googleSans(
                fontSize: 13,
                color: AppColors.primary,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _hasScrolledToBottom
                ? () => setState(() => _hasAgreed = !_hasAgreed)
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _hasAgreed,
                    onChanged: _hasScrolledToBottom
                        ? (v) => setState(() => _hasAgreed = v ?? false)
                        : null,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(
                      color: _hasScrolledToBottom
                          ? AppColors.primary
                          : const Color(0xFFCCCCCC),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).privacyPolicyCheckbox,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasScrolledToBottom
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_hasScrolledToBottom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.arrow_downward,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context).privacyPolicyScrollHint,
                  style: GoogleFonts.googleSans(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GradientButton(
            onPressed: (_hasAgreed && !_isLoading) ? _register : null,
            label: AppLocalizations.of(context).ok,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
