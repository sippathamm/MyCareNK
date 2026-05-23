import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import 'privacy_policy_page.dart';
import '../../../../core/l10n/app_localizations.dart';

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

  void _goToPrivacyPolicy() {
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectGender, style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectBirthDate, style: GoogleFonts.googleSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nationalityValue = _nationality == 'อื่นๆ'
        ? _customNationalityController.text.trim()
        : _nationality;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivacyPolicyPage(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          gender: _gender,
          dateOfBirth: _selectedDateOfBirth,
          nationality: nationalityValue,
        ),
      ),
    );
  }

  Widget _buildNationalityOption(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(value: value, activeColor: AppColors.primary),
        Text(label, style: GoogleFonts.googleSans(fontSize: 14)),
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
          AppLocalizations.of(context).registerTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: GradientButton(
            onPressed: _goToPrivacyPolicy,
            label: AppLocalizations.of(context).next,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
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
                      hintText: AppLocalizations.of(context).usernameHint,
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
                    AppLocalizations.of(context).usernameLength,
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
                      hintText: AppLocalizations.of(context).passwordHint,
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
                    AppLocalizations.of(context).passwordStrengthHint,
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
                      hintText: AppLocalizations.of(context).confirmPasswordHint,
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
                        return AppLocalizations.current.confirmPasswordRequired;
                      }
                      if (value != _passwordController.text) {
                        return AppLocalizations.current.passwordMismatch;
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
                                    AppLocalizations.of(context).gender,
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
                                      child: Text(AppLocalizations.of(context).male, style: GoogleFonts.googleSans()),
                                    ),
                                    DropdownMenuItem(
                                      value: 'หญิง',
                                      child: Text(AppLocalizations.of(context).female, style: GoogleFonts.googleSans()),
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
                                hintText: AppLocalizations.of(context).dateOfBirth,
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

                // Nationality
                RadioGroup<String>(
                  groupValue: _nationality,
                  onChanged: (val) => setState(() => _nationality = val!),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).nationality,
                            style: GoogleFonts.googleSans(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              runSpacing: 4,
                              children: [
                                _buildNationalityOption('ไทย', AppLocalizations.of(context).nationalityThai),
                                _buildNationalityOption('ลาว', AppLocalizations.of(context).nationalityLao),
                                _buildNationalityOption('พม่า', AppLocalizations.of(context).nationalityMyanmar),
                                _buildNationalityOption('อื่นๆ', AppLocalizations.of(context).nationalityOther),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_nationality == 'อื่นๆ') ...[
                        const SizedBox(height: 8),
                        _buildInputBox(
                          child: TextFormField(
                            controller: _customNationalityController,
                            style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.language, color: Colors.grey[400]),
                              hintText: AppLocalizations.of(context).specifyNationality,
                              hintStyle: GoogleFonts.googleSans(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            validator: (_) {
                              if (_nationality == 'อื่นๆ' &&
                                  _customNationalityController.text.trim().isEmpty) {
                                return AppLocalizations.current.nationalityRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ],
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
