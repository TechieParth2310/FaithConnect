import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';

class SpiritualChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const SpiritualChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<SpiritualChatScreen> createState() => _SpiritualChatScreenState();
}

class _ActionSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFEF4444) : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpiritualChatScreenState extends State<SpiritualChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  // Edit state
  String? _editingMessageId;
  final TextEditingController _editController = TextEditingController();

  // Reply state
  MessageModel? _replyingTo;

  // Selection state (Telegram-like)
  final Set<String> _selectedMessageIds = <String>{};
  List<MessageModel> _latestMessages = const <MessageModel>[];

  late String _otherUserId;
  UserModel? _otherUser;
  bool _isSending = false;
  bool _isOnline = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _extractOtherUserId();

    // Hide emoji picker when keyboard appears
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });

    // Mark messages as read instantly for this user (per-user metadata).
    MessageService().markConversationAsRead(
      conversationId: widget.chatId,
      userId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _editController.dispose();
    super.dispose();
  }

  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  bool _isAllSelected(List<MessageModel> messages) {
    if (!_isSelectionMode) return false;
    if (messages.isEmpty) return false;
    return _selectedMessageIds.length >= messages.length;
  }

  void _selectAll(List<MessageModel> messages) {
    if (messages.isEmpty) return;
    setState(() {
      _selectedMessageIds
        ..clear()
        ..addAll(messages.map((m) => m.id));
    });
  }

  void _clearSelection() {
    if (!_isSelectionMode) return;
    setState(_selectedMessageIds.clear);
  }

  void _toggleSelection(MessageModel message) {
    setState(() {
      if (_selectedMessageIds.contains(message.id)) {
        _selectedMessageIds.remove(message.id);
      } else {
        _selectedMessageIds.add(message.id);
      }
    });
  }

  List<MessageModel> _selectedMessages(List<MessageModel> messages) {
    if (_selectedMessageIds.isEmpty) return const <MessageModel>[];
    final byId = <String, MessageModel>{for (final m in messages) m.id: m};
    final result = <MessageModel>[];
    for (final id in _selectedMessageIds) {
      final m = byId[id];
      if (m != null) result.add(m);
    }
    // Keep message order as in list (newest-first because list is reversed)
    result.sort((a, b) => messages.indexOf(a).compareTo(messages.indexOf(b)));
    return result;
  }

  Future<void> _copySelected(List<MessageModel> selected) async {
    final texts = selected
        .where((m) => m.text.trim().isNotEmpty)
        .map((m) => m.text.trim())
        .toList();

    if (texts.isEmpty) {
      _showInfo('Nothing to copy');
      return;
    }

    await Clipboard.setData(ClipboardData(text: texts.join('\n')));
    _showInfo(texts.length == 1 ? 'Copied' : 'Copied ${texts.length} messages');
    _clearSelection();
  }

  Future<void> _forwardSelected(List<MessageModel> selected) async {
    if (selected.isEmpty) {
      _showInfo('Nothing to forward');
      return;
    }

    final otherUserId = await _pickConversationToForwardTo();
    if (otherUserId == null || otherUserId.isEmpty) return;

    try {
      for (final m in selected) {
        // Forward text content.
        if (m.text.trim().isNotEmpty) {
          await MessageService().sendMessage(
            senderId: widget.currentUserId,
            senderName: m.senderName,
            recipientId: otherUserId,
            text: m.text.trim(),
          );
        }

        // Forward image URLs as text (reliable without re-upload).
        if (m.imageUrl != null && m.imageUrl!.trim().isNotEmpty) {
          await MessageService().sendMessage(
            senderId: widget.currentUserId,
            senderName: m.senderName,
            recipientId: otherUserId,
            text: m.imageUrl!.trim(),
          );
        }
      }

      _showInfo(
        selected.length == 1 ? 'Forwarded' : 'Forwarded ${selected.length}',
      );
    } catch (e) {
      _showInfo(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _clearSelection();
    }
  }

  Future<String?> _pickConversationToForwardTo() async {
    if (!mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    'Forward to…',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: MessageService().userConversationsStream(
                      userId: widget.currentUserId,
                      limit: 60,
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      final docs = snap.data?.docs ?? const [];
                      final items = docs
                          .map((d) => d.data())
                          .where(
                            (m) => (m['conversationId'] ?? '')
                                .toString()
                                .isNotEmpty,
                          )
                          .where(
                            (m) =>
                                (m['conversationId'] ?? '').toString() !=
                                widget.chatId,
                          )
                          .toList(growable: false);

                      if (items.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No other conversations to forward to.',
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final meta = items[index];
                          final otherUserId = (meta['otherUserId'] ?? '')
                              .toString();
                          return FutureBuilder<UserModel?>(
                            future: AuthService().getUserById(otherUserId),
                            builder: (context, userSnap) {
                              final u = userSnap.data;
                              final title = u?.name ?? 'User';
                              final subtitle = u?.email ?? '';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  backgroundImage:
                                      (u?.profilePhotoUrl != null &&
                                          u!.profilePhotoUrl!.isNotEmpty)
                                      ? NetworkImage(u.profilePhotoUrl!)
                                      : null,
                                  child:
                                      (u?.profilePhotoUrl == null ||
                                          u!.profilePhotoUrl!.isEmpty)
                                      ? Text(
                                          title.isNotEmpty
                                              ? title[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Color(0xFF4F46E5),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: subtitle.isNotEmpty
                                    ? Text(subtitle)
                                    : null,
                                onTap: () =>
                                    Navigator.pop(context, otherUserId),
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

  Future<void> _deleteSelected(List<MessageModel> selected) async {
    // Only allow deleting messages the current user sent.
    final mine = selected
        .where((m) => m.senderId == widget.currentUserId)
        .toList(growable: false);
    final othersCount = selected.length - mine.length;

    if (mine.isEmpty) {
      _showInfo('You can only delete your own messages');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${mine.length} message${mine.length == 1 ? '' : 's'}?',
        ),
        content: Text(
          othersCount > 0
              ? 'Only your messages will be deleted. (${othersCount} selected message${othersCount == 1 ? '' : 's'} are not yours.)'
              : 'This will permanently delete the selected message${mine.length == 1 ? '' : 's'} for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final m in mine) {
        await MessageService().deleteMessageHard(
          chatId: widget.chatId,
          message: m,
          currentUserId: widget.currentUserId,
        );
      }
      _showInfo(
        mine.length == 1 ? 'Deleted' : 'Deleted ${mine.length} messages',
      );
    } catch (e) {
      _showInfo(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _clearSelection();
    }
  }

  bool _canEdit(MessageModel message) {
    if (message.senderId != widget.currentUserId) return false;
    if (message.type != MessageType.text) return false;
    final diff = DateTime.now().difference(message.timestamp);
    return diff.inMinutes <= 5;
  }

  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  void _startReply(MessageModel message) {
    setState(() => _replyingTo = message);
    // Focus composer
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _saveEdit(MessageModel message) async {
    final newText = _editController.text;
    if (!_canEdit(message)) {
      _showInfo('You can only edit within 5 minutes of sending.');
      return;
    }
    try {
      await MessageService().editTextMessage(
        chatId: widget.chatId,
        message: message,
        currentUserId: widget.currentUserId,
        newText: newText,
      );
      if (!mounted) return;
      setState(() {
        _editingMessageId = null;
        _editController.clear();
      });
    } catch (e) {
      _showInfo(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _showMessageActions(MessageModel message) async {
    if (_isSelectionMode) {
      _toggleSelection(message);
      return;
    }
    // Mandatory debug marker for on-device verification.
    debugPrint('LONG PRESS FIRED: ${message.id}');

    final isMe = message.senderId == widget.currentUserId;
    final canEdit = _canEdit(message);

    HapticFeedback.mediumImpact();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final items = <Widget>[];

        items.add(
          _ActionSheetItem(
            icon: Icons.reply,
            label: 'Reply',
            onTap: () {
              Navigator.pop(context);
              _startReply(message);
            },
          ),
        );

        items.add(
          _ActionSheetItem(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: message.text));
              _showInfo('Copied');
            },
          ),
        );

        if (isMe && message.type == MessageType.text) {
          items.add(
            _ActionSheetItem(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () {
                Navigator.pop(context);
                if (!canEdit) {
                  _showInfo('You can only edit within 5 minutes of sending.');
                  return;
                }
                setState(() {
                  _editingMessageId = message.id;
                  _editController.text = message.text;
                });
              },
            ),
          );
        }

        if (isMe) {
          items.add(
            _ActionSheetItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: () async {
                Navigator.pop(context);
                try {
                  await MessageService().deleteMessageHard(
                    chatId: widget.chatId,
                    message: message,
                    currentUserId: widget.currentUserId,
                  );
                } catch (e) {
                  _showInfo(e.toString().replaceAll('Exception: ', ''));
                }
              },
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isMe ? 'Message options' : 'Options',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        items[i],
                        if (i != items.length - 1)
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _extractOtherUserId() async {
    final ids = widget.chatId.split('_');
    if (ids.length == 2) {
      _otherUserId = ids[0] == widget.currentUserId ? ids[1] : ids[0];
      final user = await AuthService().getUserById(_otherUserId);
      if (mounted) {
        setState(() {
          _otherUser = user;
          // Use isOnline field or check lastSeen
          _isOnline = user?.isOnline ?? false;
          // Fallback: If lastSeen is within 5 minutes, consider online
          if (!_isOnline && user?.lastSeen != null) {
            _isOnline =
                DateTime.now().difference(user!.lastSeen!).inMinutes < 5;
          }
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final replyTo = _replyingTo == null
        ? null
        : ReplyToData(
            replyToMessageId: _replyingTo!.id,
            replySenderName: _replyingTo!.senderName,
            replyPreviewText: _replyingTo!.text,
          );

    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = await AuthService().getUserById(widget.currentUserId);
      if (currentUser == null) return;

      await MessageService().sendMessage(
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        recipientId: _otherUserId,
        text: messageText,
        replyTo: replyTo,
      );

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isSending = true;
      });

      final currentUser = await AuthService().getUserById(widget.currentUserId);
      if (currentUser == null) return;

      await MessageService().sendImageMessage(
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        recipientId: _otherUserId,
        imageFile: File(image.path),
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending image: $e')));
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (diff.inDays < 7) {
      return DateFormat('EEE h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // View Profile
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              title: const Text(
                'View Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile view coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Mute Notifications
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_off,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              title: const Text(
                'Mute Notifications',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Muted ${_otherUser!.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Block User
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.block, color: Colors.red, size: 20),
              ),
              title: const Text(
                'Block User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Block ${_otherUser!.name}?'),
                    content: const Text(
                      'You won\'t be able to send or receive messages from this user.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Blocked ${_otherUser!.name}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Block',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final isEditing = _editingMessageId == message.id;
    final isSelected = _selectedMessageIds.contains(message.id);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          if (_editingMessageId != null) return;
          if (_isSelectionMode) {
            _toggleSelection(message);
            return;
          }
          // Enter selection mode on first long-press (Telegram style),
          // while still allowing the premium single-message sheet when not selecting.
          setState(() {
            _selectedMessageIds.add(message.id);
          });
          // Also show the existing action sheet for single message.
          // Comment this line if you want pure Telegram behavior only.
          _showMessageActions(message);
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(message);
          }
        },
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 80 : 16,
            right: isMe ? 16 : 80,
            bottom: 12,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bubble (with a Telegram-ish blue selection overlay)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.60),
                          width: 1,
                        )
                      : null,
                  // Selection overlay sits behind the bubble content.
                  color: isSelected
                      ? const Color(0xFF3B82F6).withOpacity(0.14)
                      : (isMe ? null : Colors.grey[100]),
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? const Color(0xFF6366F1).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isEditing && message.replyTo != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.14)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: isMe
                                  ? Colors.white.withOpacity(0.6)
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
                              message.replyTo!.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isMe ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyTo!.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (message.imageUrl != null &&
                        message.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.imageUrl!,
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
                      ),
                    if (message.imageUrl != null && message.text.isNotEmpty)
                      const SizedBox(height: 8),
                    if (message.text.isNotEmpty)
                      if (isEditing && isMe && message.type == MessageType.text)
                        TextField(
                          controller: _editController,
                          autofocus: true,
                          maxLines: null,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      else
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  if (message.edited) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Edited',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? const Color(0xFF6366F1)
                          : Colors.grey[400],
                    ),
                  ],
                ],
              ),
              if (isEditing && isMe && message.type == MessageType.text) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _editingMessageId = null;
                          _editController.clear();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _saveEdit(message),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_otherUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final selectedCount = _selectedMessageIds.length;
    final selectedOne = selectedCount == 1
        ? _selectedMessages(_latestMessages).firstOrNull
        : null;

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _clearSelection();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              gradient: _isSelectionMode
                  ? const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF111827)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isSelectionMode
                              ? const Color(0xFF111827)
                              : const Color(0xFF6366F1))
                          .withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isSelectionMode ? Icons.close : Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_isSelectionMode) {
                          _clearSelection();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    if (_isSelectionMode) ...[
                      Expanded(
                        child: Text(
                          '$selectedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (selectedOne != null)
                        IconButton(
                          tooltip: 'Reply',
                          icon: const Icon(Icons.reply, color: Colors.white),
                          onPressed: () {
                            _clearSelection();
                            _startReply(selectedOne);
                          },
                        ),
                      if (selectedOne != null && _canEdit(selectedOne))
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _clearSelection();
                            setState(() {
                              _editingMessageId = selectedOne.id;
                              _editController.text = selectedOne.text;
                            });
                          },
                        ),
                      IconButton(
                        tooltip: _isAllSelected(_latestMessages)
                            ? 'Clear'
                            : 'Select all',
                        icon: Icon(
                          _isAllSelected(_latestMessages)
                              ? Icons.deselect
                              : Icons.select_all,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_isAllSelected(_latestMessages)) {
                            _clearSelection();
                          } else {
                            _selectAll(_latestMessages);
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () =>
                            _copySelected(_selectedMessages(_latestMessages)),
                      ),
                      IconButton(
                        tooltip: 'Forward',
                        icon: const Icon(Icons.forward, color: Colors.white),
                        onPressed: () => _forwardSelected(
                          _selectedMessages(_latestMessages),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            _deleteSelected(_selectedMessages(_latestMessages)),
                      ),
                    ] else ...[
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                _otherUser!.profilePhotoUrl != null &&
                                    _otherUser!.profilePhotoUrl!.isNotEmpty
                                ? NetworkImage(_otherUser!.profilePhotoUrl!)
                                : null,
                            child:
                                _otherUser!.profilePhotoUrl == null ||
                                    _otherUser!.profilePhotoUrl!.isEmpty
                                ? Text(
                                    _otherUser!.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                    ),
                                  )
                                : null,
                          ),
                          if (_isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _otherUser!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_otherUser!.role ==
                                    UserRole.religiousLeader) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _otherUser!.faith
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _otherUser!.role == UserRole.religiousLeader
                                        ? 'Religious Leader'
                                        : 'Worshipper',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isOnline)
                              Text(
                                'Active now',
                                style: TextStyle(
                                  color: Colors.greenAccent[100],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: _showOptionsMenu,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: MessageService().getMessagesStream(
                  userId1: widget.currentUserId,
                  userId2: _otherUserId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading messages',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];
                  _latestMessages = messages;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.1),
                                  const Color(0xFF8B5CF6).withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '🙏 Start a Spiritual Conversation',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send your first message',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mark messages as read
                  MessageService().markChatAsRead(
                    widget.chatId,
                    widget.currentUserId,
                  );

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),

            // Emoji Picker
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text += emoji.emoji;
                  },
                  config: const Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28,
                      columns: 7,
                      backgroundColor: Colors.white,
                    ),
                    skinToneConfig: SkinToneConfig(),
                    categoryViewConfig: CategoryViewConfig(
                      indicatorColor: Color(0xFF6366F1),
                      iconColorSelected: Color(0xFF6366F1),
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),

            // Input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: SafeArea(
                child: Row(
                  children: [
                    // Image picker button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _isSending ? null : _pickAndSendImage,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Message input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _focusNode,
                                maxLines: null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: 'Send a message...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _showEmojiPicker
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions_outlined,
                                color: _showEmojiPicker
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _showEmojiPicker = !_showEmojiPicker;
                                  if (_showEmojiPicker) {
                                    _focusNode.unfocus();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send button
                    _isSending
                        ? Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
