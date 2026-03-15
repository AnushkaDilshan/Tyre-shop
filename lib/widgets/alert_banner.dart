import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}