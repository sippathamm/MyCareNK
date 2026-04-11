import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/recovery_service.dart';
import 'forgot_password_reset_page.dart';

class ForgotPasswordRecoveryCodePage extends StatefulWidget {
  final String username;

  const ForgotPasswordRecoveryCodePage({super.key, required this.username});

  @override
  State<ForgotPasswordRecoveryCodePage> createState() =>
      _ForgotPasswordRecoveryCodePageState();
}

class _ForgotPasswordRecoveryCodePageState
    extends State<ForgotPasswordRecoveryCodePage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  final RecoveryService _recoveryService = RecoveryService();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _onNext() async {
    final recoveryCode =
        _controllers.map((c) => c.text.trim().toUpperCase()).join();

    if (recoveryCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกรหัสกู้คืนให้ครบ 6 หลัก'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _recoveryService.verifyCode(
        username: widget.username,
        recoveryCode: recoveryCode,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordResetPage(
              username: widget.username,
              recoveryCode: recoveryCode,
            ),
          ),
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
                child: Icon(Icons.lock_outline, color: colorScheme.primary, size: 40),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'กรอกรหัสผ่านกู้คืนบัญชี',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-fA-F0-9]')),
                          LengthLimitingTextInputFormatter(1),
                        ],
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) => _onChanged(value, index),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48.0),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _onNext,
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
                          'ถัดไป',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {},
                child: Text(
                  'ต้องการความช่วยเหลือ?',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
