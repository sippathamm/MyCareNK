import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'forgot_password_recovery_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordRecoveryCodePage(username: username),
      ),
    );
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
          'ลืมรหัสผ่าน',
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'กรอกชื่อผู้ใช้งานของคุณ',
                  style: GoogleFonts.googleSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เราจะพาคุณไปยืนยันตัวตนด้วยรหัสกู้คืน',
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Username field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _usernameController,
                    style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ชื่อผู้ใช้งาน',
                      hintStyle: GoogleFonts.googleSans(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อผู้ใช้งาน';
                      }
                      if (value.trim().length < 4) {
                        return 'ชื่อผู้ใช้งานต้องมีความยาวอย่างน้อย 4 ตัวอักษร';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
                        return 'ชื่อผู้ใช้งานต้องเป็นตัวอักษรภาษาอังกฤษหรือตัวเลขเท่านั้น';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'ถัดไป',
                      style: GoogleFonts.googleSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
