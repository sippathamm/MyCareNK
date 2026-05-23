import 'package:flutter/material.dart';
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

  final _customNationalityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _customNationalityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final data = await Supabase.instance.client
        .from('user_profiles')
        .select('username, gender, nationality, date_of_birth')
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
        if (!isStandard) {
          _customNationalityController.text = _customNationality;
        }
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
    setState(() => _saving = true);
    try {
      final natValue = _nationality == 'อื่นๆ'
          ? _customNationalityController.text.trim()
          : _nationality;
      await Supabase.instance.client.from('user_profiles').update({
        'gender': _gender,
        'nationality': natValue,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyField(label: l10n.usernameLabel, value: _username),
                    const SizedBox(height: 20),
                    _buildReadOnlyField(label: l10n.dateOfBirth, value: _dateOfBirth),
                    const SizedBox(height: 24),
                    _buildGenderField(l10n),
                    const SizedBox(height: 24),
                    _buildNationalityField(l10n),
                    const SizedBox(height: 32),
                    GradientButton(
                      onPressed: _saving ? null : _save,
                      label: AppLocalizations.of(context).confirm,
                      isLoading: _saving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
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
          child: Text(
            value.isEmpty ? '—' : value,
            style: GoogleFonts.googleSans(fontSize: 15, color: AppColors.textMuted),
          ),
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
