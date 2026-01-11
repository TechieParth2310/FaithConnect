import 'package:flutter/material.dart';

class QuickActionStrip extends StatelessWidget {
  final VoidCallback? onPrayer;
  final VoidCallback? onWisdom;
  final VoidCallback? onChant;
  final VoidCallback? onNearby;

  const QuickActionStrip({
    super.key,
    this.onPrayer,
    this.onWisdom,
    this.onChant,
    this.onNearby,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(
        icon: Icons.volunteer_activism_rounded,
        tooltip: 'Prayer',
        onTap: onPrayer,
      ),
      _ActionItem(
        icon: Icons.menu_book_rounded,
        tooltip: 'Wisdom',
        onTap: onWisdom,
      ),
      _ActionItem(
        icon: Icons.graphic_eq_rounded,
        tooltip: 'Chant',
        onTap: onChant,
      ),
      _ActionItem(
        icon: Icons.location_on_rounded,
        tooltip: 'Nearby',
        onTap: onNearby,
      ),
    ];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionItem({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: isEnabled
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF9CA3AF),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
