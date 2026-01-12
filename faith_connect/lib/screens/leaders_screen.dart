import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../utils/gradient_theme.dart';
import '../widgets/follow_button.dart';
import '../widgets/notification_bell.dart';
import 'leader_profile_screen.dart';

class _FaithFilter {
  final String label;
  final FaithType? faith;
  const _FaithFilter(this.label, this.faith);
}

class LeadersScreen extends StatefulWidget {
  const LeadersScreen({super.key});

  @override
  State<LeadersScreen> createState() => _LeadersScreenState();
}

class _LeadersScreenState extends State<LeadersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentUserId;
  final TextEditingController _searchController = TextEditingController();
  FaithType? _selectedFaith;

  // Calm, intentional filter ordering.
  static const List<_FaithFilter> _faithFilters = <_FaithFilter>[
    _FaithFilter('All', null),
    _FaithFilter('Christianity', FaithType.christianity),
    _FaithFilter('Islam', FaithType.islam),
    _FaithFilter('Judaism', FaithType.judaism),
    _FaithFilter('Hinduism', FaithType.hinduism),
    _FaithFilter('Other', FaithType.other),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUser();
  }

  void _initializeUser() {
    final user = AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GradientTheme.softBackground,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: GradientTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Religious Leaders',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Discover spiritual guides you resonate with',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBell(iconColor: Colors.white),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          overlayColor: WidgetStateProperty.all(
            Colors.black.withValues(alpha: 0.04),
          ),
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'My Leaders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExploreTab(), _buildFollowingTab()],
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            children: [
              // Search Bar (rounded + soft shadow)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search leaders by name or faith',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 10),

              // Faith Filter Chips (rounded, soft colors, slight animation)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _faithFilters.map((f) {
                    final selected = _selectedFaith == f.faith;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        scale: selected ? 1.03 : 1.0,
                        child: ChoiceChip(
                          label: Text(
                            f.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedFaith = f.faith;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFFEEF2FF),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFE5E7EB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Leaders Grid
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: _fetchLeaders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<UserModel> leaders = snapshot.data ?? [];

              // Filter by search
              if (_searchController.text.isNotEmpty) {
                leaders = leaders
                    .where(
                      (leader) => leader.name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ),
                    )
                    .toList();
              }

              // Filter by faith
              if (_selectedFaith != null) {
                leaders = leaders
                    .where((leader) => leader.faith == _selectedFaith)
                    .toList();
              }

              // Filter only religious leaders
              leaders = leaders
                  .where(
                    (leader) =>
                        leader.role == UserRole.religiousLeader &&
                        leader.id != _currentUserId,
                  )
                  .toList();

              if (leaders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: const Color(0xFFE5E7EB),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No leaders found',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Responsive grid based on screen width
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth < 360
                  ? 1
                  : screenWidth < 600
                      ? 2
                      : screenWidth < 900
                          ? 3
                          : 4;
              
              // Dynamic aspect ratio based on screen size
              final aspectRatio = screenWidth < 360
                  ? 1.1
                  : screenWidth < 600
                      ? 0.75
                      : screenWidth < 900
                          ? 0.7
                          : 0.65;

              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: leaders.length,
                itemBuilder: (context, index) {
                  final leader = leaders[index];
                  return LeaderCard(
                    leader: leader,
                    currentUserId: _currentUserId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowingTab() {
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserById(_currentUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final followingIds = userSnapshot.data?.following ?? [];

        if (followingIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You haven\'t followed any leaders yet',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Text('Explore Leaders'),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<UserModel>>(
          future: _fetchFollowingLeaders(followingIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final followingLeaders = snapshot.data ?? [];

            if (followingLeaders.isEmpty) {
              return Center(
                child: Text(
                  'No leaders found',
                  style: TextStyle(color: const Color(0xFF9CA3AF)),
                ),
              );
            }

            // My Leaders: personal list, tap-to-view only (no Follow / Message here).
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: followingLeaders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final leader = followingLeaders[index];
                final faithLabel = leader.faith.toString().split('.').last;
                final bio = (leader.bio ?? '').trim();
                final subtitle = bio.isNotEmpty ? bio : 'Tap to view profile';

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LeaderProfileScreen(leaderId: leader.id),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFEEF2FF),
                            backgroundImage: leader.profilePhotoUrl != null
                                ? NetworkImage(leader.profilePhotoUrl!)
                                : null,
                            child: leader.profilePhotoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF6366F1),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leader.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Text(
                                        faithLabel.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${leader.followers.length} followers',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<UserModel>> _fetchLeaders() async {
    try {
      // Fetch ALL users from Firestore and filter religious leaders
      final users = await AuthService().getAllUsers();
      return users
          .where((user) => user.role == UserRole.religiousLeader)
          .toList();
    } catch (e) {
      print('Error fetching leaders: $e');
      return [];
    }
  }

  Future<List<UserModel>> _fetchFollowingLeaders(List<String> ids) async {
    try {
      List<UserModel> leaders = [];
      for (String id in ids) {
        final leader = await AuthService().getUserById(id);
        if (leader != null) {
          leaders.add(leader);
        }
      }
      return leaders;
    } catch (e) {
      return [];
    }
  }
}

// Leader Card Widget
class LeaderCard extends StatefulWidget {
  final UserModel leader;
  final String currentUserId;

  const LeaderCard({
    super.key,
    required this.leader,
    required this.currentUserId,
  });

  @override
  State<LeaderCard> createState() => _LeaderCardState();
}

class _LeaderCardState extends State<LeaderCard> {
  @override
  Widget build(BuildContext context) {
    final bio = (widget.leader.bio ?? '').trim();
    final description = bio.isNotEmpty ? bio : 'Daily prayers & guidance';
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 14.0;
    final verticalPadding = isSmallScreen ? 12.0 : 16.0;
    final avatarRadius = isSmallScreen ? 28.0 : 30.0;
    final nameFontSize = isSmallScreen ? 13.0 : 14.0;
    final descriptionFontSize = isSmallScreen ? 10.0 : 11.0;
    final buttonHeight = isSmallScreen ? 32.0 : 36.0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaderProfileScreen(leaderId: widget.leader.id),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _LeaderAvatar(
                  profilePhotoUrl: widget.leader.profilePhotoUrl,
                  radius: avatarRadius,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              Text(
                widget.leader.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              const Center(child: _LeaderBadge()),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Flexible(
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: descriptionFontSize,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: FollowButton(
                  worshipperId: widget.currentUserId,
                  leaderId: widget.leader.id,
                  height: buttonHeight,
                  compact: true,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderAvatar extends StatelessWidget {
  final String? profilePhotoUrl;
  final double radius;

  const _LeaderAvatar({
    required this.profilePhotoUrl,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEEF2FF),
      backgroundImage: profilePhotoUrl != null
          ? NetworkImage(profilePhotoUrl!)
          : null,
      child: profilePhotoUrl == null
          ? Icon(Icons.person, color: const Color(0xFF6366F1), size: radius)
          : null,
    );
  }
}

class _LeaderBadge extends StatelessWidget {
  const _LeaderBadge();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: isSmallScreen ? 12 : 14,
            color: const Color(0xFF6366F1),
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Text(
            'Leader',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}
