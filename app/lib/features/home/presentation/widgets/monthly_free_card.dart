import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyFreeCard extends StatelessWidget {
  const MonthlyFreeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF8E1), // Cream
            Color(0xFFFFE0B2), // Light Orange
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สิทธิ์รับฟรีเดือนนี้',
            style: GoogleFonts.prompt(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '15 ',
                  style: GoogleFonts.prompt(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF8A50),
                  ),
                ),
                TextSpan(
                  text: 'ชิ้น',
                  style: GoogleFonts.prompt(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF8A50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Custom Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                width: 150, // Fixed width as per design reference often seen
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: 100, // 70% of 150 approx
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
