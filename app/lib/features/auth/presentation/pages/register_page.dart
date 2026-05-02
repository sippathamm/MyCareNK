import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/recovery_service.dart';
import 'registration_success_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _gender;
  DateTime? _selectedDateOfBirth;
  String _nationality = 'ไทย';
  final _customNationalityController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customNationalityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกเพศ'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันเกิด'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_nationality == 'อื่นๆ' && _customNationalityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุสัญชาติ'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final nationalityValue = _nationality == 'อื่นๆ'
        ? _customNationalityController.text.trim()
        : _nationality;

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final proxyEmail = '$username${AppConstants.proxyEmailDomain}';

      final response = await Supabase.instance.client.auth.signUp(
        email: proxyEmail,
        password: password,
      );

      debugPrint('[Registration] User: $username, ID: ${response.user?.id}');

      await Supabase.instance.client.auth.signInWithPassword(
        email: proxyEmail,
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        await Supabase.instance.client.from('user_profiles').upsert({
          'user_id': userId,
          'username': username,
          'gender': _gender,
          'nationality': nationalityValue,
          'date_of_birth': _selectedDateOfBirth!.toIso8601String().split('T')[0],
        });
      }

      // Check mounted before any context use after the last await
      if (!mounted) return;

      final recoveryService = RecoveryService();
      final recoveryCodes = RecoveryService.generateRecoveryCodes();

      try {
        await recoveryService.saveRecoveryCodes(recoveryCodes);
        debugPrint('บันทึกรหัสกู้คืนทั้ง 6 ชุดเรียบร้อยแล้ว');
      } catch (e) {
        debugPrint('เกิดข้อผิดพลาดในการบันทึกรหัสกู้คืน: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              RegistrationSuccessPage(recoveryCodes: recoveryCodes),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      String errorMessage = e.message;
      if (errorMessage.toLowerCase().contains('already registered') ||
          errorMessage.toLowerCase().contains('already exists')) {
        errorMessage = 'ชื่อผู้ใช้งานนี้มีอยู่ในระบบแล้ว';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint('Error during registration: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสร้างบัญชี'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildNationalityOption(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(value: value, activeColor: AppColors.primary),
        Text(value, style: GoogleFonts.googleSans(fontSize: 14)),
      ],
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
          'สร้างบัญชีใหม่',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Username Field
                _buildInputBox(
                  child: TextFormField(
                    controller: _usernameController,
                    style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                      hintText: 'ชื่อผู้ใช้งาน',
                      hintStyle: GoogleFonts.googleSans(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
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
                      final val = value.trim();
                      if (val.length < 4 || val.length > 20) {
                        return 'ชื่อผู้ใช้งานต้องมีความยาว 4-20 ตัวอักษร';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(val)) {
                        return 'ชื่อผู้ใช้งานต้องเป็นตัวอักษรภาษาอังกฤษหรือตัวเลขเท่านั้น';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'ตัวอักษรภาษาอังกฤษหรือตัวเลข (4–20 ตัว)',
                    style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Password Field
                _buildInputBox(
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                      hintText: 'รหัสผ่าน',
                      hintStyle: GoogleFonts.googleSans(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      suffixIcon: _buildPasswordToggle(
                        obscure: _obscurePassword,
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
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
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'ต้องมีทั้งตัวอักษรและตัวเลข อย่างน้อย 8 ตัว',
                    style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Confirm Password Field
                _buildInputBox(
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                      hintText: 'ยืนยันรหัสผ่าน',
                      hintStyle: GoogleFonts.googleSans(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      suffixIcon: _buildPasswordToggle(
                        obscure: _obscureConfirmPassword,
                        onTap: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณายืนยันรหัสผ่าน';
                      }
                      if (value != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16.0),

                // Gender & Date of Birth Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInputBox(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Row(
                            children: [
                              Icon(Icons.wc, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _gender,
                                  isExpanded: true,
                                  hint: Text(
                                    'เพศ',
                                    style: GoogleFonts.googleSans(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey[400],
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'ชาย',
                                      child: Text('ชาย', style: GoogleFonts.googleSans()),
                                    ),
                                    DropdownMenuItem(
                                      value: 'หญิง',
                                      child: Text('หญิง', style: GoogleFonts.googleSans()),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _gender = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 4,
                      child: GestureDetector(
                        onTap: _pickDateOfBirth,
                        child: _buildInputBox(
                          child: AbsorbPointer(
                            child: TextFormField(
                              key: ValueKey(_selectedDateOfBirth),
                              initialValue: _selectedDateOfBirth == null
                                  ? ''
                                  : '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year + 543}',
                              style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                hintText: 'วัน/เดือน/ปีเกิด',
                                hintStyle: GoogleFonts.googleSans(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                // Nationality Row
                Row(
                  children: [
                    Text(
                      'สัญชาติ',
                      style: GoogleFonts.googleSans(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RadioGroup<String>(
                        groupValue: _nationality,
                        onChanged: (val) => setState(() => _nationality = val!),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 0,
                          children: [
                            _buildNationalityOption('ไทย'),
                            _buildNationalityOption('ลาว'),
                            _buildNationalityOption('พม่า'),
                            _buildNationalityOption('อื่นๆ'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_nationality == 'อื่นๆ') ...[
                  const SizedBox(height: 12),
                  _buildInputBox(
                    child: TextFormField(
                      controller: _customNationalityController,
                      style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.public_outlined, color: Colors.grey[400]),
                        hintText: 'ระบุสัญชาติ',
                        hintStyle: GoogleFonts.googleSans(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 48.0),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _register,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
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
                        : Text(
                            'ตกลง',
                            style: GoogleFonts.googleSans(
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

  Widget _buildInputBox({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: padding,
      child: child,
    );
  }

  Widget _buildPasswordToggle({
    required bool obscure,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey[400],
      ),
      onPressed: onTap,
    );
  }
}
