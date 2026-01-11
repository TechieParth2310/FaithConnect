import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'chat_detail_screen.dart';
import 'new_message_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final ScrollController _listController = ScrollController();

  String _query = '';
  int _pageSize = 30;

  final Map<String, UserModel?> _otherUserCache = <String, UserModel?>{};

  @override
  void initState() {
    super.initState();
    _listController.addListener(() {
      if (!_listController.hasClients) return;
      final pos = _listController.position;
      if (pos.maxScrollExtent <= 0) return;
      // When nearing the end, increase page size (simple pagination).
      if (pos.pixels > pos.maxScrollExtent - 500) {
        if (mounted) {
          setState(() {
            _pageSize = (_pageSize + 20).clamp(30, 150);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9FAFB),
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        final user = snapshot.data;
        final userId = user?.uid;

        if (userId == null || userId.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9FAFB),
            body: SafeArea(
              child: Center(child: Text('Please sign in to view messages.')),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAFB),
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'Messages',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFE5E7EB)),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'messages_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewMessageScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF6366F1),
            child: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: Icon(
                          Icons.search_outlined,
                          color: Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: _messageService.userConversationsStream(
                      userId: userId,
                      limit: _pageSize,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final docs =
                          (snapshot.data as dynamic)?.docs as List? ?? [];
                      if (docs.isEmpty) {
                        return _EmptyMessagesState(
                          onStart: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewMessageScreen(),
                              ),
                            );
                          },
                        );
                      }

                      final items = docs
                          .map((d) => (d.data() as Map).cast<String, dynamic>())
                          .toList();

                      return ListView.separated(
                        controller: _listController,
                        padding: EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          12 + MediaQuery.of(context).padding.bottom + 88,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final meta = items[index];
                          final conversationId = (meta['conversationId'] ?? '')
                              .toString();
                          final otherUserId = (meta['otherUserId'] ?? '')
                              .toString();
                          final unread = (meta['unreadCount'] is int)
                              ? meta['unreadCount'] as int
                              : 0;

                          return ConversationTile(
                            conversationId: conversationId,
                            otherUserId: otherUserId,
                            unreadCount: unread,
                            query: _query,
                            otherUserCache: _otherUserCache,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    chatId: conversationId,
                                    currentUserId: userId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyMessagesState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF9CA3AF),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No conversations yet',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Start a thoughtful conversation with a leader or a friend.',
              style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onStart,
              child: const Text(
                'Start new message',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationTile extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final int unreadCount;
  final VoidCallback onTap;
  final String query;
  final Map<String, UserModel?> otherUserCache;

  const ConversationTile({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.unreadCount,
    required this.onTap,
    required this.query,
    required this.otherUserCache,
  });

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  UserModel? _otherUser;
  Map<String, dynamic>? _header;

  static final Map<String, Map<String, dynamic>> _headerCache =
      <String, Map<String, dynamic>>{};

  @override
  void initState() {
    super.initState();
    _fetchOtherUser();
    _loadHeader();
  }

  @override
  void didUpdateWidget(ConversationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherUserId != widget.otherUserId) {
      _fetchOtherUser();
    }
    if (oldWidget.conversationId != widget.conversationId) {
      _loadHeader();
    }
  }

  void _fetchOtherUser() async {
    try {
      final cached = widget.otherUserCache[widget.otherUserId];
      if (cached != null) {
        if (mounted) setState(() => _otherUser = cached);
        return;
      }
      final user = await AuthService().getUserById(widget.otherUserId);
      if (mounted) {
        setState(() {
          _otherUser = user;
        });
      }
      widget.otherUserCache[widget.otherUserId] = user;
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  Future<void> _loadHeader() async {
    final cached = _headerCache[widget.conversationId];
    if (cached != null) {
      if (mounted) setState(() => _header = cached);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();
      final data = doc.data();
      if (data != null) {
        _headerCache[widget.conversationId] = data;
      }
      if (mounted) setState(() => _header = data);
    } catch (_) {
      // Non-fatal: UI will fall back to legacy/placeholder.
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${dateTime.month}/${dateTime.day}';
  }

  DateTime? _tsToDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = widget.unreadCount > 0;

    // If a query exists and we've loaded the user, filter by name/email.
    // (We keep list filtering lightweight and avoid extra reads here.)
    if (widget.query.isNotEmpty && _otherUser != null) {
      final q = widget.query.toLowerCase();
      final name = (_otherUser?.name ?? '').toLowerCase();
      final email = (_otherUser?.email ?? '').toLowerCase();
      if (!name.contains(q) && !email.contains(q)) {
        return const SizedBox.shrink();
      }
    }

    final lastMessage = (_header?['lastMessage'] ?? '').toString();
    final lastAt = _tsToDate(_header?['lastMessageAt']);
    final previewText = lastMessage.isNotEmpty ? lastMessage : 'Say hello';
    final timeText = lastAt != null ? _formatTime(lastAt) : '';

    return Semantics(
      label: 'Conversation with ${_otherUser?.name ?? 'user'}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnread ? const Color(0xFFF5F7FF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFEEF2FF),
                      backgroundImage: _otherUser?.profilePhotoUrl != null
                          ? NetworkImage(_otherUser!.profilePhotoUrl!)
                          : null,
                      child: _otherUser?.profilePhotoUrl == null
                          ? Text(
                              _otherUser?.name.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // Online indicator
                    if (_otherUser?.isOnline == true)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherUser?.name ?? 'User',
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        previewText,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnread
                              ? const Color(0xFF111827)
                              : const Color(0xFF6B7280),
                          fontWeight: isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Time and unread badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF9CA3AF),
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(height: 6),
                      if (widget.unreadCount <= 1)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.unreadCount > 99
                                ? '99+'
                                : '${widget.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
