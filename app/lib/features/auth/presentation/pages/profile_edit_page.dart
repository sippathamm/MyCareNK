import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/l10n/app_localizations.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  bool _loading = true;
  bool _saving = false;

  String _username = '';
  String _dateOfBirth = '';
  String? _gender;
  String _nationality = 'ไทย';
  String _customNationality = '';
  String? _healthCoverage;

  final _customNationalityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _customNationalityController.dispose();
    _phoneController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final data = await Supabase.instance.client
        .from('user_profiles')
        .select('username, gender, nationality, date_of_birth, health_coverage, phone_number, nickname')
        .eq('user_id', userId)
        .maybeSingle();
    if (!mounted) return;
    if (data != null) {
      final nat = data['nationality'] as String? ?? 'ไทย';
      final isStandard = ['ไทย', 'ลาว', 'พม่า'].contains(nat);
      setState(() {
        _username = data['username'] as String? ?? '';
        _gender = data['gender'] as String?;
        _nationality = isStandard ? nat : 'อื่นๆ';
        _customNationality = isStandard ? '' : nat;
        _dateOfBirth = data['date_of_birth'] as String? ?? '';
        _healthCoverage = data['health_coverage'] as String?;
        if (!isStandard) {
          _customNationalityController.text = _customNationality;
        }
        _phoneController.text = data['phone_number'] as String? ?? '';
        _nicknameController.text = data['nickname'] as String? ?? '';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_nationality == 'อื่นๆ' && _customNationalityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).nationalityRequired,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && (phone.length != 10 || !phone.startsWith('0'))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).phoneNumberInvalid,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final natValue = _nationality == 'อื่นๆ'
          ? _customNationalityController.text.trim()
          : _nationality;
      await Supabase.instance.client.from('user_profiles').update({
        'gender': _gender,
        'nationality': natValue,
        'health_coverage': _healthCoverage,
        'phone_number': phone.isEmpty ? null : phone,
        'nickname': _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      }).eq('user_id', userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).profileSaved,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).generalErrorRetry,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          l10n.profileTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: GradientButton(
                  onPressed: _saving ? null : _save,
                  label: AppLocalizations.of(context).confirm,
                  isLoading: _saving,
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyField(label: l10n.usernameLabel, value: _username, icon: Icons.person_outline),
                    const SizedBox(height: 20),
                    _buildReadOnlyField(label: l10n.dateOfBirth, value: _formatDateToBE(_dateOfBirth), icon: Icons.calendar_today),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    _buildGenderField(l10n),
                    const SizedBox(height: 20),
                    _buildNationalityField(l10n),
                    const SizedBox(height: 20),
                    _buildHealthCoverageField(l10n),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    _buildEditableTextField(
                      label: l10n.phoneNumberHint,
                      controller: _phoneController,
                      hint: l10n.phoneNumberHint,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildEditableTextField(
                      label: l10n.nicknameHint,
                      controller: _nicknameController,
                      hint: l10n.nicknameHint,
                      icon: Icons.badge_outlined,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDateToBE(String isoDate) {
    if (isoDate.isEmpty) return '';
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return isoDate;
    return '$day/$month/${year + 543}';
  }

  Widget _buildReadOnlyField({required String label, required String value, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.googleSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textMuted),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildGenderField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gender,
            style: GoogleFonts.googleSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: Row(children: [
              Icon(Icons.wc, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _gender,
                  isExpanded: true,
                  hint: Text(l10n.selectGender,
                      style: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14)),
                  style: GoogleFonts.googleSans(color: AppColors.textPrimary, fontSize: 15),
                  items: [
                    DropdownMenuItem(value: 'ชาย', child: Text(l10n.male)),
                    DropdownMenuItem(value: 'หญิง', child: Text(l10n.female)),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCoverageField(AppLocalizations l10n) {
    const options = ['จ่ายเงินเอง', 'บัตรประกันสุขภาพต่างด้าว', 'ไม่มี/ไม่ทราบ'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.healthCoverage,
            style: GoogleFonts.googleSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: Row(children: [
              Icon(Icons.local_hospital_outlined, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _healthCoverage,
                  isExpanded: true,
                  hint: Text(l10n.healthCoverage,
                      style: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14)),
                  style: GoogleFonts.googleSans(color: AppColors.textPrimary, fontSize: 15),
                  items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                  onChanged: (v) => setState(() => _healthCoverage = v),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.googleSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: GoogleFonts.googleSans(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildNationalityField(AppLocalizations l10n) {
    final labels = {
      'ไทย': l10n.nationalityThai,
      'ลาว': l10n.nationalityLao,
      'พม่า': l10n.nationalityMyanmar,
      'อื่นๆ': l10n.nationalityOther,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.nationality,
            style: GoogleFonts.googleSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: Row(children: [
              Icon(Icons.language, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _nationality,
                  isExpanded: true,
                  style: GoogleFonts.googleSans(color: AppColors.textPrimary, fontSize: 15),
                  items: ['ไทย', 'ลาว', 'พม่า', 'อื่นๆ'].map((nat) {
                    return DropdownMenuItem(value: nat, child: Text(labels[nat]!));
                  }).toList(),
                  onChanged: (v) => setState(() => _nationality = v!),
                ),
              ),
            ]),
          ),
        ),
        if (_nationality == 'อื่นๆ') ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _customNationalityController,
              style: GoogleFonts.googleSans(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.specifyNationality,
                hintStyle: GoogleFonts.googleSans(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
