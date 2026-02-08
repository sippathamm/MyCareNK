import 'package:flutter/material.dart';

class ShortcutMenu extends StatelessWidget {
  const ShortcutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildShortcutItem(
          context: context,
          icon: Icons.location_on,
          label: 'จุดบริการ',
        ),
        _buildShortcutItem(
          context: context,
          icon: Icons.menu_book,
          label: 'คู่มือการใช้',
        ),
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
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"$label" ถูกกด')));
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFF2E8,
              ), // Light orange background matching card/mockup
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFFFF8A50), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
