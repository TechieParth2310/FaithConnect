import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../utils/profile_capabilities.dart';
import '../widgets/profile_header.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'following_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _currentUserId;
  late UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() async {
    final user = AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await AuthService().getUserById(_currentUserId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await AuthService().signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    if (_user!.role == UserRole.religiousLeader)
                      LeaderProfileHeader(
                        photoUrl: _user!.profilePhotoUrl,
                        name: _user!.name,
                        faithLabel: faithTypeToString(_user!.faith),
                        followersCount: _user!.followers.length,
                      )
                    else
                      WorshipperProfileHeader(
                        photoUrl: _user!.profilePhotoUrl,
                        name: _user!.name,
                        faithLabel: faithTypeToString(_user!.faith),
                        followingCount: _user!.following.length,
                        onFollowingTap:
                            ProfileCapabilities.showFollowing(_user!)
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FollowingScreen(userId: _currentUserId),
                                  ),
                                );
                              }
                            : null,
                      ),

                    const SizedBox(height: 16),

                    // Actions card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.edit_outlined,
                              title: 'Edit Profile',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      user: _user!,
                                      onSave: _fetchUserData,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _ActionTile(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _ActionTile(
                              icon: Icons.logout,
                              title: 'Logout',
                              titleColor: const Color(0xFFB91C1C),
                              iconColor: const Color(0xFFB91C1C),
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? const Color(0xFF0F172A)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: titleColor ?? const Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
    );
  }
}
