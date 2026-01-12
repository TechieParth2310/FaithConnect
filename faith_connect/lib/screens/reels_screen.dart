import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../models/reel_model.dart';
import '../models/user_model.dart';
import '../services/reel_service.dart';
import '../services/auth_service.dart';
import '../widgets/notification_bell.dart';

class ReelsScreen extends StatefulWidget {
  final Function(Function(bool))? onSetActiveCallback;

  const ReelsScreen({super.key, this.onSetActiveCallback});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final ReelService _reelService = ReelService();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();

  List<ReelModel> _reels = [];
  VideoPlayerController? _activeController;
  String? _activeReelId;
  int _initToken = 0; // Monotonic token to prevent overlapping init/play
  final Map<String, UserModel> _authors = {};
  // Following state is now centralized in FollowButton/FollowService.
  final Set<String> _viewedReels = {}; // Track which reels have been viewed
  StreamSubscription<List<ReelModel>>?
  _reelsSubscription; // CRITICAL: Must cancel
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isActive = true; // Track if this screen is visible - START AS ACTIVE
  bool _isDisposing = false; // Prevent operations during disposal
  bool _showVolumeIndicator = false; // Show volume icon animation
  Timer? _volumeIndicatorTimer; // Timer to hide volume indicator

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Register the setActive callback with parent
    widget.onSetActiveCallback?.call(setActive);
    _loadReels();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposing) return;

    // Pause videos when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseAllVideos();
    } else if (state == AppLifecycleState.resumed && _isActive) {
      // Resume current video only if screen is active
      _resumeCurrentVideo();
    }
  }

  // Called from MainWrapper when tab changes
  void setActive(bool active) {
    if (_isActive == active || _isDisposing) return;

    setState(() => _isActive = active);

    if (!active) {
      // Pause all videos when tab switched away
      _pauseAllVideos();
    } else if (_reels.isNotEmpty && _currentIndex < _reels.length) {
      // Resume current video when tab switched back
      _resumeCurrentVideo();
    }
  }

  void _pauseAllVideos() {
    if (_isDisposing) return;

    final controller = _activeController;
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
      // Seek to stop pipeline work as much as possible
      controller.seekTo(Duration.zero);
    }
  }

  void _resumeCurrentVideo() {
    if (_isDisposing) return;

    if (_currentIndex >= 0 && _currentIndex < _reels.length) {
      final controller = _activeController;
      if (controller != null &&
          controller.value.isInitialized &&
          !controller.value.isPlaying) {
        controller.play();
      }
    }
  }

  Future<void> _loadReels() async {
    // CRITICAL: Store subscription so we can cancel it
    // OPTIMIZED: Load 10 reels with smart preloading for smooth scrolling
    _reelsSubscription = _reelService.getReelsStream(limit: 10).listen((reels) {
      if (mounted && !_isDisposing) {
        print('📹 Loaded ${reels.length} reels from Firestore');
        if (reels.isNotEmpty) {
          print('📹 First reel URL: ${reels.first.videoUrl}');
        }
        setState(() {
          _reels = reels;
          _isLoading = false;
        });
        // Always initialize first video when reels are loaded
        if (_reels.isNotEmpty) {
          _initializeVideoPlayer(_currentIndex);
        } else {
          print('⚠️ No reels available in Firestore');
        }
      }
    });
  }

  Future<void> _refreshReels() async {
    // Dispose active controller
    try {
      await _disposeActiveController();
    } catch (_) {
      // Best-effort
    }

    _authors.clear();
    _viewedReels.clear();

    // Reset to first reel
    setState(() {
      _currentIndex = 0;
      _isLoading = true;
    });

    // Cancel old subscription
    await _reelsSubscription?.cancel();

    // Reload reels
    await _loadReels();

    // Small delay to let UI update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _initializeVideoPlayer(int index) async {
    if (index >= _reels.length || _isDisposing) return;

    // Prevent overlapping init/play when user scrolls quickly
    final int token = ++_initToken;
    final reel = _reels[index];

    // If the same reel is already active and initialized, just ensure it's playing.
    if (_activeReelId == reel.id && _activeController != null) {
      final controller = _activeController!;
      if (controller.value.isInitialized &&
          _isActive &&
          _currentIndex == index &&
          !_isDisposing) {
        controller.play();
      }
      return;
    }

    final userId = _authService.currentUser?.uid;

    // Load author info and following status in parallel (don't wait for it)
    if (!_authors.containsKey(reel.authorId)) {
      _authService.getUserById(reel.authorId).then((author) {
        if (!_isDisposing && mounted) {
          setState(() {
            if (author != null) {
              _authors[reel.authorId] = author;
            }
          });
        }
      });
    }

    // Following state is derived via streams in FollowButton.

    // Dispose the previous controller BEFORE creating a new one
    await _disposeActiveController();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(reel.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    print('🎬 Initializing video for reel ${reel.id}');

    try {
      await controller.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );
      print('✅ Video initialized successfully!');
    } catch (e) {
      if (!_isDisposing) {
        print('❌ Error initializing video: $e');
      }
      // Best-effort cleanup
      try {
        await controller.dispose();
      } catch (_) {}
      return;
    }

    // If a newer init started, dispose this controller and stop.
    if (_isDisposing || token != _initToken) {
      await controller.dispose();
      return;
    }

    // Install as active IMMEDIATELY
    _activeController = controller;
    _activeReelId = reel.id;

    // Configure controller
    controller.setLooping(true);
    controller.setVolume(0.0); // Mute by default
    controller.setPlaybackSpeed(1.0);

    // Add listener to update UI when video state changes
    controller.addListener(() {
      if (mounted &&
          !_isDisposing &&
          identical(_activeController, controller)) {
        setState(() {});
      }
    });

    // Update UI immediately
    if (mounted && !_isDisposing && token == _initToken) {
      setState(() {});
    }

    // START PLAYING IMMEDIATELY (continuous play like Instagram)
    if (_isActive &&
        _currentIndex == index &&
        !_isDisposing &&
        token == _initToken) {
      controller.play();
      print('▶️ Video playing!');
    }

    // Increment view count ONCE per reel (async, don't wait)
    if (userId != null && !_viewedReels.contains(reel.id)) {
      _viewedReels.add(reel.id);
      _reelService.incrementViewCount(reel.id, userId);
    }
  }

  Future<void> _disposeActiveController() async {
    final controller = _activeController;
    if (controller == null) return;

    try {
      if (controller.value.isInitialized) {
        await controller.pause();
        await controller.seekTo(Duration.zero);
      }
    } catch (_) {
      // Best-effort
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Best-effort
    }

    _activeController = null;
    _activeReelId = null;
  }

  Future<void> _toggleLike(ReelModel reel) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    if (reel.likes.contains(userId)) {
      await _reelService.unlikeReel(reel.id, userId);
    } else {
      await _reelService.likeReel(reel.id, userId);
    }
  }

  // Follow/unfollow is handled via FollowButton to ensure global consistency.

  @override
  void dispose() {
    _isDisposing = true; // Set flag immediately

    WidgetsBinding.instance.removeObserver(this);

    // Cancel timers
    _volumeIndicatorTimer?.cancel();

    // Cancel stream subscription FIRST
    _reelsSubscription?.cancel();

    // Pause all videos
    _pauseAllVideos();

    // Dispose active controller
    try {
      _activeController?.dispose();
    } catch (_) {
      // Ignore disposal errors
    }
    _activeController = null;
    _activeReelId = null;

    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_reels.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No reels yet',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reels from leaders will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reels',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          const NotificationBell(iconColor: Colors.white),
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshReels,
            tooltip: 'Refresh reels',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReels,
        color: const Color(0xFF6366F1),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _reels.length,
          onPageChanged: (index) {
            if (_isDisposing) return;

            // Bump token immediately so any in-flight init knows it's obsolete.
            _initToken++;

            setState(() {
              _currentIndex = index;
            });

            // THEN initialize and play new video (after cleanup)
            _initializeVideoPlayer(index);
          },
          itemBuilder: (context, index) {
            final reel = _reels[index];
            final controller = (_activeReelId == reel.id)
                ? _activeController
                : null;
            final author = _authors[reel.authorId];
            final currentUserId = _authService.currentUser?.uid;
            final isLiked =
                currentUserId != null && reel.likes.contains(currentUserId);

            // Only show video if this is the current index
            final isCurrentReel = index == _currentIndex;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Background color while loading
                Container(color: Colors.black),

                // Video Player with tap-to-mute (Instagram style)
                if (controller != null && isCurrentReel) ...[
                  if (controller.value.isInitialized)
                    GestureDetector(
                      onTap: () {
                        if (_isDisposing) return;
                        setState(() {
                          final newVolume = controller.value.volume > 0
                              ? 0.0
                              : 1.0;
                          controller.setVolume(newVolume);

                          // Show volume indicator
                          _showVolumeIndicator = true;
                          _volumeIndicatorTimer?.cancel();
                          _volumeIndicatorTimer = Timer(
                            const Duration(milliseconds: 800),
                            () {
                              if (mounted && !_isDisposing) {
                                setState(() {
                                  _showVolumeIndicator = false;
                                });
                              }
                            },
                          );
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.size.width,
                              height: controller.value.size.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                          // Center volume icon indicator
                          if (_showVolumeIndicator)
                            Center(
                              child: AnimatedOpacity(
                                opacity: _showVolumeIndicator ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    controller.value.volume > 0
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Show buffering indicator
                  if (controller.value.isBuffering)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                  // Loading indicator (while video is initializing)
                  if (!controller.value.isInitialized)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],

                // Error state
                if (controller != null &&
                    controller.value.isInitialized &&
                    controller.value.hasError &&
                    isCurrentReel)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load video',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // Retry loading
                              _initializeVideoPlayer(_currentIndex);
                            },
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Default loading state (no controller yet or not current reel)
                if ((controller == null || !isCurrentReel) && isCurrentReel)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // Gradient Overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right Side Actions
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: Column(
                    children: [
                      // Like Button
                      _ActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        iconColor: isLiked ? Colors.red : Colors.white,
                        label: _formatCount(reel.likeCount),
                        onTap: () => _toggleLike(reel),
                      ),
                      const SizedBox(height: 20),

                      // Comment Button (Instagram style)
                      _ActionButton(
                        icon: Icons.mode_comment_outlined,
                        label: _formatCount(reel.commentCount),
                        onTap: () => _showComments(context, reel),
                      ),
                      const SizedBox(height: 20),

                      // Share Button (Instagram style - paper plane icon)
                      _ActionButton(
                        icon: Icons.send_outlined,
                        label: 'Share',
                        onTap: () => _shareReel(reel),
                      ),
                      const SizedBox(height: 20),

                      // Views (Instagram style with eye icon)
                      Column(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCount(reel.viewCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Info
                Positioned(
                  left: 16,
                  right: 80,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Info (no follow button in reels overlay)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: author?.profilePhotoUrl != null
                                ? NetworkImage(author!.profilePhotoUrl!)
                                : null,
                            child: author?.profilePhotoUrl == null
                                ? Text(
                                    (author?.name ?? 'L')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              author?.name ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Caption
                      Text(
                        reel.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Hashtags
                      if (reel.hashtags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: reel.hashtags.take(3).map((hashtag) {
                            return Text(
                              '#$hashtag',
                              style: const TextStyle(
                                color: Color(0xFF4FB5FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ), // Close RefreshIndicator
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showComments(BuildContext context, ReelModel reel) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => ReelCommentsSheet(
        reel: reel,
        userId: userId,
        reelService: _reelService,
        authService: _authService,
      ),
    );
  }

  void _shareReel(ReelModel reel) async {
    try {
      final author = _authors[reel.authorId];
      String shareText =
          '${author?.name ?? "Someone"} shared a reel on FaithConnect!\n\n';

      if (reel.caption.isNotEmpty) {
        shareText += '${reel.caption}\n\n';
      }

      shareText +=
          '🎥 ${_formatCount(reel.viewCount)} views • ${_formatCount(reel.likes.length)} likes\n\n';

      // Add deep link to the reel
      shareText += '🔗 Watch now: https://faithconnect.app/reel/${reel.id}\n\n';
      shareText +=
          'Download FaithConnect - The Multi-Faith Social Platform\nhttps://faithconnect.app';

      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing reel: $e')));
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for comments to avoid rebuilds and memory leaks
class ReelCommentsSheet extends StatefulWidget {
  final ReelModel reel;
  final String userId;
  final ReelService reelService;
  final AuthService authService;

  const ReelCommentsSheet({
    super.key,
    required this.reel,
    required this.userId,
    required this.reelService,
    required this.authService,
  });

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  Map<String, dynamic>? _replyingTo;
  Map<String, dynamic>? _editingComment;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final user = await widget.authService.getUserById(widget.userId);
      if (user != null) {
        if (_editingComment != null) {
          // Edit existing comment
          await widget.reelService.editComment(
            reelId: widget.reel.id,
            commentId: _editingComment!['id'],
            newText: text,
          );
          setState(() {
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
          await widget.reelService.addCommentWithReply(
            reelId: widget.reel.id,
            userId: widget.userId,
            userName: user.name,
            text: text,
            replyToId: _replyingTo?['id'],
            replyToUserName: _replyingTo?['userName'],
          );
          setState(() {
            _replyingTo = null;
            _commentController.clear();
          });
        }
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showCommentActions(BuildContext context, Map<String, dynamic> comment) {
    final isOwn = comment['userId'] == widget.userId;
    final isReelOwner = widget.reel.authorId == widget.userId;

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
              // Reply option
              ListTile(
                leading: const Icon(Icons.reply, color: Color(0xFF6366F1)),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
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
                    setState(() {
                      _editingComment = comment;
                      _replyingTo = null;
                      _commentController.text = comment['text'] ?? '';
                    });
                  },
                ),
              // Delete option (for own comments or reel owner)
              if (isOwn || isReelOwner)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteComment(comment);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteComment(Map<String, dynamic> comment) async {
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
        await widget.reelService.deleteComment(
          reelId: widget.reel.id,
          commentId: comment['id'],
        );
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

  Future<void> _toggleCommentLike(Map<String, dynamic> comment) async {
    final likedBy = List<String>.from(comment['likedBy'] ?? []);
    final isLiked = likedBy.contains(widget.userId);

    try {
      if (isLiked) {
        await widget.reelService.unlikeComment(
          reelId: widget.reel.id,
          commentId: comment['id'],
          userId: widget.userId,
        );
      } else {
        await widget.reelService.likeComment(
          reelId: widget.reel.id,
          commentId: comment['id'],
          userId: widget.userId,
        );
      }
      // The StreamBuilder will automatically update the UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatCommentTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = timestamp.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 7).floor()}w ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.reelService.getCommentsStream(widget.reel.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return Center(
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
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isOwn = comment['userId'] == widget.userId;

                      return GestureDetector(
                        onLongPress: () =>
                            _showCommentActions(context, comment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF6366F1),
                                child: Text(
                                  (comment['userName'] ?? 'U')[0].toUpperCase(),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Reply indicator
                                    if (comment['replyToUserName'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              'Replying to @${comment['replyToUserName']}',
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment['userName'] ??
                                                    'Anonymous',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (comment['isEdited'] ==
                                                  true) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(edited)',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            comment['text'] ?? '',
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
                                            _formatCommentTime(
                                              comment['createdAt'],
                                            ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _replyingTo = comment;
                                                _editingComment = null;
                                              });
                                            },
                                            child: Text(
                                              'Reply',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          // Like button
                                          GestureDetector(
                                            onTap: () =>
                                                _toggleCommentLike(comment),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  (comment['likedBy'] as List?)
                                                              ?.contains(
                                                                widget.userId,
                                                              ) ==
                                                          true
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 14,
                                                  color:
                                                      (comment['likedBy']
                                                                  as List?)
                                                              ?.contains(
                                                                widget.userId,
                                                              ) ==
                                                          true
                                                      ? Colors.red
                                                      : Colors.grey[500],
                                                ),
                                                if ((comment['likedBy']
                                                            as List?)
                                                        ?.isNotEmpty ==
                                                    true) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${(comment['likedBy'] as List).length}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
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
                            : 'Replying to @${_replyingTo!['userName']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
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
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: _editingComment != null
                              ? 'Edit your comment...'
                              : _replyingTo != null
                              ? 'Reply to @${_replyingTo!['userName']}...'
                              : 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey[300]!),
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
                        onSubmitted: (_) => _sendComment(),
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
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                _editingComment != null
                                    ? Icons.check
                                    : Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _sendComment,
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
