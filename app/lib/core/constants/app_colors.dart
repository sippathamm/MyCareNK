import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette
  static const Color primary = Color(0xFFFF8A50);
  static const Color primaryLight = Color(0xFFFFB58A);
  static const Color primaryShadow = Color(0x29FF8A50); // ~16% opacity
  static const Color primaryCardShadow = Color(0x1AFF8A50); // ~10% opacity
  static const Color primaryButtonShadow = Color(0x66FF8A50); // ~40% opacity

  // Background / surface
  static const Color primaryBackground = Color(0xFFFFF7E6);
  static const Color primaryCardStart = Color(0xFFFEF1D2);
  static const Color primaryCardEnd = Color(0xFFFBCFB8);
  static const Color primaryCodeBox = Color(0xFFFFF3E0);
  static const Color primaryCodeBorder = Color(0xFFFFCC80);

  // Lubricant / blue
  static const Color lubricant = Color(0xFF4A9FE8);
  static const Color lubricantCardStart = Color(0xFFC0DEFB);
  static const Color lubricantCardEnd = Color(0xFF86C0FA);
  static const Color lubricantShadow = Color(0x1A4A9FE8); // ~10% opacity

  // Error / red
  static const Color error = Color(0xFFFF4D4D);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color errorShadow = Color(0x4DB71C1C); // ~30% opacity

  // Success / green
  static const Color success = Color(0xFF5DB036);

  // Request status colors
  static const Color statusPendingLight = Color(0xFFFBE9E7);
  static const Color statusPreparing = Color(0xFF1F77C3);
  static const Color statusPreparingLight = Color(0xFFE3F2FD);
  static const Color statusReady = Color(0xFF9C27B0);
  static const Color statusReadyLight = Color(0xFFF3E5F5);
  static const Color statusCompleted = Color(0xFF26A69A);
  static const Color statusCompletedLight = Color(0xFFE0F2F1);

  // Text
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF777777);
  static const Color textHint = Color(0xFF999999);
  static const Color textBlack87 = Color(0xDD000000);

  // Avatar / profile
  static const Color avatarBackground = Color(0xFFEFE5FD);
  static const Color avatarCircle = Color(0xFFD1C4E9);
  static const Color avatarIcon = Color(0xFF7C4DFF);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0D000000); // ~5% black
  static const Color cardShadowMedium = Color(0x14000000); // ~8% black
  static const Color overlayDark = Color(0x80000000); // ~50% black
}
