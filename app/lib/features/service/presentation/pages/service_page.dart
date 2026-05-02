import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/service_card.dart';
import 'condom_request_page.dart';
import 'request_history_page.dart';
import '../../../health/presentation/pages/hiv_assessment_page.dart';
import '../../../health/presentation/pages/doctor_booking_page.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: const Text(
          'บริการ',
          style: TextStyle(
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
              iconBgColor: AppColors.primary,
              title: 'รับถุงยางอนามัย',
              subtitle: 'ค้นหาสถานบริการและรับถุงยางอนามัยฟรี',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CondomRequestPage()),
              ),
            ),
            ServiceCard(
              icon: Icons.favorite_outline,
              iconBgColor: const Color(0xFF7C4DFF),
              title: 'ประเมินความเสี่ยงการติดเชื้อ HIV',
              subtitle: 'ทำแบบทดสอบเพื่อประเมินความเสี่ยงการติดเชื้อ HIV',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HivAssessmentPage()),
              ),
            ),
            ServiceCard(
              icon: Icons.calendar_month_outlined,
              iconBgColor: AppColors.lubricant,
              title: 'นัดพบแพทย์',
              subtitle: 'จองคิวล่วงหน้าเพื่อรับยา PrEP/PEP ตรวจเลือด หรือปรึกษาสุขภาพ',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorBookingPage()),
              ),
            ),
            ServiceCard(
              icon: Icons.receipt_long_outlined,
              iconBgColor: AppColors.statusCompleted,
              title: 'ประวัติคำขอ',
              subtitle: 'ดูสถานะและรายละเอียดคำขอรับถุงยางอนามัยทั้งหมด',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestHistoryPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
