import 'package:flutter/material.dart';

/// Thin animated bar showing [current]/[total] as a filled fraction.
/// Pass a changing [key] (e.g. an animation version) to replay the fill.
class QuotaProgressBar extends StatelessWidget {
  final Color color;
  final int current;
  final int total;

  const QuotaProgressBar({
    super.key,
    required this.color,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = total > 0 ? (current / total).clamp(0.0, 1.0) : 0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: pct),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Stack(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 6,
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
