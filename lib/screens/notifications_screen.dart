import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'chat_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late String _currentUserId;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _notificationService.markAllAsRead(_currentUserId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All marked as read'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Mark All',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF111827)),
            onSelected: (value) async {
              if (value != 'clearAll') return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear all notifications?'),
                  content: const Text(
                    'This will permanently delete all notifications.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              try {
                await _notificationService.clearAllNotifications(
                  _currentUserId,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clearAll', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotificationsStream(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Check if it's a Firestore index error
            final errorMessage = snapshot.error.toString();
            if (errorMessage.contains('index') ||
                errorMessage.contains('FAILED_PRECONDITION')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Firestore Index Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Notifications need a database index to work properly.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Steps to fix:\n'
                        '1. Open Firebase Console\n'
                        '2. Go to Firestore Database\n'
                        '3. Click "Indexes" tab\n'
                        '4. Click the link in terminal/logs\n'
                        '5. Wait 2-5 minutes for index creation',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            // Force rebuild
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: const Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Dismissible(
                key: ValueKey(notification.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: const Color(0xFFFEE2E2),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Color(0xFFB91C1C)),
                ),
                secondaryBackground: Container(
                  color: const Color(0xFFFEE2E2),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Color(0xFFB91C1C)),
                ),
                onDismissed: (_) async {
                  try {
                    await _notificationService.deleteNotification(
                      notification.id,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: NotificationTile(
                  notification: notification,
                  currentUserId: _currentUserId,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatefulWidget {
  final NotificationModel notification;
  final String currentUserId;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.currentUserId,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  UserModel? _fromUser;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchFromUser();
  }

  void _fetchFromUser() async {
    final user = await AuthService().getUserById(widget.notification.actorId);
    setState(() {
      _fromUser = user;
    });
  }

  String _getNotificationMessage() {
    switch (widget.notification.type) {
      case NotificationType.like:
        return 'liked your post';
      case NotificationType.comment:
        return 'commented on your post';
      case NotificationType.newFollower:
        return 'started following you';
      case NotificationType.newMessage:
        return 'sent you a message';
      case NotificationType.newPost:
        return 'posted new content';
      case NotificationType.newReel:
        return 'posted a new reel';
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.newFollower:
        return Icons.person_add;
      case NotificationType.newMessage:
        return Icons.mail;
      case NotificationType.newPost:
        return Icons.post_add;
      case NotificationType.newReel:
        return Icons.play_circle;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // TAP TO READ (AUTO-CLEAR): mark read first, then navigate.
        if (!widget.notification.isRead) {
          try {
            await _notificationService.markNotificationAsRead(
              widget.notification.id,
            );
          } catch (_) {
            // Silent - stream will retry/refresh.
          }
        }

        if (widget.notification.type == NotificationType.newMessage &&
            widget.notification.chatId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: widget.notification.chatId!,
                currentUserId: widget.currentUserId,
              ),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opening ${widget.notification.type.toString().split('.').last}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.notification.isRead
              ? Colors.white
              : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.notification.isRead
                ? const Color(0xFFE5E7EB)
                : const Color(0xFFD1CCFF),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF6366F1),
                  backgroundImage: _fromUser?.profilePhotoUrl != null
                      ? NetworkImage(_fromUser!.profilePhotoUrl!)
                      : null,
                  child: _fromUser?.profilePhotoUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                // Notification type indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _getNotificationIcon(),
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _fromUser?.name ?? 'User',
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_getNotificationMessage()}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(widget.notification.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!widget.notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
