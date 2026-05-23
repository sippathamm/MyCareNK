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
                    _buildInputBox(
                      child: TextFormField(
                        controller: _usernameController,
                        style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                          hintText: l10n.usernameHint,
                          hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.current.usernameRequired;
                          }
                          final val = value.trim();
                          if (val.length < 4 || val.length > 20) {
                            return AppLocalizations.current.usernameRange;
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(val)) {
                            return AppLocalizations.current.usernameInvalidChars;
                          }
                          return null;
                        },
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

                    _buildInputBox(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                          hintText: l10n.passwordHint,
                          hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          suffixIcon: _buildPasswordToggle(
                            obscure: _obscurePassword,
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.current.passwordRequired;
                          }
                          if (value.length < 8) {
                            return AppLocalizations.current.passwordTooShort;
                          }
                          if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(value)) {
                            return AppLocalizations.current.passwordStrength;
                          }
                          return null;
                        },
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

                    _buildInputBox(
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                          hintText: l10n.confirmPasswordHint,
                          hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          suffixIcon: _buildPasswordToggle(
                            obscure: _obscureConfirmPassword,
                            onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.current.confirmPasswordRequired;
                          }
                          if (value != _passwordController.text) {
                            return AppLocalizations.current.passwordMismatch;
                          }
                          return null;
                        },
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

  Widget _buildInputBox({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: padding,
      child: child,
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
