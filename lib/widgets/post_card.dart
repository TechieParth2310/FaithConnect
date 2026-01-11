import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/index.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;

  const PostCard({super.key, required this.post, required this.currentUserId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  bool _isSaved = false;
  final TextEditingController _commentController = TextEditingController();

  // Comment action state
  CommentModel? _replyingTo;
  CommentModel? _editingComment;
  List<CommentModel> _localComments = [];

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likedBy.contains(widget.currentUserId);
    _likeCount = widget.post.likedBy.length;
    _commentCount = widget.post.comments.length;
    _localComments = List.from(widget.post.comments);
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final postService = PostService();
    final saved = await postService.isPostSaved(
      widget.post.id,
      widget.currentUserId,
    );
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSave() async {
    final postService = PostService();
    try {
      if (_isSaved) {
        await postService.unsavePost(widget.post.id, widget.currentUserId);
        setState(() {
          _isSaved = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post removed from saved')),
          );
        }
      } else {
        await postService.savePost(widget.post.id, widget.currentUserId);
        setState(() {
          _isSaved = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post saved!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _fmtCount(int n) {
    if (n <= 0) return '';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _showComments() {
    _replyingTo = null;
    _editingComment = null;
    _commentController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Comments list
                Expanded(
                  child: _localComments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to comment!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _localComments.length,
                          itemBuilder: (context, index) {
                            final comment = _localComments[index];
                            final isOwn =
                                comment.userId == widget.currentUserId;
                            final isPostOwner =
                                widget.post.leaderId == widget.currentUserId;

                            return GestureDetector(
                              onLongPress: () => _showCommentActions(
                                context,
                                comment,
                                isOwn,
                                isPostOwner,
                                setSheetState,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF6366F1),
                                      child: Text(
                                        comment.userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Reply indicator
                                          if (comment.replyToUserName != null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.reply,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Replying to @${comment.replyToUserName}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // Comment bubble
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isOwn
                                                  ? const Color(
                                                      0xFF6366F1,
                                                    ).withOpacity(0.1)
                                                  : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      comment.userName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    if (comment.isEdited) ...[
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '(edited)',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.grey[500],
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  comment.text,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Bottom row: time + reply button + like button
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              left: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  _formatTime(
                                                    comment.createdAt,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                GestureDetector(
                                                  onTap: () {
                                                    setSheetState(() {
                                                      _replyingTo = comment;
                                                      _editingComment = null;
                                                    });
                                                    setState(() {});
                                                  },
                                                  child: Text(
                                                    'Reply',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Like button
                                                GestureDetector(
                                                  onTap: () =>
                                                      _toggleCommentLike(
                                                        comment,
                                                        setSheetState,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        comment.likedBy.contains(
                                                              widget
                                                                  .currentUserId,
                                                            )
                                                            ? Icons.favorite
                                                            : Icons
                                                                  .favorite_border,
                                                        size: 14,
                                                        color:
                                                            comment.likedBy
                                                                .contains(
                                                                  widget
                                                                      .currentUserId,
                                                                )
                                                            ? Colors.red
                                                            : Colors.grey[500],
                                                      ),
                                                      if (comment.likeCount >
                                                          0) ...[
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${comment.likeCount}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Reply/Edit indicator
                if (_replyingTo != null || _editingComment != null)
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _editingComment != null ? Icons.edit : Icons.reply,
                          size: 16,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _editingComment != null
                                ? 'Editing comment'
                                : 'Replying to @${_replyingTo!.userName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              _replyingTo = null;
                              _editingComment = null;
                              _commentController.clear();
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Comment input
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
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: _editingComment != null
                                  ? 'Edit your comment...'
                                  : _replyingTo != null
                                  ? 'Reply to @${_replyingTo!.userName}...'
                                  : 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _submitComment(setSheetState),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _editingComment != null
                                  ? Icons.check
                                  : Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _submitComment(setSheetState),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentActions(
    BuildContext context,
    CommentModel comment,
    bool isOwn,
    bool isPostOwner,
    StateSetter setSheetState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              const SizedBox(height: 16),
              // Reply option (always available)
              ListTile(
                leading: const Icon(Icons.reply, color: Color(0xFF6366F1)),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setSheetState(() {
                    _replyingTo = comment;
                    _editingComment = null;
                    _commentController.clear();
                  });
                },
              ),
              // Edit option (only for own comments)
              if (isOwn)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    setSheetState(() {
                      _editingComment = comment;
                      _replyingTo = null;
                      _commentController.text = comment.text;
                    });
                  },
                ),
              // Delete option (for own comments or post owner)
              if (isOwn || isPostOwner)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteComment(comment, setSheetState);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteComment(
    CommentModel comment,
    StateSetter setSheetState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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

    if (confirmed == true) {
      try {
        final postService = PostService();
        await postService.deleteComment(
          postId: widget.post.id,
          commentId: comment.id,
          currentComments: _localComments,
        );

        setSheetState(() {
          _localComments.removeWhere((c) => c.id == comment.id);
        });
        setState(() {
          _commentCount--;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment deleted'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
        }
      }
    }
  }

  Future<void> _toggleCommentLike(
    CommentModel comment,
    StateSetter setSheetState,
  ) async {
    final postService = PostService();
    final isLiked = comment.likedBy.contains(widget.currentUserId);

    try {
      if (isLiked) {
        await postService.unlikeComment(
          postId: widget.post.id,
          commentId: comment.id,
          userId: widget.currentUserId,
          currentComments: _localComments,
        );
        setSheetState(() {
          final index = _localComments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            final newLikedBy = List<String>.from(_localComments[index].likedBy);
            newLikedBy.remove(widget.currentUserId);
            _localComments[index] = _localComments[index].copyWith(
              likedBy: newLikedBy,
            );
          }
        });
      } else {
        await postService.likeComment(
          postId: widget.post.id,
          commentId: comment.id,
          userId: widget.currentUserId,
          currentComments: _localComments,
        );
        setSheetState(() {
          final index = _localComments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            final newLikedBy = List<String>.from(_localComments[index].likedBy);
            newLikedBy.add(widget.currentUserId);
            _localComments[index] = _localComments[index].copyWith(
              likedBy: newLikedBy,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitComment(StateSetter setSheetState) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final postService = PostService();
      final authService = AuthService();
      final user = await authService.getUserById(widget.currentUserId);
      if (user == null) throw Exception('User not found');

      if (_editingComment != null) {
        // Edit existing comment
        await postService.editComment(
          postId: widget.post.id,
          commentId: _editingComment!.id,
          newText: text,
          currentComments: _localComments,
        );

        setSheetState(() {
          final index = _localComments.indexWhere(
            (c) => c.id == _editingComment!.id,
          );
          if (index != -1) {
            _localComments[index] = _localComments[index].copyWith(
              text: text,
              isEdited: true,
            );
          }
          _editingComment = null;
          _commentController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment updated!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add new comment (with or without reply)
        await postService.addCommentWithReply(
          postId: widget.post.id,
          userId: widget.currentUserId,
          userName: user.name,
          text: text,
          replyToId: _replyingTo?.id,
          replyToUserName: _replyingTo?.userName,
        );

        final newComment = CommentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: widget.currentUserId,
          userName: user.name,
          text: text,
          createdAt: DateTime.now(),
          replyToId: _replyingTo?.id,
          replyToUserName: _replyingTo?.userName,
        );

        setSheetState(() {
          _localComments.add(newComment);
          _replyingTo = null;
          _commentController.clear();
        });
        setState(() {
          _commentCount++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleLike() async {
    final postService = PostService();
    try {
      if (_isLiked) {
        await postService.unlikePost(
          postId: widget.post.id,
          userId: widget.currentUserId,
        );
        if (!mounted) return;
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 1 << 31);
        });
      } else {
        await postService.likePost(
          postId: widget.post.id,
          userId: widget.currentUserId,
        );
        if (!mounted) return;
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sharePost() async {
    try {
      String shareText =
          '${widget.post.leaderName} posted on FaithConnect:\n\n${widget.post.caption}';

      if (widget.post.imageUrl != null) {
        shareText += '\n\n📷 View image on FaithConnect';
      } else if (widget.post.videoUrl != null) {
        shareText += '\n\n🎥 Watch video on FaithConnect';
      }

      shareText +=
          '\n\n🔗 View full post: https://faithconnect.app/post/${widget.post.id}';
      shareText += '\n\nDownload FaithConnect\nhttps://faithconnect.app';

      await Share.share(shareText);
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({'shareCount': FieldValue.increment(1)});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing post: $e')));
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.post.id)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting post: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return dateTime.toLocal().toString().split(' ')[0];
    }
  }

  Widget _iconAction({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    String? countText,
    Color? color,
  }) {
    final t = tooltip;
    final btn = InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? const Color(0xFF374151)),
            if (countText != null && countText.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                countText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return t == null ? btn : Tooltip(message: t, child: btn);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final likeCountText = _fmtCount(_likeCount);
    final commentCountText = _fmtCount(_commentCount);
    final shareCount = post.shareCount;
    final shareCountText = _fmtCount(shareCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  // Avatar (fallback to gradient circle)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child:
                        post.leaderProfilePhotoUrl != null &&
                            (post.leaderProfilePhotoUrl ?? '').isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: post.leaderProfilePhotoUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              memCacheHeight: 120,
                              placeholder: (context, _) => const SizedBox(),
                              errorWidget: (context, _, __) => const Icon(
                                Icons.person,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          )
                        : const Icon(Icons.person, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.leaderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF9CA3AF),
                    ),
                    onSelected: (value) {
                      if (value == 'save') {
                        _toggleSave();
                      }
                      if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) {
                      final isOwner = post.leaderId == widget.currentUserId;
                      return [
                        PopupMenuItem<String>(
                          value: 'save',
                          child: Text(_isSaved ? 'Unsave' : 'Save'),
                        ),
                        if (isOwner)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ];
                    },
                  ),
                ],
              ),
            ),

            // Caption
            if (post.caption.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  post.caption.trim(),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

            // Image support (square, calm)
            if (post.imageUrl != null && (post.imageUrl ?? '').isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 1080,
                  placeholder: (context, _) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              ),

            // Actions (icons only, counts when > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
              child: Row(
                children: [
                  _iconAction(
                    icon: _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    onTap: _toggleLike,
                    tooltip: 'Like',
                    color: _isLiked
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF374151),
                    countText: likeCountText.isNotEmpty ? likeCountText : null,
                  ),
                  _iconAction(
                    icon: Icons.mode_comment_outlined,
                    onTap: _showComments,
                    tooltip: 'Comment',
                    countText: commentCountText.isNotEmpty
                        ? commentCountText
                        : null,
                  ),
                  _iconAction(
                    icon: Icons.ios_share_rounded,
                    onTap: _sharePost,
                    tooltip: 'Share',
                    countText: shareCountText.isNotEmpty
                        ? shareCountText
                        : null,
                  ),
                  const Spacer(),
                  _iconAction(
                    icon: _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    onTap: _toggleSave,
                    tooltip: _isSaved ? 'Saved' : 'Save',
                    color: _isSaved
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF374151),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
