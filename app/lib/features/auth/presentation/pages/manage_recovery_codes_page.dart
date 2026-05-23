import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/recovery_service.dart';
import '../widgets/recovery_codes_grid.dart';

class ManageRecoveryCodesPage extends StatefulWidget {
  const ManageRecoveryCodesPage({super.key});

  @override
  State<ManageRecoveryCodesPage> createState() => _ManageRecoveryCodesPageState();
}

class _ManageRecoveryCodesPageState extends State<ManageRecoveryCodesPage> {
  bool _isGenerating = false;
  List<String>? _newCodes;

  Future<void> _regenerate() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.recoveryCodesManageTitle,
          style: GoogleFonts.googleSans(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.recoveryCodesRegenerateConfirm,
          style: GoogleFonts.googleSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: GoogleFonts.googleSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm,
                style: GoogleFonts.googleSans(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isGenerating = true);
    try {
      final codes = RecoveryService.generateRecoveryCodes();
      await RecoveryService().saveRecoveryCodes(codes);
      if (!mounted) return;
      setState(() => _newCodes = codes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).recoveryCodesRegenerateSuccess,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).generalErrorRetry,
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
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
          l10n.recoveryCodesManageTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: _newCodes != null ? _buildNewCodes(l10n) : _buildInitial(l10n),
        ),
      ),
    );
  }

  Widget _buildInitial(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.recoveryCodesCannotRetrieve,
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          onPressed: _isGenerating ? null : _regenerate,
          label: l10n.recoveryCodesRegenerateBtn,
          isLoading: _isGenerating,
        ),
      ],
    );
  }

  Widget _buildNewCodes(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.statusCompletedLight,
            border: Border.all(color: AppColors.statusCompleted, width: 3),
          ),
          child: const Icon(Icons.check, color: AppColors.statusCompleted, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.recoveryCodesRegenerateSuccess,
          style: GoogleFonts.googleSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.newCodesCreated,
          style: GoogleFonts.googleSans(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadowMedium,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.recoveryCodesManageTitle,
                        style: GoogleFonts.googleSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RecoveryCodesGrid(
                    recoveryCodes: _newCodes!,
                    footerText: l10n.newCodesHint,
                    showCopyButton: false,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.statusCompleted,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _newCodes!.join(', ')));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context).allCopied,
                    style: GoogleFonts.googleSans()),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: Text(
              l10n.copyAll,
              style: GoogleFonts.googleSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
