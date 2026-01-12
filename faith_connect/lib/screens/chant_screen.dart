import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/gradient_theme.dart';

class ChantScreen extends StatefulWidget {
  const ChantScreen({super.key});

  @override
  State<ChantScreen> createState() => _ChantScreenState();
}

class _ChantScreenState extends State<ChantScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;

  final List<Map<String, dynamic>> _chants = [
    {
      'title': 'Om Mani Padme Hum',
      'description': 'A powerful Tibetan Buddhist mantra',
      'duration': '10 min',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Placeholder - replace with actual audio URLs
    },
    {
      'title': 'Allahu Akbar',
      'description': 'The greatness of the Creator',
      'duration': '5 min',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
    {
      'title': 'Hare Krishna',
      'description': 'Devotional chant for inner peace',
      'duration': '15 min',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    },
    {
      'title': 'Shalom',
      'description': 'Prayer for peace and harmony',
      'duration': '8 min',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    },
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(int index) async {
    try {
      if (_currentlyPlayingIndex == index) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingIndex = null;
        });
      } else {
        if (_currentlyPlayingIndex != null) {
          await _audioPlayer.stop();
        }
        await _audioPlayer.play(UrlSource(_chants[index]['audioUrl']));
        setState(() {
          _currentlyPlayingIndex = index;
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _currentlyPlayingIndex = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Chanting',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chants.length,
        itemBuilder: (context, index) {
          final chant = _chants[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: GradientTheme.cardDecoration(borderRadius: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: GradientTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chant['title']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GradientTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chant['description']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: GradientTheme.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chant['duration']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _currentlyPlayingIndex == index
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    size: 40,
                    color: GradientTheme.primaryGradient.colors[2],
                  ),
                  onPressed: () => _togglePlayback(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
