import 'package:flutter/material.dart';

class ShortcutMenu extends StatelessWidget {
  const ShortcutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildShortcutItem(
          context: context,
          icon: Icons.location_on,
          label: 'จุดบริการ',
        ),
        const SizedBox(width: 16),
        _buildShortcutItem(
          context: context,
          icon: Icons.menu_book,
          label: 'คู่มือการใช้',
        ),
        const SizedBox(width: 16),
        _buildShortcutItem(
          context: context,
          icon: Icons.receipt_long,
          label: 'ประวัติการขอ',
        ),
      ],
    );
  }

  Widget _buildShortcutItem({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('"$label" ถูกกด')));
              },
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFFFF8A50), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
