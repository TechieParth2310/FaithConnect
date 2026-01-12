import 'package:flutter/material.dart';
import '../utils/gradient_theme.dart';

/// Role-specific premium profile headers.
///
/// NON-NEGOTIABLE RULES:
/// - Leader UI != Worshipper UI (separate widgets)
/// - Exactly ONE primary stat card
/// - Stat value must be RIGHT-aligned (Row + spaceBetween)

class WorshipperProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String name;

  /// e.g. "Christianity" / "Islam" etc
  final String faithLabel;

  /// Number of leaders followed.
  final int followingCount;

  /// Optional navigation to the list of followed leaders.
  final VoidCallback? onFollowingTap;

  const WorshipperProfileHeader({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.faithLabel,
    required this.followingCount,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: _containerDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(photoUrl: photoUrl),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.1,
                  ) ??
                  const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                const _Pill(icon: Icons.verified_user, label: 'Worshipper'),
                _Pill(icon: Icons.auto_awesome, label: faithLabel),
              ],
            ),
            const SizedBox(height: 14),
            _PrimaryStatCard(
              label: 'Following',
              value: followingCount,
              onTap: onFollowingTap,
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String name;

  /// e.g. "CHRISTIANITY" / "ISLAM" etc
  final String faithLabel;

  /// Number of worshippers following.
  final int followersCount;

  /// Optional navigation to followers list.
  final VoidCallback? onFollowersTap;

  /// Optional leader-only secondary stats.
  final int? postsCount;
  final int? reelsCount;

  const LeaderProfileHeader({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.faithLabel,
    required this.followersCount,
    this.onFollowersTap,
    this.postsCount,
    this.reelsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: _containerDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(photoUrl: photoUrl),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.1,
                  ) ??
                  const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                const _Pill(icon: Icons.verified_user, label: 'Leader'),
                _Pill(icon: Icons.auto_awesome, label: faithLabel),
              ],
            ),
            const SizedBox(height: 14),
            _PrimaryStatCard(
              label: 'Followers',
              value: followersCount,
              onTap: onFollowersTap,
            ),
            if (postsCount != null || reelsCount != null) ...[
              const SizedBox(height: 12),
              _SecondaryStatsRow(
                postsCount: postsCount,
                reelsCount: reelsCount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _containerDecoration = GradientTheme.cardDecoration(
  borderRadius: 20,
  backgroundColor: Colors.white,
);

class _Avatar extends StatelessWidget {
  final String? photoUrl;

  const _Avatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final url = (photoUrl ?? '').trim();
    return CircleAvatar(
      radius: 44,
      backgroundColor: const Color(0xFFF1F5F9),
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? const Icon(Icons.person, color: Color(0xFF475569), size: 42)
          : null,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GradientTheme.textDark),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: GradientTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStatCard extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _PrimaryStatCard({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      // REQUIRED: label on the left, number on the RIGHT.
      // Do NOT center. Do NOT stack under.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString(),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: content,
    );
  }
}

class _SecondaryStatsRow extends StatelessWidget {
  final int? postsCount;
  final int? reelsCount;

  const _SecondaryStatsRow({
    required this.postsCount,
    required this.reelsCount,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (postsCount != null) {
      chips.add(_MiniStatChip(label: 'Posts', value: postsCount!));
    }
    if (reelsCount != null) {
      chips.add(_MiniStatChip(label: 'Reels', value: reelsCount!));
    }

    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          Expanded(child: chips[i]),
          if (i != chips.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value.toString(),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
