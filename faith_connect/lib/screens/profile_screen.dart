import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../utils/profile_capabilities.dart';
import '../utils/gradient_theme.dart';
import '../widgets/profile_header.dart';
import '../widgets/notification_bell.dart';
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
      backgroundColor: GradientTheme.softBackground,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: GradientTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: const [
          NotificationBell(iconColor: Colors.white),
        ],
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile Header with gradient styling
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

                  const SizedBox(height: 20),

                  // Actions card with premium styling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: GradientTheme.cardDecoration(borderRadius: 20),
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Update your information',
                            accentColor: GradientTheme.pastelSkyBlue,
                            iconColor: const Color(0xFF3B82F6),
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
                          const Divider(height: 1, indent: 72),
                          _ActionTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'Manage your preferences',
                            accentColor: GradientTheme.pastelMint,
                            iconColor: const Color(0xFF10B981),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 72),
                          _ActionTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            subtitle: 'Sign out of your account',
                            accentColor: const Color(0xFFFFE5E5),
                            iconColor: const Color(0xFFEF4444),
                            titleColor: const Color(0xFFEF4444),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color accentColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.accentColor,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final finalIconColor = iconColor ?? GradientTheme.textDark;
    final finalTitleColor = titleColor ?? GradientTheme.textDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: finalIconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: finalTitleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: GradientTheme.textMedium,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: GradientTheme.textLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
