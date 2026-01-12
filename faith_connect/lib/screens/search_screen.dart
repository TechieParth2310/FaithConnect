import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/search_service.dart';
import '../services/auth_service.dart';
import '../widgets/post_card.dart';
import '../widgets/notification_bell.dart';
import '../utils/gradient_theme.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  late String _currentUserId;

  List<UserModel> _leaderResults = [];
  List<PostModel> _postResults = [];
  List<String> _trendingHashtags = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUser();
    _loadTrendingHashtags();
  }

  Future<void> _initializeUser() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _isLoading = false;
      });
      _loadSearchHistory();
    }
  }

  Future<void> _loadTrendingHashtags() async {
    final hashtags = await _searchService.getTrendingHashtags(limit: 10);
    if (mounted) {
      setState(() {
        _trendingHashtags = hashtags;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchService.getSearchHistory(_currentUserId);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _leaderResults = [];
        _postResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    // Save to search history
    await _searchService.saveSearchHistory(_currentUserId, query);

    if (query.startsWith('#')) {
      // Search by hashtag
      final posts = await _searchService.searchPostsByHashtag(query);
      if (mounted) {
        setState(() {
          _postResults = posts;
          _leaderResults = [];
          _tabController.index = 1; // Switch to Posts tab
        });
      }
    } else {
      // Search leaders and posts
      final leaders = await _searchService.searchLeaders(query);
      final posts = await _searchService.searchPosts(query);

      if (mounted) {
        setState(() {
          _leaderResults = leaders;
          _postResults = posts;
        });
      }
    }

    _loadSearchHistory();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _leaderResults = [];
      _postResults = [];
    });
  }

  Future<void> _clearSearchHistory() async {
    await _searchService.clearSearchHistory(_currentUserId);
    _loadSearchHistory();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Search history cleared')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _performSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search leaders, posts, #hashtags...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.9)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.9)),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        actions: const [
          NotificationBell(iconColor: Colors.white),
        ],
        bottom: _isSearching
            ? TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF9CA3AF),
                indicatorColor: const Color(0xFF6366F1),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 18),
                        const SizedBox(width: 4),
                        Text('Leaders (${_leaderResults.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article, size: 18),
                        const SizedBox(width: 4),
                        Text('Posts (${_postResults.length})'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: _isSearching
          ? TabBarView(
              controller: _tabController,
              children: [_buildLeadersResults(), _buildPostsResults()],
            )
          : _buildDiscoverContent(),
    );
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Hashtags Section
          if (_trendingHashtags.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending Hashtags',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange.shade400,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingHashtags.map((hashtag) {
                return InkWell(
                  onTap: () {
                    _searchController.text = hashtag;
                    _performSearch(hashtag);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      hashtag,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Search History Section
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._searchHistory.map((query) {
              return ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF9CA3AF)),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west, size: 18),
                  onPressed: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            }),
          ],

          // Search Tips
          if (!_isSearching && _searchHistory.isEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.search, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Discover FaithConnect',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for religious leaders, spiritual posts,\nor explore trending hashtags',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeadersResults() {
    if (_leaderResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No leaders found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderResults.length,
      itemBuilder: (context, index) {
        final leader = _leaderResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF6366F1),
              backgroundImage: leader.profilePhotoUrl != null
                  ? NetworkImage(leader.profilePhotoUrl!)
                  : null,
              child: leader.profilePhotoUrl == null
                  ? Text(
                      leader.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            title: Text(
              leader.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  leader.faith.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (leader.bio != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    leader.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsResults() {
    if (_postResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No posts found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: _postResults[index],
          currentUserId: _currentUserId,
        );
      },
    );
  }
}
