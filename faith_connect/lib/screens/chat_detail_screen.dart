import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'leader_profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final MessageService _messageService = MessageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _sortedChatId;
  late String _otherUserId;
  UserModel? _otherUser;

  final Map<String, int> _messageIndexById = {};
  String? _flashMessageId;
  String? _selectedMessageId;
  MessageModel? _replyingTo;
  String? _editingMessageId;

  // Audio playback state (kept for potential future use)
  // final AudioPlayer _audioPlayer = AudioPlayer();
  // bool _isPlayingAudio = false;
  // String? _playingAudioUrl;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final ids = widget.chatId.split('_');
    if (ids.length == 2) {
      _otherUserId = ids[0] == widget.currentUserId ? ids[1] : ids[0];
      final sortedIds = <String>[widget.currentUserId, _otherUserId]..sort();
      _sortedChatId = sortedIds.join('_');
    } else {
      _sortedChatId = widget.chatId;
      _otherUserId = '';
    }
    _loadOtherUser();
  }

  Future<void> _loadOtherUser() async {
    if (_otherUserId.isEmpty) return;
    final user = await AuthService().getUserById(_otherUserId);
    if (mounted) {
      setState(() => _otherUser = user);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageService
        .markConversationAsRead(
          conversationId: widget.chatId,
          userId: widget.currentUserId,
        )
        .catchError((e) => debugPrint('markConversationAsRead failed: $e'));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    // _audioPlayer.dispose(); // Commented out since AudioPlayer is not used
    super.dispose();
  }



  bool _isMine(MessageModel message) =>
      message.senderId == widget.currentUserId;

  bool _canEdit(MessageModel message) {
    if (!_isMine(message)) return false;
    if (message.type != MessageType.text) return false;
    final diff = DateTime.now().difference(message.timestamp);
    return diff.inMinutes <= 5;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _onMessageLongPress(MessageModel message) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedMessageId = message.id;
    });
    _showMessageActionsSheet(message);
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageId = null;
    });
  }

  void _onMessageTap(MessageModel message) {
    if (_selectedMessageId != null) {
      _clearSelection();
    }
  }

  void _showMessageActionsSheet(MessageModel message) {
    final isMine = _isMine(message);
    final canEdit = _canEdit(message);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.reply,
                label: 'Reply',
                onTap: () {
                  Navigator.pop(ctx);
                  _startReply(message);
                },
              ),
              if (isMine && canEdit)
                _ActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {
                    Navigator.pop(ctx);
                    _startEdit(message);
                  },
                ),
              _ActionTile(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  Navigator.pop(ctx);
                  _copyMessage(message);
                },
              ),
              _ActionTile(
                icon: Icons.forward,
                label: 'Forward',
                onTap: () {
                  Navigator.pop(ctx);
                  _forwardMessage(message);
                },
              ),
              if (isMine)
                _ActionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessage(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _clearSelection();
    });
  }

  void _startReply(MessageModel message) {
    setState(() {
      _replyingTo = message;
      _editingMessageId = null;
    });
    _clearSelection();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _startEdit(MessageModel message) {
    if (!_canEdit(message)) {
      _showSnackBar('You can only edit within 5 minutes of sending');
      return;
    }
    setState(() {
      _editingMessageId = message.id;
      _editController.text = message.text;
      _replyingTo = null;
    });
    _clearSelection();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(MessageModel message) async {
    final newText = _editController.text.trim();
    if (newText.isEmpty) {
      _showSnackBar('Message cannot be empty');
      return;
    }
    if (!_canEdit(message)) {
      _showSnackBar('Edit window has expired');
      _cancelEdit();
      return;
    }

    try {
      await _messageService.editTextMessage(
        chatId: _sortedChatId,
        message: message,
        currentUserId: widget.currentUserId,
        newText: newText,
      );
      _cancelEdit();
      _showSnackBar('Message edited');
    } catch (e) {
      _showSnackBar(
        'Failed to edit: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }

  Future<void> _copyMessage(MessageModel message) async {
    await Clipboard.setData(ClipboardData(text: message.text));
    _showSnackBar('Copied to clipboard');
    _clearSelection();
  }

  Future<void> _deleteMessage(MessageModel message) async {
    if (!_isMine(message)) {
      _showSnackBar('You can only delete your own messages');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _messageService.deleteMessageHard(
        chatId: _sortedChatId,
        message: message,
        currentUserId: widget.currentUserId,
      );
      _clearSelection();
      _showSnackBar('Message deleted');
    } catch (e) {
      _showSnackBar(
        'Failed to delete: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }

  Future<void> _forwardMessage(MessageModel message) async {
    final otherUserId = await _pickConversationToForwardTo();
    if (otherUserId == null || otherUserId.isEmpty) return;

    try {
      final currentUser = await AuthService().getUserById(widget.currentUserId);
      if (currentUser == null) return;

      if (message.text.trim().isNotEmpty) {
        await _messageService.sendMessage(
          senderId: widget.currentUserId,
          senderName: currentUser.name,
          recipientId: otherUserId,
          text: message.text.trim(),
        );
      }

      if (message.imageUrl != null && message.imageUrl!.trim().isNotEmpty) {
        await _messageService.sendMessage(
          senderId: widget.currentUserId,
          senderName: currentUser.name,
          recipientId: otherUserId,
          text: message.imageUrl!.trim(),
        );
      }

      _showSnackBar('Message forwarded');
    } catch (e) {
      _showSnackBar(
        'Failed to forward: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
    _clearSelection();
  }

  Future<String?> _pickConversationToForwardTo() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx2, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Forward to...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder(
                stream: _messageService.userConversationsStream(
                  userId: widget.currentUserId,
                  limit: 50,
                ),
                builder: (ctx3, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  final items = docs
                      .map((d) => d.data())
                      .where(
                        (m) =>
                            (m['conversationId'] ?? '').toString().isNotEmpty &&
                            (m['conversationId'] ?? '').toString() !=
                                widget.chatId,
                      )
                      .toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('No other conversations'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (ctx4, index) {
                      final meta = items[index];
                      final otherUserId = (meta['otherUserId'] ?? '')
                          .toString();
                      return FutureBuilder<UserModel?>(
                        future: AuthService().getUserById(otherUserId),
                        builder: (ctx5, userSnap) {
                          final u = userSnap.data;
                          final name = u?.name ?? 'User';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEEF2FF),
                              backgroundImage: u?.profilePhotoUrl != null
                                  ? NetworkImage(u!.profilePhotoUrl!)
                                  : null,
                              child: u?.profilePhotoUrl == null
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(name),
                            onTap: () => Navigator.pop(ctx2, otherUserId),
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
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    ReplyToData? replyTo;
    if (_replyingTo != null) {
      replyTo = ReplyToData(
        replyToMessageId: _replyingTo!.id,
        replySenderName: _replyingTo!.senderName,
        replyPreviewText: _replyingTo!.text.trim(),
      );
    }

    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }

    try {
      final currentUser = await AuthService().getUserById(widget.currentUserId);
      if (currentUser == null) return;

      await _messageService.sendMessage(
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        recipientId: _otherUserId,
        text: text,
        replyTo: replyTo,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error sending message: $e');
    }
  }

  Future<void> _scrollToMessage(String messageId) async {
    final index = _messageIndexById[messageId];
    if (index == null) {
      _showSnackBar('Original message not found');
      return;
    }

    if (!_scrollController.hasClients) return;

    const approxItemExtent = 72.0;
    final targetOffset = (index * approxItemExtent).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    if (!mounted) return;
    setState(() => _flashMessageId = messageId);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      if (_flashMessageId == messageId) _flashMessageId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_otherUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          if (_otherUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeaderProfileScreen(leaderId: _otherUserId),
              ),
            );
          }
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6366F1),
              backgroundImage: _otherUser?.profilePhotoUrl != null
                  ? NetworkImage(_otherUser!.profilePhotoUrl!)
                  : null,
              child: _otherUser?.profilePhotoUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.name ?? 'User',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Active now',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _firestore
          .collection('chats')
          .doc(_sortedChatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => MessageModel.fromFirestore(d)).toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];

        _messageIndexById.clear();
        for (var i = 0; i < messages.length; i++) {
          _messageIndexById[messages[i].id] = i;
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isCurrentUser = _isMine(message);
            final isSelected = _selectedMessageId == message.id;
            final isFlashing = _flashMessageId == message.id;
            final isEditing = _editingMessageId == message.id;

            return ChatBubble(
              key: ValueKey('bubble-${message.id}'),
              message: message,
              isMine: isCurrentUser,
              isSelected: isSelected,
              isFlashing: isFlashing,
              isEditing: isEditing,
              editController: _editController,
              timeLabel: _formatTime(message.timestamp),
              onLongPress: () => _onMessageLongPress(message),
              onTap: () => _onMessageTap(message),
              onTapQuotedReply: message.replyTo != null
                  ? () => _scrollToMessage(message.replyTo!.replyToMessageId)
                  : null,
              onSaveEdit: isEditing ? () => _saveEdit(message) : null,
              onCancelEdit: isEditing ? _cancelEdit : null,
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingTo != null) _buildReplyPreview(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _replyingTo != null
                                ? 'Reply...'
                                : 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFF6366F1),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingTo!.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF374151)),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? const Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMine;
  final bool isSelected;
  final bool isFlashing;
  final bool isEditing;
  final TextEditingController editController;
  final String timeLabel;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback? onTapQuotedReply;
  final VoidCallback? onSaveEdit;
  final VoidCallback? onCancelEdit;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isSelected,
    required this.isFlashing,
    required this.isEditing,
    required this.editController,
    required this.timeLabel,
    required this.onLongPress,
    required this.onTap,
    this.onTapQuotedReply,
    this.onSaveEdit,
    this.onCancelEdit,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isPressed = false;

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress();
  }

  void _handleTap() {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isMine
        ? (widget.isSelected
              ? const Color(0xFF4F46E5)
              : const Color(0xFF6366F1))
        : (widget.isSelected
              ? const Color(0xFFD1D5DB)
              : const Color(0xFFF3F4F6));

    final textColor = widget.isMine ? Colors.white : const Color(0xFF1F2937);
    final metaColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF6B7280);

    // Row background highlight when selected
    final rowHighlight = widget.isSelected
        ? (widget.isMine
              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
              : const Color(0xFF111827).withValues(alpha: 0.04))
        : widget.isFlashing
        ? const Color(0xFFFEF3C7)
        : Colors.transparent;

    return Container(
      color: rowHighlight,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
              minWidth: 80,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isPressed
                  ? (widget.isMine
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE5E7EB))
                  : bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.isMine ? 16 : 4),
                bottomRight: Radius.circular(widget.isMine ? 4 : 16),
              ),
              border: widget.isSelected
                  ? Border.all(
                      color: widget.isMine
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF6366F1),
                      width: 2,
                    )
                  : null,
              boxShadow: widget.isFlashing
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quoted reply (if any)
                if (widget.message.replyTo != null && !widget.isEditing)
                  _buildQuotedReply(textColor),

                // Main content or edit field
                if (widget.isEditing)
                  _buildEditField(textColor)
                else if (widget.message.type == MessageType.audio)
                  _buildAudioMessage(textColor, metaColor)
                else if (widget.message.type == MessageType.image)
                  _buildImageMessage(textColor)
                else
                  // Message text
                  Text(
                    widget.message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),

                // Timestamp - ALWAYS below text, right-aligned
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(),
                    if (widget.message.edited)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: metaColor,
                          ),
                        ),
                      ),
                    Text(
                      widget.timeLabel,
                      style: TextStyle(fontSize: 10, color: metaColor),
                    ),
                  ],
                ),

                // Edit buttons (if editing)
                if (widget.isEditing) _buildEditButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotedReply(Color textColor) {
    return GestureDetector(
      onTap: widget.onTapQuotedReply,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isMine
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: widget.isMine
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF6366F1),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message.replyTo!.replySenderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.isMine
                    ? Colors.white.withValues(alpha: 0.95)
                    : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.message.replyTo!.replyPreviewText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: widget.isMine
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(Color textColor) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: TextField(
        controller: widget.editController,
        autofocus: true,
        maxLines: null,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: widget.onCancelEdit,
            style: TextButton.styleFrom(
              foregroundColor: widget.isMine
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: widget.onSaveEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isMine
                  ? Colors.white
                  : const Color(0xFF6366F1),
              foregroundColor: widget.isMine
                  ? const Color(0xFF1F2937)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              elevation: 0,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMessage(Color textColor, Color metaColor) {
    // Note: Audio playback will be handled by parent widget
    final duration = widget.message.audioDuration ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 3,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: metaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(Color textColor) {
    if (widget.message.imageUrl == null) {
      return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.message.imageUrl!,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50),
          );
        },
      ),
    );
  }
}
