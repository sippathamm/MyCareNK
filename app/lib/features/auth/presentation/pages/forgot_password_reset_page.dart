import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/recovery_service.dart';
import 'recovery_codes_display_page.dart';

class ForgotPasswordResetPage extends StatefulWidget {
  final String username;
  final String recoveryCode;

  const ForgotPasswordResetPage({
    super.key,
    required this.username,
    required this.recoveryCode,
  });

  @override
  State<ForgotPasswordResetPage> createState() =>
      _ForgotPasswordResetPageState();
}

class _ForgotPasswordResetPageState extends State<ForgotPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final RecoveryService _recoveryService = RecoveryService();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _recoveryService.resetPassword(
        username: widget.username,
        recoveryCode: widget.recoveryCode,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success && result.newRecoveryCodes != null) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => RecoveryCodesDisplayPage(
              recoveryCodes: result.newRecoveryCodes!,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error ?? 'ชื่อผู้ใช้งานหรือรหัสกู้คืนไม่ถูกต้อง',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ลืมรหัสผ่าน',
          style: TextStyle(
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.lock_reset, color: colorScheme.primary, size: 40),
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'กรอกรหัสผ่านใหม่',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32.0),

                // New Password Field
                _buildInputBox(
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[400],
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่านใหม่';
                      }
                      if (value.length < 8) {
                        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร';
                      }
                      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(value)) {
                        return 'รหัสผ่านต้องมีทั้งตัวอักษรและตัวเลข';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16.0),

                // Confirm Password Field
                _buildInputBox(
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'ยืนยันรหัสผ่านใหม่',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[400],
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณายืนยันรหัสผ่านใหม่';
                      }
                      if (value != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 48.0),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ตกลง',
                            style: TextStyle(
                              fontSize: 16.0,
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

  Widget _buildInputBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: child,
    );
  }
}
