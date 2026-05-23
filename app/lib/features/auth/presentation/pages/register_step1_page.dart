import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/register_step_indicator.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'register_step2_page.dart';

class RegisterStep1Page extends StatefulWidget {
  const RegisterStep1Page({super.key});

  @override
  State<RegisterStep1Page> createState() => _RegisterStep1PageState();
}

class _RegisterStep1PageState extends State<RegisterStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterStep2Page(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.registerTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          buildRegisterStepIndicator(context, 0),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormField<void>(
                      autovalidateMode: AutovalidateMode.disabled,
                      validator: (_) {
                        final v = _usernameController.text.trim();
                        if (v.isEmpty) return AppLocalizations.current.usernameRequired;
                        if (v.length < 4 || v.length > 20) return AppLocalizations.current.usernameRange;
                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) return AppLocalizations.current.usernameInvalidChars;
                        return null;
                      },
                      builder: (field) => _buildFieldContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Icon(Icons.person_outline, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _usernameController,
                                  style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: l10n.usernameHint,
                                    hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ]),
                            if (field.hasError) _buildErrorText(field.errorText!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        l10n.usernameLength,
                        style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    FormField<void>(
                      autovalidateMode: AutovalidateMode.disabled,
                      validator: (_) {
                        final v = _passwordController.text;
                        if (v.isEmpty) return AppLocalizations.current.passwordRequired;
                        if (v.length < 8) return AppLocalizations.current.passwordTooShort;
                        if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(v)) return AppLocalizations.current.passwordStrength;
                        return null;
                      },
                      builder: (field) => _buildFieldContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: l10n.passwordHint,
                                    hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    suffixIcon: _buildPasswordToggle(
                                      obscure: _obscurePassword,
                                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            if (field.hasError) _buildErrorText(field.errorText!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        l10n.passwordStrengthHint,
                        style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    FormField<void>(
                      autovalidateMode: AutovalidateMode.disabled,
                      validator: (_) {
                        final v = _confirmPasswordController.text;
                        if (v.isEmpty) return AppLocalizations.current.confirmPasswordRequired;
                        if (v != _passwordController.text) return AppLocalizations.current.passwordMismatch;
                        return null;
                      },
                      builder: (field) => _buildFieldContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: l10n.confirmPasswordHint,
                                    hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    suffixIcon: _buildPasswordToggle(
                                      obscure: _obscureConfirmPassword,
                                      onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            if (field.hasError) _buildErrorText(field.errorText!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GradientButton(onPressed: _next, label: l10n.next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  Widget _buildErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        message,
        style: GoogleFonts.googleSans(color: AppColors.error, fontSize: 12),
      ),
    );
  }

  Widget _buildPasswordToggle({required bool obscure, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey[400],
      ),
      onPressed: onTap,
    );
  }
}
