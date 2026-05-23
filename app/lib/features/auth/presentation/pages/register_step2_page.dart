import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/register_step_indicator.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'register_step3_page.dart';

class RegisterStep2Page extends StatefulWidget {
  final String username;
  final String password;

  const RegisterStep2Page({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<RegisterStep2Page> createState() => _RegisterStep2PageState();
}

class _RegisterStep2PageState extends State<RegisterStep2Page> {
  static const _healthCoverageOptions = [
    'จ่ายเงินเอง',
    'บัตรประกันสุขภาพต่างด้าว',
    'ไม่มี/ไม่ทราบ',
  ];

  String? _gender;
  DateTime? _selectedDateOfBirth;
  String? _nationality;
  final _customNationalityController = TextEditingController();
  String? _healthCoverage;

  @override
  void dispose() {
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateOfBirth = picked);
  }

  void _next() {
    final l10n = AppLocalizations.of(context);

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.selectGender, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.selectBirthDate, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_nationality == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.nationalityRequired, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_nationality == 'อื่นๆ' && _customNationalityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.nationalityRequired, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_healthCoverage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.selectHealthCoverage, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final nationalityValue = _nationality == 'อื่นๆ'
        ? _customNationalityController.text.trim()
        : _nationality!;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RegisterStep3Page(
        username: widget.username,
        password: widget.password,
        gender: _gender,
        dateOfBirth: _selectedDateOfBirth,
        nationality: nationalityValue,
        healthCoverage: _healthCoverage!,
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
          buildRegisterStepIndicator(context, 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gender + Date of Birth row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildInputBox(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: Row(children: [
                              Icon(Icons.wc, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _gender,
                                  isExpanded: true,
                                  hint: Text(l10n.gender,
                                      style: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14)),
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'ชาย',
                                        child: Text(l10n.male, style: GoogleFonts.googleSans())),
                                    DropdownMenuItem(
                                        value: 'หญิง',
                                        child: Text(l10n.female, style: GoogleFonts.googleSans())),
                                  ],
                                  onChanged: (v) => setState(() => _gender = v),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                  prefixIcon: Icon(Icons.calendar_today,
                                      color: Colors.grey[400], size: 20),
                                  hintText: l10n.dateOfBirth,
                                  hintStyle: GoogleFonts.googleSans(
                                      color: Colors.grey[400], fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nationality dropdown
                  _buildInputBox(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: Row(children: [
                        Icon(Icons.language, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _nationality,
                            isExpanded: true,
                            hint: Text(l10n.nationality,
                                style: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14)),
                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                            items: [
                              DropdownMenuItem(
                                  value: 'ไทย',
                                  child: Text(l10n.nationalityThai, style: GoogleFonts.googleSans())),
                              DropdownMenuItem(
                                  value: 'ลาว',
                                  child: Text(l10n.nationalityLao, style: GoogleFonts.googleSans())),
                              DropdownMenuItem(
                                  value: 'พม่า',
                                  child: Text(l10n.nationalityMyanmar, style: GoogleFonts.googleSans())),
                              DropdownMenuItem(
                                  value: 'อื่นๆ',
                                  child: Text(l10n.nationalityOther, style: GoogleFonts.googleSans())),
                            ],
                            onChanged: (v) => setState(() => _nationality = v),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  if (_nationality == 'อื่นๆ') ...[
                    const SizedBox(height: 8),
                    _buildInputBox(
                      child: TextFormField(
                        controller: _customNationalityController,
                        style: GoogleFonts.googleSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: l10n.specifyNationality,
                          hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Health coverage dropdown
                  _buildInputBox(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: Row(children: [
                        Icon(Icons.local_hospital_outlined,
                            color: Colors.grey[400],
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _healthCoverage,
                            isExpanded: true,
                            hint: Text(l10n.healthCoverage,
                                style: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14)),
                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                            items: _healthCoverageOptions
                                .map((opt) => DropdownMenuItem(
                                    value: opt,
                                    child: Text(opt, style: GoogleFonts.googleSans())))
                                .toList(),
                            onChanged: (v) => setState(() => _healthCoverage = v),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      l10n.healthCoverageHelper,
                      style: GoogleFonts.googleSans(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GradientButton(onPressed: _next, label: l10n.next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: padding,
      child: child,
    );
  }
}
