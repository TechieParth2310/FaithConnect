import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../widgets/follow_button.dart';
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Religious Leaders',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Discover spiritual guides you resonate with',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF111827),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          indicatorColor: const Color(0xFF6366F1),
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

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 360
                      ? 1
                      : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  // Slightly taller to guarantee no overflow with long bio
                  // and the fixed 48dp CTA on small screens.
                  childAspectRatio: 0.78,
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
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LeaderAvatar(profilePhotoUrl: widget.leader.profilePhotoUrl),
              const SizedBox(height: 8),
              Text(
                widget.leader.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const _LeaderBadge(),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FollowButton(
                  worshipperId: widget.currentUserId,
                  leaderId: widget.leader.id,
                  height: 48,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
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

  const _LeaderAvatar({required this.profilePhotoUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFEEF2FF),
      backgroundImage: profilePhotoUrl != null
          ? NetworkImage(profilePhotoUrl!)
          : null,
      child: profilePhotoUrl == null
          ? const Icon(Icons.person, color: Color(0xFF6366F1), size: 30)
          : null,
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: Color(0xFF6366F1)),
          SizedBox(width: 6),
          Text(
            'Leader',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}
