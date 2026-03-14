import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'forgot_password_reset_page.dart';

class ForgotPasswordRecoveryCodePage extends StatefulWidget {
  const ForgotPasswordRecoveryCodePage({super.key});

  @override
  State<ForgotPasswordRecoveryCodePage> createState() => _ForgotPasswordRecoveryCodePageState();
}

class _ForgotPasswordRecoveryCodePageState extends State<ForgotPasswordRecoveryCodePage> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ลืมรหัสผ่าน',
          style: TextStyle(
            color: Color(0xFF333333),
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
              // Icon Box
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24.0),
              // Title Text
              const Text(
                'กรอกรหัสผ่านกู้คืนบัญชี',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 32.0),
              // Recovery Code Fields
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
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 1,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              // Next Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordResetPage(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'ถัดไป',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Help Button
              TextButton(
                onPressed: () {},
                child: Text(
                  'ต้องการความช่วยเหลือ?',
                  style: TextStyle(
                    color: colorScheme.primary,
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
