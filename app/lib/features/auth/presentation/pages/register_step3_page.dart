import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/register_step_indicator.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'privacy_policy_page.dart';

class RegisterStep3Page extends StatefulWidget {
  final String username;
  final String password;
  final String? gender;
  final DateTime? dateOfBirth;
  final String nationality;
  final String healthCoverage;

  const RegisterStep3Page({
    super.key,
    required this.username,
    required this.password,
    required this.gender,
    required this.dateOfBirth,
    required this.nationality,
    required this.healthCoverage,
  });

  @override
  State<RegisterStep3Page> createState() => _RegisterStep3PageState();
}

class _RegisterStep3PageState extends State<RegisterStep3Page> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _skip() => _toPrivacy(phone: null, nickname: null);

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    _toPrivacy(
      phone: _phoneController.text.trim(),
      nickname: _nicknameController.text.trim(),
    );
  }

  void _toPrivacy({String? phone, String? nickname}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PrivacyPolicyPage(
        username: widget.username,
        password: widget.password,
        gender: widget.gender,
        dateOfBirth: widget.dateOfBirth,
        nationality: widget.nationality,
        healthCoverage: widget.healthCoverage,
        phoneNumber: phone,
        nickname: nickname,
      ),
    ));
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
          buildRegisterStepIndicator(context, 2),
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
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),
                          hintText: l10n.phoneNumberHint,
                          hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.phoneNumberRequired;
                          }
                          if (value.length != 10) {
                            return l10n.phoneNumberInvalid;
                          }
                          if (!value.startsWith('0')) {
                            return l10n.phoneNumberInvalid;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        l10n.phoneNumberHelper,
                        style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInputBox(
                      child: TextFormField(
                        controller: _nicknameController,
                        style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey[400]),
                          hintText: l10n.nicknameHint,
                          hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.nicknameRequired;
                          }
                          if (value.trim().length > 50) {
                            return l10n.nicknameTooLong;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        l10n.nicknameHelper,
                        style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Privacy info frame
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        border: Border.all(color: AppColors.primaryLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.privacyFrameTitle,
                                  style: GoogleFonts.googleSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.privacyFrameBody,
                                  style: GoogleFonts.googleSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientButton(onPressed: _next, label: l10n.next),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: _skip,
                      child: Text(l10n.skip,
                          style: GoogleFonts.googleSans(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
