import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/auth_service.dart';
import 'leader_profile_screen.dart';

/// Followers for a leader.
///
/// Product rule:
/// - Leaders are followed.
/// - This screen lists worshippers who follow the given leader.
class FollowersScreen extends StatefulWidget {
  final String leaderId;

  const FollowersScreen({super.key, required this.leaderId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  bool _isLoading = true;
  UserModel? _leader;
  List<UserModel> _followers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _isLoading = true);

      final leader = await AuthService().getUserById(widget.leaderId);
      if (!mounted) return;

      if (leader == null) {
        setState(() {
          _leader = null;
          _followers = [];
          _isLoading = false;
        });
        return;
      }

      final followerUsers = <UserModel>[];
      for (final followerId in leader.followers) {
        final u = await AuthService().getUserById(followerId);
        if (u != null) followerUsers.add(u);
      }

      if (!mounted) return;
      setState(() {
        _leader = leader;
        _followers = followerUsers;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leader = _leader;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          leader == null ? 'Followers' : '${leader.name}\'s Followers',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : leader == null
          ? const Center(
              child: Text(
                'Leader not found',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : _followers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.black.withValues(alpha: 0.10),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No followers yet',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _followers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = _followers[index];

                  return Container(
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
                    child: ListTile(
                      onTap: () {
                        // If a follower is also a leader, open their leader profile.
                        if (user.role == UserRole.religiousLeader) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LeaderProfileScreen(leaderId: user.id),
                            ),
                          );
                        }
                      },
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEEF2FF),
                        backgroundImage: user.profilePhotoUrl != null
                            ? NetworkImage(user.profilePhotoUrl!)
                            : null,
                        child: user.profilePhotoUrl == null
                            ? const Icon(Icons.person, color: Color(0xFF6366F1))
                            : null,
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: Text(
                        user.role == UserRole.religiousLeader
                            ? 'Leader'
                            : 'Worshipper',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
