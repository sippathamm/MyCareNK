import 'package:flutter/material.dart';
import '../widgets/service_card.dart';
import 'condom_request_page.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            ServiceCard(
              icon: Icons.location_on,
              title: 'รับถุงยางอนามัย',
              subtitle: 'ค้นหาจุดบริการและรับถุงยางอนามัยฟรี',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CondomRequestPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ServiceCard(
              icon: Icons.assignment,
              title: 'ประเมินความเสี่ยง HIV',
              subtitle: 'ทำแบบทดสอบเพื่อประเมินความเสี่ยงติดเชื้อ HIV',
              onTap: () {
                // TODO: Navigate to HIV Assessment
              },
            ),
          ],
        ),
      ),
    );
  }
}
