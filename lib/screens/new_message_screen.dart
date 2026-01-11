import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'chat_detail_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final AuthService _authService = AuthService();
  final MessageService _messageService = MessageService();

  List<UserModel> _availableUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final currentUserData = await _authService.getUserById(currentUser.uid);
      if (currentUserData == null) return;

      List<UserModel> users = [];

      if (currentUserData.role == UserRole.worshiper) {
        // Worshippers can message leaders they follow
        final followingIds = currentUserData.following;

        if (followingIds.isNotEmpty) {
          // Get leader details
          for (String leaderId in followingIds) {
            final leaderData = await _authService.getUserById(leaderId);
            if (leaderData != null) {
              users.add(leaderData);
            }
          }
        }
      } else if (currentUserData.role == UserRole.religiousLeader) {
        // Leaders can message their followers AND other leaders

        // Get followers
        final followerIds = currentUserData.followers;
        if (followerIds.isNotEmpty) {
          for (String followerId in followerIds) {
            final followerData = await _authService.getUserById(followerId);
            if (followerData != null) {
              users.add(followerData);
            }
          }
        }

        // Also get all other leaders
        final allUsers = await _authService.getAllUsers();
        for (var user in allUsers) {
          if (user.role == UserRole.religiousLeader &&
              user.id != currentUser.uid &&
              !users.any((u) => u.id == user.id)) {
            users.add(user);
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _availableUsers;
      } else {
        _filteredUsers = _availableUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _startConversation(UserModel user) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Create or get existing conversation
      final chatId = await _messageService.getOrCreateConversation(
        currentUser.uid,
        user.id,
      );

      // Navigate to conversation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              currentUserId: currentUser.uid,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to continue')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Message',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserTile(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserById(_authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final isWorshipper = snapshot.data?.role == UserRole.worshiper;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWorshipper ? Icons.people_outline : Icons.group_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isWorshipper ? 'No Leaders to Message' : 'No Followers Yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isWorshipper
                      ? 'Follow religious leaders to start messaging them'
                      : 'When worshippers follow you, you can message them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                if (isWorshipper)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to Leaders tab
                      DefaultTabController.of(context).animateTo(2);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find Leaders'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage:
            user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
            ? NetworkImage(user.profilePhotoUrl!)
            : null,
        child: user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          if (user.role == UserRole.religiousLeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Leader',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        user.faith.toString().split('.').last.toUpperCase(),
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, color: Color(0xFF6366F1), size: 20),
      ),
      onTap: () => _startConversation(user),
    );
  }
}
