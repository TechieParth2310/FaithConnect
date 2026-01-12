import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final String currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _markAsViewed();
  }

  void _markAsViewed() {
    if (_currentIndex < widget.stories.length) {
      final story = widget.stories[_currentIndex];
      _storyService.viewStory(story.id, widget.currentUserId);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _markAsViewed();
        },
        itemBuilder: (context, index) {
          return _buildStoryPage(widget.stories[index]);
        },
      ),
    );
  }

  Widget _buildStoryPage(StoryModel story) {
    return Stack(
      children: [
        // Story Content
        Center(
          child: story.mediaType == 'image'
              ? Image.network(
                  story.mediaUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                )
              : const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
        ),

        // Top Gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),

        // Progress Indicators
        Positioned(
          top: 40,
          left: 8,
          right: 8,
          child: Row(
            children: List.generate(
              widget.stories.length,
              (index) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Story Header
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple,
                backgroundImage: story.userPhotoUrl != null
                    ? NetworkImage(story.userPhotoUrl!)
                    : null,
                child: story.userPhotoUrl == null
                    ? Text(
                        story.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      story.timeRemainingText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Caption
        if (story.caption != null && story.caption!.isNotEmpty)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                story.caption!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

        // View Count
        Positioned(
          bottom: 20,
          left: 16,
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                '${story.viewCount} views',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),

        // Navigation Zones
        Row(
          children: [
            // Previous story
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_currentIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            // Next story
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_currentIndex < widget.stories.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
