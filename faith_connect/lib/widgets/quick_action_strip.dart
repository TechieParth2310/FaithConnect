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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _ActionItem(
              icon: Icons.volunteer_activism_rounded,
              tooltip: 'Prayer',
              onTap: onPrayer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionItem(
              icon: Icons.menu_book_rounded,
              tooltip: 'Wisdom',
              onTap: onWisdom,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionItem(
              icon: Icons.graphic_eq_rounded,
              tooltip: 'Chant',
              onTap: onChant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionItem(
              icon: Icons.location_on_rounded,
              tooltip: 'Nearby',
              onTap: onNearby,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [
                      Color(0xFFE8E4FF),
                      Color(0xFFF3F1FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isEnabled ? null : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF8B7CF0).withOpacity(0.3)
                  : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B7CF0).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: isEnabled
                  ? const Color(0xFF7B6FE8)
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
