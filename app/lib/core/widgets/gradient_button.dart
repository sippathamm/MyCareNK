import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final List<Color> gradientColors;
  final double height;
  final double borderRadius;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.gradientColors = const [AppColors.primaryDark, AppColors.primary],
    this.height = 52,
    this.borderRadius = 24,
    this.fontSize = 16,
  });

  static const List<Color> errorGradient = [AppColors.errorDark, AppColors.error];
  static const List<Color> lubricantGradient = [AppColors.lubricantDark, AppColors.lubricant];
  static const List<Color> completedGradient = [AppColors.success, AppColors.statusCompleted];
  static const List<Color> healthGradient = [Color(0xFF5E35B1), AppColors.avatarIcon];

  @override
  Widget build(BuildContext context) {
    final bool active = onPressed != null && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active ? gradientColors : [Colors.grey.shade400, Colors.grey.shade400],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: active ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.25),
            highlightColor: Colors.transparent,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.googleSans(
                        color: AppColors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
