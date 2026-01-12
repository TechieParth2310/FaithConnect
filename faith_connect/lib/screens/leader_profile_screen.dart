import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/index.dart';
import '../models/reel_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/reel_service.dart';
import '../utils/gradient_theme.dart';
import '../widgets/follow_button.dart';
import '../widgets/post_card.dart';
import '../widgets/profile_header.dart';
import 'followers_screen.dart';
import 'chat_detail_screen.dart';

/// Leader Profile
/// - Calm header with leader identity
/// - Follow + Message actions (message only here, not in lists)
/// - Sticky tabs: Posts / Reels
class LeaderProfileScreen extends StatefulWidget {
  final String leaderId;

  const LeaderProfileScreen({super.key, required this.leaderId});

  @override
  State<LeaderProfileScreen> createState() => _LeaderProfileScreenState();
}

class _LeaderProfileScreenState extends State<LeaderProfileScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final ReelService _reelService = ReelService();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUser()?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;

    return FutureBuilder<UserModel?>(
      future: _authService.getUserById(widget.leaderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: GradientTheme.softBackground,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
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
              title: const Text('User'),
            ),
            body: const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          );
        }

        // Check if user is a leader
        if (user.role != UserRole.religiousLeader) {
          // Show worshiper profile view (simpler, no posts/reels tabs)
          final faithLabel = faithTypeToString(user.faith);
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
              title: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  WorshipperProfileHeader(
                    photoUrl: user.profilePhotoUrl,
                    name: user.name,
                    faithLabel: faithLabel,
                    followingCount: user.following.length,
                  ),
                  const SizedBox(height: 20),
                  // Message button
                  if (currentUserId != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final ids = <String>[currentUserId, user.id]..sort();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chatId: ids.join('_'),
                                  currentUserId: currentUserId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message_outlined, size: 20),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF111827),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        final leader = user;
        final faithLabel = leader.faith.toString().split('.').last;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: GradientTheme.softBackground,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: GradientTheme.primaryGradient,
                      ),
                    ),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    title: Text(
                      leader.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LeaderProfileHeader(
                            photoUrl: leader.profilePhotoUrl,
                            name: leader.name,
                            faithLabel: faithLabel.toUpperCase(),
                            followersCount: leader.followers.length,
                            onFollowersTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FollowersScreen(leaderId: leader.id),
                                ),
                              );
                            },
                            // Optional leader-only stats (wire real counts below).
                            postsCount: null,
                            reelsCount: null,
                          ),

                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                if (currentUserId != null) ...[
                                  Expanded(
                                    child: FollowButton(
                                      worshipperId: currentUserId,
                                      leaderId: leader.id,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final ids = <String>[
                                            currentUserId,
                                            leader.id,
                                          ]..sort();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatDetailScreen(
                                                chatId: ids.join('_'),
                                                currentUserId: currentUserId,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.message_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Message'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF111827,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const Expanded(
                                    child: Text(
                                      'Sign in to follow or message',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverPersistentHeader(
                    pinned: true,
                    delegate: _LeaderProfileTabBarDelegate(),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _PostsTab(
                    leaderId: leader.id,
                    postService: _postService,
                    currentUserId: currentUserId ?? leader.id,
                  ),
                  _ReelsTab(leaderId: leader.id, reelService: _reelService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeaderProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _LeaderProfileTabBarDelegate();

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const TabBar(
        labelColor: Color(0xFF111827),
        unselectedLabelColor: Color(0xFF9CA3AF),
        indicatorColor: Color(0xFF6366F1),
        indicatorWeight: 3,
        tabs: [
          Tab(text: 'Posts'),
          Tab(text: 'Reels'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _PostsTab extends StatelessWidget {
  final String leaderId;
  final PostService postService;
  final String currentUserId;

  const _PostsTab({
    required this.leaderId,
    required this.postService,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: postService.getLeaderPostsStream(leaderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const Center(
            child: Text(
              'No posts yet',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return PostCard(post: posts[index], currentUserId: currentUserId);
          },
        );
      },
    );
  }
}

class _ReelsTab extends StatelessWidget {
  final String leaderId;
  final ReelService reelService;

  const _ReelsTab({required this.leaderId, required this.reelService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReelModel>>(
      stream: reelService.getUserReelsStream(leaderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reels = snapshot.data ?? [];
        if (reels.isEmpty) {
          return const Center(
            child: Text(
              'No reels yet',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }

        // Calm grid of reel thumbnails. Tap to play.
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            final thumb = (reel.thumbnailUrl ?? '').trim();
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _ReelPlaybackScreen(reels: reels, initialIndex: index),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFFE5E7EB),
                      child: thumb.isNotEmpty
                          ? Image.network(thumb, fit: BoxFit.cover)
                          : const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Color(0xFF9CA3AF),
                                size: 30,
                              ),
                            ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReelPlaybackScreen extends StatefulWidget {
  final List<ReelModel> reels;
  final int initialIndex;

  const _ReelPlaybackScreen({required this.reels, required this.initialIndex});

  @override
  State<_ReelPlaybackScreen> createState() => _ReelPlaybackScreenState();
}

class _ReelPlaybackScreenState extends State<_ReelPlaybackScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Reels'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.reels.length,
        itemBuilder: (context, index) {
          final reel = widget.reels[index];
          return _SingleReelPlayer(reel: reel);
        },
      ),
    );
  }
}

class _SingleReelPlayer extends StatefulWidget {
  final ReelModel reel;

  const _SingleReelPlayer({required this.reel});

  @override
  State<_SingleReelPlayer> createState() => _SingleReelPlayerState();
}

class _SingleReelPlayerState extends State<_SingleReelPlayer> {
  VideoPlayerController? _videoController;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      _videoController = controller;
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(1.0);

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Could not load this reel',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.reel.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    final c = _videoController;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: Text(
          'Reel unavailable',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          // subtle play/pause affordance
          Align(
            alignment: Alignment.center,
            child: AnimatedOpacity(
              opacity: c.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
          // caption footer
          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: Text(
              widget.reel.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
