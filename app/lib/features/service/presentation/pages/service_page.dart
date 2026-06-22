import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../widgets/service_card.dart';
import 'condom_request_page.dart';
import '../../../health/presentation/pages/hiv_assessment_page.dart';
import '../../../health/presentation/pages/consultation_booking_page.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: Text(
          l10n.servicePageTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            ServiceCard(
              icon: Icons.inventory_2_outlined,
              iconBgColor: AppColors.primaryBackground,
              iconColor: AppColors.primaryDark,
              title: l10n.getCondomsTitle,
              subtitle: l10n.getCondomsSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CondomRequestPage()),
              ),
            ),
            ServiceCard(
              icon: Icons.favorite_outline,
              iconBgColor: AppColors.avatarBackground,
              iconColor: AppColors.avatarIcon,
              title: l10n.assessHIVTitle,
              subtitle: l10n.assessHIVSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HivAssessmentPage()),
              ),
            ),
            ServiceCard(
              icon: Icons.calendar_month_outlined,
              iconBgColor: AppColors.statusPreparingLight,
              iconColor: AppColors.lubricant,
              title: l10n.bookDoctorTitle,
              subtitle: l10n.bookDoctorSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConsultationBookingPage()),
              ),
            ),
            ServiceCard(
              icon: Icons.health_and_safety_outlined,
              iconBgColor: AppColors.statusCompletedLight,
              iconColor: AppColors.statusCompleted,
              title: l10n.healthTrackerTitle,
              subtitle: l10n.healthTrackerSubtitle,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.comingSoon,
                      style: GoogleFonts.googleSans()),
                  backgroundColor: AppColors.textSecondary,
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
