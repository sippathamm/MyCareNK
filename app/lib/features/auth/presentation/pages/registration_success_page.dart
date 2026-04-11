import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../widgets/recovery_codes_grid.dart';

class RegistrationSuccessPage extends StatelessWidget {
  final List<String> recoveryCodes;

  const RegistrationSuccessPage({super.key, required this.recoveryCodes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBackground, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'สร้างบัญชีใหม่สำเร็จ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Image.asset(
                    'assets/images/rocket.png',
                    width: 175,
                    height: 175,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'กรุณาเก็บรหัสกู้คืนทั้ง 6 ตัวนี้\nไว้ในที่ปลอดภัย หากคุณลืมรหัสผ่าน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                RecoveryCodesGrid(
                  recoveryCodes: recoveryCodes,
                  footerText: 'หากต้องการกู้คืนบัญชี ให้ใช้หนึ่งในรหัส 6 ตัวนี้',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      foregroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'ตกลง',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
