import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/test_data_seeder.dart';
import '../utils/gradient_theme.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserById(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF6366F1),
                          backgroundImage: _currentUser?.profilePhotoUrl != null
                              ? NetworkImage(_currentUser!.profilePhotoUrl!)
                              : null,
                          child: _currentUser?.profilePhotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.name ?? 'User',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentUser?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _currentUser?.role == UserRole.religiousLeader
                                      ? 'Religious Leader'
                                      : 'Worshiper',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Settings Options
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: GradientTheme.cardDecoration(borderRadius: 18),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.person,
                          title: 'Edit Profile',
                          subtitle: 'Update your profile information',
                          onTap: () {
                            if (_currentUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(
                                    user: _currentUser!,
                                    onSave: _loadUserData,
                                  ),
                                ),
                              ).then((_) => _loadUserData());
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: 'Manage notification preferences',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notification settings coming soon!',
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.lock,
                          title: 'Privacy',
                          subtitle: 'Control your privacy settings',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy settings coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.help,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact us',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Help & Support coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.info,
                          title: 'About',
                          subtitle: 'Learn more about FaithConnect',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'FaithConnect',
                              applicationVersion: '1.0.0',
                              applicationIcon: const FlutterLogo(size: 48),
                              children: [
                                const Text(
                                  'FaithConnect is a multi-faith social platform '
                                  'connecting worshipers with religious leaders.',
                                ),
                              ],
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.science,
                          title: 'Generate Test Data',
                          subtitle:
                              'Add sample followers & messages for testing',
                          onTap: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            await TestDataSeeder.seedTestData();

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Test data added! Check Messages and following/followers',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Delete Account Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: GradientTheme.cardDecoration(borderRadius: 18),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          subtitle:
                              'Permanently delete your account and all data',
                          iconColor: const Color(0xFFEF4444),
                          accentColor: GradientTheme.pastelPink,
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Logout Button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone. All your data including:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Your profile and posts', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('• Messages and conversations', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('• Followers and following', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('• Saved content', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'will be permanently deleted.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleDeleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _authService.deleteAccount();

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show success message and navigate to landing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to landing screen or auth screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor,
    Color? iconColor,
  }) {
    final finalAccentColor = accentColor ?? GradientTheme.pastelSkyBlue;
    final finalIconColor = iconColor ?? const Color(0xFF6366F1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: finalAccentColor,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: GradientTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GradientTheme.textMedium,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
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
