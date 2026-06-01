import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/models/condom_request_model.dart';

/// Single source of truth for the colors and icon that represent a
/// [RequestStatus]. [color] is used for the status chip background and the
/// status icon; [lightBg] tints the icon circle.
class RequestStatusVisuals {
  final Color color;
  final Color lightBg;
  final IconData icon;

  const RequestStatusVisuals({
    required this.color,
    required this.lightBg,
    required this.icon,
  });

  factory RequestStatusVisuals.of(RequestStatus status) {
    if (status.isCancelled) {
      return RequestStatusVisuals(
        color: Colors.grey.shade600,
        lightBg: Colors.grey.shade200,
        icon: Icons.cancel_outlined,
      );
    }
    switch (status) {
      case RequestStatus.preparing:
        return const RequestStatusVisuals(
          color: AppColors.statusPreparing,
          lightBg: AppColors.statusPreparingLight,
          icon: Icons.inventory_2_outlined,
        );
      case RequestStatus.ready:
        return const RequestStatusVisuals(
          color: AppColors.statusReady,
          lightBg: AppColors.statusReadyLight,
          icon: Icons.local_shipping_outlined,
        );
      case RequestStatus.completed:
        return const RequestStatusVisuals(
          color: AppColors.statusCompleted,
          lightBg: AppColors.statusCompletedLight,
          icon: Icons.check_circle_outline,
        );
      case RequestStatus.pending:
      default:
        return const RequestStatusVisuals(
          color: AppColors.primary,
          lightBg: AppColors.statusPendingLight,
          icon: Icons.assignment_outlined,
        );
    }
  }
}
