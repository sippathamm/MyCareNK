import 'package:flutter/material.dart';
import '../widgets/recovery_codes_grid.dart';
import 'login_page.dart';

/// Displays the new recovery codes after a successful password reset.
class RecoveryCodesDisplayPage extends StatelessWidget {
  final List<String> recoveryCodes;

  const RecoveryCodesDisplayPage({super.key, required this.recoveryCodes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7E6), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'เปลี่ยนรหัสผ่านสำเร็จ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8A50),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCC80),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFFFF8A50),
                    size: 48,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'กรุณาเก็บรหัสกู้คืนใหม่ทั้ง 6 ตัวนี้\nไว้ในที่ปลอดภัย หากคุณลืมรหัสผ่าน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                RecoveryCodesGrid(
                  recoveryCodes: recoveryCodes,
                  footerText:
                      'รหัสกู้คืนชุดเก่าใช้ไม่ได้แล้ว\nหากต้องการกู้คืนบัญชี ให้ใช้หนึ่งในรหัสชุดใหม่นี้',
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => route.isFirst,
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
                      'กลับไปเข้าสู่ระบบ',
                      style: TextStyle(
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
