import 'package:flutter/material.dart';

class ExploreQuickActions extends StatelessWidget {
  final VoidCallback? onPrayer;
  final VoidCallback? onWisdom;
  final VoidCallback? onChant;
  final VoidCallback? onNearby;

  const ExploreQuickActions({
    super.key,
    this.onPrayer,
    this.onWisdom,
    this.onChant,
    this.onNearby,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 8),
      child: SizedBox(
        height: 62,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _ActionPill(
              icon: Icons.self_improvement,
              tooltip: 'Prayer',
              onTap: onPrayer,
            ),
            const SizedBox(width: 10),
            _ActionPill(
              icon: Icons.menu_book,
              tooltip: 'Wisdom',
              onTap: onWisdom,
            ),
            const SizedBox(width: 10),
            _ActionPill(
              icon: Icons.graphic_eq,
              tooltip: 'Chant',
              onTap: onChant,
            ),
            const SizedBox(width: 10),
            _ActionPill(
              icon: Icons.place_outlined,
              tooltip: 'Nearby',
              onTap: onNearby,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionPill({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF8FAFC);
    final border = const Color(0xFFE5E7EB);
    final fg = const Color(0xFF1F2937);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: fg, size: 24),
          ),
        ),
      ),
    );
  }
}
