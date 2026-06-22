import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Single source of truth for the colors and icon that represent a doctor
/// appointment status string ('pending' | 'confirmed' | 'completed' |
/// 'cancelled_by_user' | 'cancelled_by_staff'). [color] backs both the status
/// badge and the icon; [lightBg] tints the icon circle.
class ConsultationStatusVisuals {
  final Color color;
  final Color lightBg;
  final IconData icon;

  const ConsultationStatusVisuals({
    required this.color,
    required this.lightBg,
    required this.icon,
  });

  factory ConsultationStatusVisuals.of(String status) {
    switch (status) {
      case 'pending':
        return const ConsultationStatusVisuals(
          color: AppColors.primary,
          lightBg: AppColors.statusPendingLight,
          icon: Icons.schedule_outlined,
        );
      case 'confirmed':
        return const ConsultationStatusVisuals(
          color: AppColors.statusReady,
          lightBg: AppColors.statusReadyLight,
          icon: Icons.event_available_outlined,
        );
      case 'completed':
        return const ConsultationStatusVisuals(
          color: AppColors.statusCompleted,
          lightBg: AppColors.statusCompletedLight,
          icon: Icons.check_circle_outline,
        );
      default: // cancelled_by_user / cancelled_by_staff
        return ConsultationStatusVisuals(
          color: Colors.grey.shade600,
          lightBg: Colors.grey.shade200,
          icon: Icons.cancel_outlined,
        );
    }
  }
}
