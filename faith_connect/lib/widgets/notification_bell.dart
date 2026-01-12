import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

/// Reusable notification bell widget for AppBar actions.
/// Shows unread count badge and navigates to NotificationsScreen on tap.
class NotificationBell extends StatefulWidget {
  /// Icon color (defaults to app theme primary color)
  final Color? iconColor;

  /// Icon size (defaults to 24)
  final double? iconSize;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.iconSize,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List>? _notificationsSub;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    super.dispose();
  }

  void _subscribeToNotifications() {
    // Wait for auth state
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      
      _notificationsSub?.cancel();
      
      if (user == null) {
        setState(() {
          _unreadCount = 0;
        });
        return;
      }

      _notificationsSub = _notificationService
          .getUserNotificationsStream(user.uid)
          .listen(
            (notifications) {
              if (!mounted) return;
              setState(() {
                _unreadCount = notifications
                    .where((n) => !n.isRead)
                    .length;
              });
            },
            onError: (e) {
              // Silent error handling - badge will show 0
              if (mounted) {
                setState(() => _unreadCount = 0);
              }
            },
          );
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ??
        Theme.of(context).appBarTheme.iconTheme?.color ??
        const Color(0xFF6366F1);
    final iconSize = widget.iconSize ?? 24.0;
    final showBadge = _unreadCount > 0;

    return IconButton(
      icon: _buildBadgedIcon(iconColor, iconSize, showBadge),
      onPressed: _navigateToNotifications,
      tooltip: 'Notifications',
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildBadgedIcon(Color iconColor, double iconSize, bool showBadge) {
    // Calm badge: muted indigo dot for 1-9, numeric for 10+.
    final bool showNumber = _unreadCount >= 10;
    final String label = _unreadCount > 99 ? '99+' : '$_unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_outlined, color: iconColor, size: iconSize),
        if (showBadge)
          Positioned(
            right: -6,
            top: -4,
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
              child: Container(
                key: ValueKey('badge_${showNumber ? 'num' : 'dot'}'),
                padding: showNumber
                    ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: showNumber
                    ? const BoxConstraints(minWidth: 16, minHeight: 16)
                    : const BoxConstraints(minWidth: 8, minHeight: 8),
                child: showNumber
                    ? Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : const SizedBox(width: 8, height: 8),
              ),
            ),
          ),
      ],
    );
  }
}
