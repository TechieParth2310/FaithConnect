import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import '../widgets/daily_quote_card.dart';
import '../widgets/prayer_times_card.dart';
import '../widgets/quick_action_strip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentUserId;
  UserModel? _currentUser;
  bool _isLoading = true;

  // Explore feed state (non-realtime, paginated)
  final List<PostModel> _explorePosts = [];
  DocumentSnapshot? _exploreLastDoc;
  bool _exploreIsLoading = true;
  bool _exploreIsLoadingMore = false;
  bool _exploreHasMore = true;
  bool _exploreLoadError = false;
  final ScrollController _exploreScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUser();
    _exploreScrollController.addListener(_onExploreScroll);
  }

  Future<void> _initializeUser() async {
    try {
      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user != null) {
        final userData = await authService.getUserById(user.uid);
        setState(() {
          _currentUserId = user.uid;
          _currentUser = userData;
          _isLoading = false;
        });

        // Kick off first Explore page after we have user info.
        await _refreshExplore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _exploreScrollController.dispose();
    super.dispose();
  }

  void _onExploreScroll() {
    if (!_exploreHasMore || _exploreIsLoadingMore || _exploreIsLoading) return;
    final position = _exploreScrollController.position;
    if (!position.hasContentDimensions) return;

    // Load next page a bit before reaching the end.
    if (position.pixels > position.maxScrollExtent - 600) {
      _loadMoreExplore();
    }
  }

  Future<void> _refreshExplore() async {
    if (!mounted) return;
    setState(() {
      _exploreIsLoading = true;
      _exploreIsLoadingMore = false;
      _exploreHasMore = true;
      _exploreLastDoc = null;
      _exploreLoadError = false;
      _explorePosts.clear();
    });

    try {
      final page = await PostService().fetchExplorePostsPage(limit: 10);
      if (!mounted) return;
      setState(() {
        _explorePosts.addAll(page.posts);
        _exploreLastDoc = page.lastDoc;
        _exploreHasMore = page.posts.length >= 10 && page.lastDoc != null;
        _exploreIsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exploreIsLoading = false;
        _exploreLoadError = true;
      });
    }
  }

  Future<void> _loadMoreExplore() async {
    if (!_exploreHasMore || _exploreIsLoadingMore || _exploreLastDoc == null) {
      return;
    }

    setState(() => _exploreIsLoadingMore = true);

    try {
      final page = await PostService().fetchExplorePostsPage(
        limit: 10,
        startAfter: _exploreLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _explorePosts.addAll(page.posts);
        _exploreLastDoc = page.lastDoc;
        _exploreHasMore = page.posts.length >= 10 && page.lastDoc != null;
        _exploreIsLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _exploreIsLoadingMore = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            // ignore: use_build_context_synchronously
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'FaithConnect',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6366F1)),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Explore Tab - All Posts with Daily Quote
          _buildExploreTab(),
          // Following Tab - Following Posts (no quote)
          _buildFollowingPostsList(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return RefreshIndicator(
      onRefresh: _refreshExplore,
      child: ListView.builder(
        controller: _exploreScrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 1 + (_exploreIsLoading ? 3 : _explorePosts.length) + 1,
        itemBuilder: (context, index) {
          // Header (hero + quick actions + prayer)
          if (index == 0) {
            return Column(
              children: [
                DailyQuoteCard(
                  userFaith: _currentUser?.faith.toString().split('.').last,
                ),
                QuickActionStrip(
                  onPrayer: () {
                    // For hackathon polish, keep lightweight.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prayer coming soon')),
                    );
                  },
                  onWisdom: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wisdom coming soon')),
                    );
                  },
                  onChant: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chant coming soon')),
                    );
                  },
                  onNearby: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nearby coming soon')),
                    );
                  },
                ),
                if (_currentUser != null)
                  PrayerTimesCard(
                    faith: _currentUser!.faith.toString().split('.').last,
                  ),
              ],
            );
          }

          // Footer (loading more / end-of-feed)
          final footerIndex =
              1 + (_exploreIsLoading ? 3 : _explorePosts.length);
          if (index == footerIndex) {
            if (_exploreIsLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (_exploreLoadError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Couldn\'t refresh the feed. Pull down to try again.',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!_exploreIsLoading && _explorePosts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Your feed is quiet right now. Take a breath—new inspiration arrives soon.',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!_exploreHasMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'You\'re all caught up.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                ),
              );
            }
            return const SizedBox(height: 16);
          }

          // Skeletons while initial load
          if (_exploreIsLoading) {
            return const _ExplorePostSkeleton();
          }

          final postIndex = index - 1;
          if (postIndex < 0 || postIndex >= _explorePosts.length) {
            return const SizedBox.shrink();
          }

          return RepaintBoundary(
            child: PostCard(
              post: _explorePosts[postIndex],
              currentUserId: _currentUserId,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList({
    required Stream<List<PostModel>> stream,
    required String emptyMessage,
    bool showQuote = true,
  }) {
    return StreamBuilder<List<PostModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty && !showQuote) {
          return Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: showQuote ? posts.length + 1 : posts.length,
          itemBuilder: (context, index) {
            // Show Daily Quote Card at the top of Explore tab
            if (showQuote && index == 0) {
              return Column(
                children: [
                  const DailyQuoteCard(),
                  if (_currentUser != null)
                    PrayerTimesCard(
                      faith: _currentUser!.faith.toString().split('.').last,
                    ),
                  if (posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            }

            // Adjust index for posts (skip the quote card)
            final postIndex = showQuote ? index - 1 : index;
            if (postIndex >= posts.length) return const SizedBox.shrink();

            return RepaintBoundary(
              child: PostCard(
                post: posts[postIndex],
                currentUserId: _currentUserId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingPostsList() {
    return FutureBuilder<UserModel?>(
      future: _getUserData(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final followingIds = userSnapshot.data?.following ?? [];

        if (followingIds.isEmpty) {
          return const Center(
            child: Text(
              'No leaders followed yet. Explore to find leaders!',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
          );
        }

        return _buildPostsList(
          stream: PostService().getFollowingPostsStream(followingIds),
          emptyMessage: 'No posts from leaders you follow yet.',
          showQuote: false,
        );
      },
    );
  }

  Future<UserModel?> _getUserData() async {
    try {
      return await AuthService().getUserById(_currentUserId);
    } catch (e) {
      return null;
    }
  }
}

class _ExplorePostSkeleton extends StatelessWidget {
  const _ExplorePostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            width: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
