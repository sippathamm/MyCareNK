import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../main/presentation/pages/main_page.dart';

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
            colors: [
              Color(0xFFFFF7E6), // Light yellowish/orange at top
              Color(0xFFFFFFFF), // White at bottom
            ],
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
                  'สร้างบัญชีใหม่สำเร็จ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8A50),
                  ),
                ),
                const SizedBox(height: 32),

                // Rocket Image
                Image.asset(
                  'assets/images/rocket.png',
                  width: 175, // Adjusted size
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
                        child: Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                const Text(
                  'กรุณาเก็บรหัสกู้คืนทั้ง 6 ตัวนี้\nไว้ในที่ปลอดภัย หากคุณลืมรหัสผ่าน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Recovery Codes Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: recoveryCodes
                      .map((code) => _buildCodeBox(code))
                      .toList(),
                ),

                const SizedBox(height: 24),

                const Text(
                  'หากต้องการกู้คืนบัญชี ให้ใช้หนึ่งในรหัส 6 หลักนี้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),

                const SizedBox(height: 32),

                // Copy All Button
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: recoveryCodes.join(', ')),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('คัดลอกรหัสทั้งหมดแล้ว')),
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
                      'คัดลอกรหัสทั้งหมด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // OK Button
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
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

  Widget _buildCodeBox(String code) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Very light orange
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}
