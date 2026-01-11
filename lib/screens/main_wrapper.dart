import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'leaders_screen.dart';
import 'reels_screen.dart';
import 'search_screen.dart';
import 'create_post_screen.dart';
import 'create_reel_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'leader_dashboard_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  bool _isLoading = true;
  Function(bool)? _reelsSetActive;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;
  final MessageService _messageService = MessageService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _unreadMessagesSub;
  StreamSubscription? _unreadNotificationsSub;
  StreamSubscription<User?>? _authSub;

  /// Lazy-mount: only build a screen after it has been visited at least once.
  /// This prevents heavy screens (like Reels video playback) from initializing
  /// offstage when using a bottom nav.
  final Set<int> _mountedTabIndices = <int>{0};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    // Drive unread badges purely from Firestore streams, but wait until auth is ready.
    // This prevents null/invalid userId subscriptions that can cause flicker.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _unreadMessageCount = 0;
          _unreadNotificationCount = 0;
        });
        _unreadMessagesSub?.cancel();
        _unreadNotificationsSub?.cancel();
        return;
      }
      _subscribeToUnreadCounts(user.uid);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _unreadMessagesSub?.cancel();
    _unreadNotificationsSub?.cancel();
    super.dispose();
  }

  void _subscribeToUnreadCounts(String userId) {
    // Subscribe to messages (per-user total unread)
    _unreadMessagesSub?.cancel();
    _unreadMessagesSub = _messageService
        .totalUnreadStream(userId)
        .listen(
          (n) {
            if (!mounted) return;
            setState(() => _unreadMessageCount = n);
          },
          onError: (e) {
            // ignore: avoid_print
            print('❌ Unread message stream error: $e');
          },
        );

    // Subscribe to notifications
    _unreadNotificationsSub?.cancel();
    _unreadNotificationsSub = _notificationService
        .getUserNotificationsStream(userId)
        .listen(
          (notifications) {
            if (!mounted) return;
            setState(() {
              _unreadNotificationCount = notifications
                  .where((n) => !n.isRead)
                  .length;
            });
          },
          onError: (e) {
            // ignore: avoid_print
            print('❌ Unread notification stream error: $e');
          },
        );
  }

  Widget _buildBadgedIcon({
    required IconData icon,
    required int count,
    Color? iconColor,
  }) {
    final show = count > 0;

    // Calm badge: muted indigo dot for 1-9, numeric for 10+.
    final bool showNumber = count >= 10;
    final String label = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: iconColor),
        Positioned(
          right: -8,
          top: -6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: !show
                ? const SizedBox.shrink(key: ValueKey('no_badge'))
                : Container(
                    key: ValueKey('badge_${showNumber ? 'num' : 'dot'}'),
                    padding: showNumber
                        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: showNumber
                        ? const BoxConstraints(minWidth: 18, minHeight: 18)
                        : const BoxConstraints(minWidth: 10, minHeight: 10),
                    child: showNumber
                        ? Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const SizedBox(width: 10, height: 10),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadCurrentUser() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      final userData = await authService.getUserById(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> get _screens {
    if (_currentUser?.role == UserRole.religiousLeader) {
      // Religious Leader screens - COMPLETELY DIFFERENT UI
      return [
        const LeaderDashboardScreen(), // Leader Dashboard (NOT home feed)
        const SearchScreen(),
        const MessagesScreen(),
        const NotificationsScreen(),
        const ProfileScreen(),
      ];
    } else {
      // Worshipper screens
      return [
        const HomeScreen(),
        ReelsScreen(
          onSetActiveCallback: (callback) => _reelsSetActive = callback,
        ),
        const LeadersScreen(), // Browse religious leaders
        const MessagesScreen(),
        const NotificationsScreen(),
        const ProfileScreen(),
      ];
    }
  }

  Widget _buildLazyBody() {
    final screens = _screens;
    // Safety: if nav items change due to role switch, ensure index is valid.
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Stack(
      children: List.generate(screens.length, (index) {
        final shouldBuild = _mountedTabIndices.contains(index);
        return Offstage(
          offstage: safeIndex != index,
          child: shouldBuild ? screens[index] : const SizedBox.shrink(),
        );
      }),
    );
  }

  List<BottomNavigationBarItem> get _navBarItems {
    if (_currentUser?.role == UserRole.religiousLeader) {
      // Leader navigation - Different labels
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgedIcon(
            icon: Icons.message,
            count: _unreadMessageCount,
            iconColor: _currentIndex == 2
                ? const Color(0xFF6366F1)
                : const Color(0xFF9CA3AF),
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgedIcon(
            icon: Icons.notifications,
            count: _unreadNotificationCount,
            iconColor: _currentIndex == 3
                ? const Color(0xFF6366F1)
                : const Color(0xFF9CA3AF),
          ),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      // Worshipper navigation
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: 'Reels',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Leaders',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgedIcon(
            icon: Icons.message,
            count: _unreadMessageCount,
            iconColor: _currentIndex == 3
                ? const Color(0xFF6366F1)
                : const Color(0xFF9CA3AF),
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: _buildBadgedIcon(
            icon: Icons.notifications,
            count: _unreadNotificationCount,
            iconColor: _currentIndex == 4
                ? const Color(0xFF6366F1)
                : const Color(0xFF9CA3AF),
          ),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Content',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image, color: Colors.blue[700]),
              ),
              title: const Text(
                'Create Post',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Share images and text'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.video_library, color: Colors.purple[700]),
              ),
              title: const Text(
                'Create Reel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Share short videos (15-60s)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateReelScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLeader = _currentUser?.role == UserRole.religiousLeader;
    // On Messages, the primary action is "New Message" (screen-local FAB).
    // Hide the global leader Create Content FAB to avoid overlap and keep the
    // UX context-aware and premium.
    final isMessagesTab = isLeader ? _currentIndex == 2 : _currentIndex == 3;

    // Premium FAB placement:
    // - Floats above the BottomNavigationBar with SafeArea awareness
    // - Avoids system gesture area
    // - Keeps a comfortable ~24dp visual gap from the nav
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // BottomNavigationBar default height is 56dp.
    const navBarHeight = 56.0;
    const fabDiameter = 56.0; // 56–60dp spec
    const gapAboveNav = 24.0; // 24–32px spec
    final fabBottom = bottomInset + navBarHeight + gapAboveNav;

    return Scaffold(
      body: _buildLazyBody(),
      // Only leaders get the FAB
      floatingActionButton: (isLeader && !isMessagesTab)
          ? _FloatingCreateFab(onPressed: _showCreateOptions, size: fabDiameter)
          : null,
      floatingActionButtonLocation: _AboveBottomNavFabLocation(
        bottom: fabBottom,
        right: 16,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF9CA3AF),
        onTap: (index) {
          // Notify ReelsScreen of active state (worshippers only).
          if (!isLeader) {
            final reelsIndex = 1;
            _reelsSetActive?.call(index == reelsIndex);
          }

          // Mark this tab as eligible to be built (lazy-mount).
          _mountedTabIndices.add(index);

          setState(() {
            _currentIndex = index;
          });
        },
        items: _navBarItems,
      ),
    );
  }
}

/// Places FAB above bottom navigation with explicit SafeArea-aware bottom offset.
///
/// We intentionally use a custom location (instead of centerDocked) so the FAB
/// reads as a primary action, not part of navigation.
class _AboveBottomNavFabLocation extends FloatingActionButtonLocation {
  const _AboveBottomNavFabLocation({required this.bottom, required this.right});

  final double bottom;
  final double right;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    return Offset(
      scaffoldGeometry.scaffoldSize.width - fabSize.width - right,
      scaffoldGeometry.scaffoldSize.height - fabSize.height - bottom,
    );
  }
}

class _FloatingCreateFab extends StatefulWidget {
  const _FloatingCreateFab({required this.onPressed, required this.size});

  final VoidCallback onPressed;
  final double size;

  @override
  State<_FloatingCreateFab> createState() => _FloatingCreateFabState();
}

class _FloatingCreateFabState extends State<_FloatingCreateFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Slight scale animation on tap (premium feel).
    await _controller.forward();
    await _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    // Spec: minimum 16dp touch padding.
    // We wrap the visual 56dp button with padding to increase the hit target.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final scale = 1.0 - (0.06 * t);
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'mainWrapperCreateFab',
              onPressed: _handleTap,
              backgroundColor: const Color(0xFF6366F1),
              elevation: 0,
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
