import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'my_posts_screen.dart';
import 'my_reels_screen.dart';
import 'saved_posts_screen.dart';

/// Leader Dashboard
///
/// UX contract (non-negotiable):
/// - Single create entry point: ONE FAB only
/// - Header: identity only (no CTAs)
/// - Impact cards: fully tappable
/// - Leader tools: strict list (no create actions)
class LeaderDashboardScreen extends StatefulWidget {
  const LeaderDashboardScreen({super.key});

  @override
  State<LeaderDashboardScreen> createState() => _LeaderDashboardScreenState();
}

class _LeaderDashboardScreenState extends State<LeaderDashboardScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;

  int _postsCount = 0;
  int _reelsCount = 0;
  int _followersCount = 0;
  int _reachCount = 0;

  List<UserModel> _recentFollowers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final current = _authService.currentUser;
      if (current == null) {
        if (!mounted) return;
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
        return;
      }

      final user = await _authService.getUserById(current.uid);
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
        return;
      }

      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.id)
          .get();

      final reelsSnapshot = await _firestore
          .collection('reels')
          .where('userId', isEqualTo: user.id)
          .get();

      // Best-effort reach: sum likes + comments + views if present.
      var reach = 0;
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        final likes = (data['likes'] as List?)?.length ?? 0;
        final comments =
            (data['commentsCount'] as num?)?.toInt() ??
            (data['comments'] as List?)?.length ??
            0;
        final views = (data['views'] as num?)?.toInt() ?? 0;
        reach += likes + comments + views;
      }
      for (final doc in reelsSnapshot.docs) {
        final data = doc.data();
        final likes = (data['likes'] as List?)?.length ?? 0;
        final views = (data['views'] as num?)?.toInt() ?? 0;
        reach += likes + views;
      }

      // Recent followers preview.
      final followerIds = user.followers;
      final List<UserModel> recentFollowers = [];
      if (followerIds.isNotEmpty) {
        final ids = followerIds.reversed.take(8).toList();
        for (final id in ids) {
          final doc = await _firestore.collection('users').doc(id).get();
          if (doc.exists) {
            recentFollowers.add(UserModel.fromFirestore(doc));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _postsCount = postsSnapshot.docs.length;
        _reelsCount = reelsSnapshot.docs.length;
        _followersCount = user.followers.length;
        _reachCount = reach;
        _recentFollowers = recentFollowers;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Non-leader safety fallback.
    if (_currentUser != null &&
        _currentUser!.role != UserRole.religiousLeader) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Leader Dashboard'),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'This area is for leaders only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Follower and content tools are only available to religious leaders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: LeaderDashboardHeader(user: _currentUser),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ImpactGrid(
                    followersCount: _followersCount,
                    postsCount: _postsCount,
                    reelsCount: _reelsCount,
                    reachCount: _reachCount,
                    onOpenFollowers: _showFollowersList,
                    onOpenMyPosts: _goMyPosts,
                    onOpenMyReels: _goMyReels,
                    onOpenInsights: _goInsights,
                  ),
                  const SizedBox(height: 18),
                  LeaderToolsList(
                    followersCount: _followersCount,
                    onViewMyPosts: _goMyPosts,
                    onViewMyReels: _goMyReels,
                    onViewFollowers: _showFollowersList,
                    onSavedPosts: _goSavedPosts,
                    onEditProfile: _goEditProfile,
                  ),
                  const SizedBox(height: 18),
                  _FollowersPreview(
                    followersCount: _followersCount,
                    recentFollowers: _recentFollowers,
                    onViewAll: _showFollowersList,
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goMyPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyPostsScreen()),
    );
  }

  void _goMyReels() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyReelsScreen()),
    );
  }

  void _goInsights() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaderInsightsScreen(reach: _reachCount),
      ),
    );
  }

  void _goSavedPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
    );
  }

  void _goEditProfile() {
    final user = _currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: user, onSave: _loadData),
      ),
    ).then((_) => _loadData());
  }

  void _showFollowersList() {
    final user = _currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Followers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: user.followers.isNotEmpty
                    ? StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where(
                              FieldPath.documentId,
                              whereIn: user.followers,
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final followers = snapshot.data!.docs;

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: followers.length,
                            itemBuilder: (context, index) {
                              final follower =
                                  followers[index].data()
                                      as Map<String, dynamic>;
                              final photoUrl =
                                  (follower['profilePhotoUrl'] as String?)
                                      ?.trim();
                              final name =
                                  (follower['name'] as String?)?.trim() ??
                                  'Follower';
                              final email =
                                  (follower['email'] as String?)?.trim() ?? '';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      photoUrl != null && photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: (photoUrl == null || photoUrl.isEmpty)
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'F',
                                        )
                                      : null,
                                ),
                                title: Text(name),
                                subtitle: email.isEmpty ? null : Text(email),
                              );
                            },
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No followers yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Refactored building blocks
// ---------------------------------------------------------------------------

class LeaderDashboardHeader extends StatelessWidget {
  const LeaderDashboardHeader({super.key, required this.user});

  final UserModel? user;

  static const _brand = Color(0xFF6366F1);
  static const _brand2 = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final name = (user?.name ?? 'Leader').trim();
    final faith = (user?.faith.toString().split('.').last ?? '').trim();
    final faithLabel = faith.isEmpty
        ? ''
        : faith[0].toUpperCase() + faith.substring(1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brand, _brand2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Row(
            children: [
              _Avatar(user: user, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _LeaderBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (faithLabel.isNotEmpty) _FaithPill(faithLabel),
                    const SizedBox(height: 10),
                    Text(
                      'Lead with calm clarity — your community is listening.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final UserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = (user?.profilePhotoUrl ?? '').trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty
            ? Text(
                (user?.name ?? 'L').isNotEmpty
                    ? (user!.name[0]).toUpperCase()
                    : 'L',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _LeaderBadge extends StatelessWidget {
  const _LeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'Leader',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaithPill extends StatelessWidget {
  const _FaithPill(this.faithLabel);

  final String faithLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            faithLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ImpactGrid extends StatelessWidget {
  const ImpactGrid({
    super.key,
    required this.followersCount,
    required this.postsCount,
    required this.reelsCount,
    required this.reachCount,
    required this.onOpenFollowers,
    required this.onOpenMyPosts,
    required this.onOpenMyReels,
    required this.onOpenInsights,
  });

  final int followersCount;
  final int postsCount;
  final int reelsCount;
  final int reachCount;

  final VoidCallback onOpenFollowers;
  final VoidCallback onOpenMyPosts;
  final VoidCallback onOpenMyReels;
  final VoidCallback onOpenInsights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Your Impact',
          subtitle: 'A quick view of what your leadership is touching.',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ImpactTile(
                  icon: Icons.people_alt_rounded,
                  value: followersCount,
                  label: 'Followers',
                  accent: const Color(0xFFEC4899),
                  onTap: onOpenFollowers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactTile(
                  icon: Icons.article_rounded,
                  value: postsCount,
                  label: 'Posts',
                  accent: const Color(0xFF3B82F6),
                  onTap: onOpenMyPosts,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ImpactTile(
                  icon: Icons.video_library_rounded,
                  value: reelsCount,
                  label: 'Reels',
                  accent: const Color(0xFF8B5CF6),
                  onTap: onOpenMyReels,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactTile(
                  icon: Icons.insights_rounded,
                  value: reachCount,
                  label: 'Reach',
                  accent: const Color(0xFF10B981),
                  onTap: onOpenInsights,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String formatCompactNumber(int value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[300], size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ImpactGrid.formatCompactNumber(value),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.2,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderToolsList extends StatelessWidget {
  const LeaderToolsList({
    super.key,
    required this.followersCount,
    required this.onViewMyPosts,
    required this.onViewMyReels,
    required this.onViewFollowers,
    required this.onSavedPosts,
    required this.onEditProfile,
  });

  final int followersCount;
  final VoidCallback onViewMyPosts;
  final VoidCallback onViewMyReels;
  final VoidCallback onViewFollowers;
  final VoidCallback onSavedPosts;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Leader Tools',
          subtitle: 'Quick access to your content and community.',
        ),
        const SizedBox(height: 12),
        _PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ToolRow(
                title: 'View My Posts',
                subtitle: 'Review what you’ve shared',
                icon: Icons.article_outlined,
                accent: const Color(0xFF3B82F6),
                onTap: onViewMyPosts,
              ),
              const Divider(height: 1),
              _ToolRow(
                title: 'View My Reels',
                subtitle: 'Your short-form inspiration',
                icon: Icons.video_library_outlined,
                accent: const Color(0xFF8B5CF6),
                onTap: onViewMyReels,
              ),
              const Divider(height: 1),
              _ToolRow(
                title: 'View Followers',
                subtitle: followersCount == 1
                    ? '1 follower'
                    : '$followersCount followers',
                icon: Icons.people_alt_outlined,
                accent: const Color(0xFFEC4899),
                onTap: onViewFollowers,
              ),
              const Divider(height: 1),
              _ToolRow(
                title: 'Saved Posts',
                subtitle: 'Revisit what you’ve saved',
                icon: Icons.bookmark_outline,
                accent: const Color(0xFFF59E0B),
                onTap: onSavedPosts,
              ),
              const Divider(height: 1),
              _ToolRow(
                title: 'Edit Profile',
                subtitle: 'Update your presence',
                icon: Icons.manage_accounts_outlined,
                accent: const Color(0xFF10B981),
                onTap: onEditProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class CreateContentFAB extends StatelessWidget {
  const CreateContentFAB({
    super.key,
    required this.onCreatePost,
    required this.onUploadReel,
  });

  final VoidCallback onCreatePost;
  final VoidCallback onUploadReel;

  static const _bg = Color(0xFFF9FAFB);
  static const _brand = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'leaderDashboardCreateFab',
      backgroundColor: _brand,
      foregroundColor: Colors.white,
      elevation: 6,
      onPressed: () => _showCreateSheet(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Create',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Create',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _CreateSheetAction(
                    icon: Icons.edit_note,
                    title: 'Create Post',
                    subtitle: 'Share guidance with a caption',
                    accent: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      onCreatePost();
                    },
                  ),
                  const SizedBox(height: 10),
                  _CreateSheetAction(
                    icon: Icons.video_call,
                    title: 'Upload Reel',
                    subtitle: 'Short video inspiration',
                    accent: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      onUploadReel();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateSheetAction extends StatelessWidget {
  const _CreateSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CreateContentFAB._bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.2,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FollowersPreview extends StatelessWidget {
  const _FollowersPreview({
    required this.followersCount,
    required this.recentFollowers,
    required this.onViewAll,
  });

  final int followersCount;
  final List<UserModel> recentFollowers;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Recent followers — people choosing to learn from you.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.2,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (followersCount == 0)
          _PremiumCard(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Your community will grow',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share consistently to invite people into your guidance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          _PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        size: 20,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        followersCount == 1
                            ? '1 person following your guidance'
                            : '$followersCount people following your guidance',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentFollowers.isEmpty
                        ? 1
                        : recentFollowers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (recentFollowers.isEmpty) {
                        return _FollowerChip(
                          name: 'View followers',
                          photoUrl: null,
                          onTap: onViewAll,
                        );
                      }
                      final f = recentFollowers[index];
                      return _FollowerChip(
                        name: (f.name).trim().isEmpty ? 'Follower' : f.name,
                        photoUrl: f.profilePhotoUrl,
                        onTap: onViewAll,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FollowerChip extends StatelessWidget {
  const _FollowerChip({
    required this.name,
    required this.photoUrl,
    required this.onTap,
  });

  final String name;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = (photoUrl ?? '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
              backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
              child: url.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'F',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal placeholder used by the "Reach" impact card.
/// This keeps the dashboard fully interactive without adding features.
class LeaderInsightsScreen extends StatelessWidget {
  const LeaderInsightsScreen({super.key, required this.reach});

  final int reach;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total engagement signals (likes, comments, views): $reach',
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a basic analytics page so the dashboard stays fully clickable and predictable.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
