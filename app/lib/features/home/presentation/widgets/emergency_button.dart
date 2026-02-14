import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: const Color(0xFFB71C1C).withOpacity(0.3),
      child: Ink(
        width: 140,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF4D4D), // Red
              Color(0xFFB71C1C), // Dark Red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () async {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('"1669" ถูกกด')));
            final Uri launchUri = Uri(scheme: 'tel', path: '1669');
            if (await canLaunchUrl(launchUri)) {
              await launchUrl(launchUri);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk, color: Colors.white, size: 24),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '1669',
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'เจ็บป่วยฉุกเฉิน',
                      style: GoogleFonts.prompt(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
