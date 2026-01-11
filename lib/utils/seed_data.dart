import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SeedData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sample test videos (short, reliable URLs from public sources)
  static final List<Map<String, dynamic>> _sampleReels = [
    {
      'videoUrl':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'caption': '🙏 Daily Prayer & Meditation | Find peace in God\'s presence',
      'thumbnailUrl': 'https://i.pravatar.cc/400?img=1',
      'hashtags': ['prayer', 'meditation', 'faith', 'peace'],
    },
    {
      'videoUrl':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'caption': '✝️ Sunday Service Highlights | Powerful message about hope',
      'thumbnailUrl': 'https://i.pravatar.cc/400?img=2',
      'hashtags': ['worship', 'sunday', 'church', 'hope'],
    },
    {
      'videoUrl':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'caption': '🕉️ Ancient Wisdom | Teachings for modern life',
      'thumbnailUrl': 'https://i.pravatar.cc/400?img=3',
      'hashtags': ['wisdom', 'teaching', 'spirituality'],
    },
  ];

  // Sample leader data organized by faith
  static final List<Map<String, dynamic>> _sampleLeaders = [
    // Christianity Leaders (5)
    {
      'email': 'pastor.john@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Pastor John Williams',
      'role': 'leader',
      'faith': 'Christianity',
      'bio':
          '🙏 Senior Pastor at Grace Community Church | Spreading the love of Christ | Daily devotionals & sermons | Matthew 5:16',
      'profilePhoto': 'https://i.pravatar.cc/300?img=12',
      'posts': [
        {
          'caption':
              '🌅 Good morning! "Let your light shine before others, that they may see your good deeds and glorify your Father in heaven." - Matthew 5:16\n\nStart your day with gratitude and purpose. God bless you all! 🙏✨',
          'type': 'text',
        },
        {
          'caption':
              '📖 Sunday Service Reminder: Join us this Sunday at 10 AM for an inspiring message about Faith & Perseverance. Bring your family and friends! 🏛️💒',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'sister.mary@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Sister Mary Thompson',
      'role': 'leader',
      'faith': 'Christianity',
      'bio':
          '✝️ Catholic Nun | Prayer Warrior | Sharing God\'s Word daily | "Be still and know that I am God" - Psalm 46:10',
      'profilePhoto': 'https://i.pravatar.cc/300?img=47',
      'posts': [
        {
          'caption':
              '🕊️ Prayer for Today: Heavenly Father, guide us through this day with Your wisdom and grace. Help us to be instruments of Your peace. Amen. 🙏💙',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'rev.david@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Reverend David Smith',
      'role': 'leader',
      'faith': 'Christianity',
      'bio':
          '⛪ Methodist Minister | 20+ years serving the community | Marriage counselor | Spreading hope through scripture',
      'profilePhoto': 'https://i.pravatar.cc/300?img=33',
      'posts': [
        {
          'caption':
              '❤️ "Love is patient, love is kind. It does not envy, it does not boast..." - 1 Corinthians 13:4\n\nIn a world of chaos, choose love. Choose kindness. Choose faith. 💕🙏',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'bishop.michael@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Bishop Michael Brown',
      'role': 'leader',
      'faith': 'Christianity',
      'bio':
          '👑 Episcopal Bishop | Teacher of the Word | Youth ministry advocate | "Train up a child in the way he should go"',
      'profilePhoto': 'https://i.pravatar.cc/300?img=51',
      'posts': [
        {
          'caption':
              '🎯 This week\'s focus: FAITH IN ACTION\n\nJames 2:17 - "Faith by itself, if it is not accompanied by action, is dead."\n\nLet\'s serve our community with love! 💪🙏',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'pastor.sarah@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Pastor Sarah Johnson',
      'role': 'leader',
      'faith': 'Christianity',
      'bio':
          '🌟 Worship Leader & Pastor | Contemporary Christian music | Inspiring the next generation | Psalm 150:6',
      'profilePhoto': 'https://i.pravatar.cc/300?img=45',
      'posts': [
        {
          'caption':
              '🎵 "Let everything that has breath praise the Lord!" - Psalm 150:6\n\nJoin us for worship night this Friday! Bring your voice and your heart. 🎶✨',
          'type': 'text',
        },
      ],
    },

    // Islam Leaders (5)
    {
      'email': 'imam.ahmed@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Imam Ahmed Al-Hassan',
      'role': 'leader',
      'faith': 'Islam',
      'bio':
          '☪️ Imam at Central Mosque | Quran teacher | Islamic scholar | Guiding the Ummah with compassion | "Indeed, Allah is with the patient"',
      'profilePhoto': 'https://i.pravatar.cc/300?img=60',
      'posts': [
        {
          'caption':
              '🕌 Assalamu Alaikum!\n\n"And whoever puts their trust in Allah, He alone is sufficient for them." - Quran 65:3\n\nTrust in Allah\'s plan always. May peace be upon you all. 🤲',
          'type': 'text',
        },
        {
          'caption':
              '📿 Reminder: The five daily prayers are the pillars of our faith. Make time for Salah today. Allah is waiting to hear from you. ☪️🙏',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'sheikh.omar@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Sheikh Omar Abdullah',
      'role': 'leader',
      'faith': 'Islam',
      'bio':
          '📖 Islamic Scholar | Hadith specialist | Teaching Quran and Sunnah | "The best among you are those who learn the Quran"',
      'profilePhoto': 'https://i.pravatar.cc/300?img=13',
      'posts': [
        {
          'caption':
              '🌙 Hadith of the Day:\n\n"The best charity is that given in Ramadan." - Prophet Muhammad (PBUH)\n\nLet us prepare our hearts for the blessed month ahead. 💚',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'ustadh.ibrahim@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Ustadh Ibrahim Malik',
      'role': 'leader',
      'faith': 'Islam',
      'bio':
          '🌟 Quran reciter | Youth mentor | Spreading the message of peace | "Read in the name of your Lord" - Quran 96:1',
      'profilePhoto': 'https://i.pravatar.cc/300?img=68',
      'posts': [
        {
          'caption':
              '✨ "Indeed, the best speech is the Book of Allah, and the best guidance is the guidance of Muhammad (PBUH)."\n\nJoin our Quran study circle every Thursday evening! 📚☪️',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'sister.fatima@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Sister Fatima Rahman',
      'role': 'leader',
      'faith': 'Islam',
      'bio':
          '👩‍🏫 Islamic educator for women | Hijab & modesty advocate | Mother of 3 | "And say: My Lord, increase me in knowledge"',
      'profilePhoto': 'https://i.pravatar.cc/300?img=44',
      'posts': [
        {
          'caption':
              '💎 Sisters, remember: Your hijab is your crown, your modesty is your strength, and your faith is your beauty. Stay strong! 💪✨',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'mufti.yusuf@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Mufti Yusuf Ibrahim',
      'role': 'leader',
      'faith': 'Islam',
      'bio':
          '⚖️ Islamic Jurist | Fatwa specialist | Community counselor | Helping Muslims navigate modern life with Islamic principles',
      'profilePhoto': 'https://i.pravatar.cc/300?img=56',
      'posts': [
        {
          'caption':
              '🤲 Dua of the Day:\n\n"Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire." - Quran 2:201\n\nAmeen! 🌙',
          'type': 'text',
        },
      ],
    },

    // Judaism Leaders (3)
    {
      'email': 'rabbi.cohen@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Rabbi David Cohen',
      'role': 'leader',
      'faith': 'Judaism',
      'bio':
          '✡️ Orthodox Rabbi | Torah scholar | Bar Mitzvah teacher | "Hear, O Israel: the Lord our God, the Lord is One" - Deuteronomy 6:4',
      'profilePhoto': 'https://i.pravatar.cc/300?img=11',
      'posts': [
        {
          'caption':
              '📜 Shabbat Shalom! 🕯️🕯️\n\nAs we light the candles tonight, let us reflect on the blessings of the week and welcome the day of rest with grateful hearts. ✡️💙',
          'type': 'text',
        },
        {
          'caption':
              '🎓 This week\'s Torah portion teaches us about faith and obedience. Join us for Saturday morning service to dive deeper into the Word. Shabbat Shalom! 📖',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'rabbi.goldstein@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Rabbi Sarah Goldstein',
      'role': 'leader',
      'faith': 'Judaism',
      'bio':
          '🌟 Reform Rabbi | Women\'s rights advocate | Interfaith dialogue leader | "Justice, justice shall you pursue"',
      'profilePhoto': 'https://i.pravatar.cc/300?img=48',
      'posts': [
        {
          'caption':
              '💫 "Do not be daunted by the enormity of the world\'s grief. Do justly, now. Love mercy, now. Walk humbly now." - Talmud\n\nOne act of kindness at a time. 🙏',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'cantor.levy@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Cantor Benjamin Levy',
      'role': 'leader',
      'faith': 'Judaism',
      'bio':
          '🎵 Cantor & music director | Preserving Jewish liturgical traditions | "Sing to the Lord a new song" - Psalm 96:1',
      'profilePhoto': 'https://i.pravatar.cc/300?img=52',
      'posts': [
        {
          'caption':
              '🎶 The beauty of Jewish prayer is in the melody that connects our hearts to HaShem. Join us for High Holiday services - experience the spiritual power of song! ✡️',
          'type': 'text',
        },
      ],
    },

    // Other Faiths (Buddhism, Hinduism) (2)
    {
      'email': 'lama.tenzin@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Lama Tenzin Dorje',
      'role': 'leader',
      'faith': 'Other',
      'bio':
          '🧘‍♂️ Tibetan Buddhist Monk | Meditation teacher | Compassion advocate | "Peace comes from within. Do not seek it without" - Buddha',
      'profilePhoto': 'https://i.pravatar.cc/300?img=70',
      'posts': [
        {
          'caption':
              '☸️ Morning Meditation Wisdom:\n\n"Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment." - Buddha\n\nBe here now. 🧘‍♀️🙏',
          'type': 'text',
        },
        {
          'caption':
              '🪷 Join our weekly meditation sessions every Wednesday evening. Learn mindfulness, loving-kindness, and the path to inner peace. All are welcome! 🕉️',
          'type': 'text',
        },
      ],
    },
    {
      'email': 'swami.krishna@faithconnect.app',
      'password': 'Faith123!',
      'name': 'Swami Krishna Das',
      'role': 'leader',
      'faith': 'Other',
      'bio':
          '🕉️ Hindu Spiritual Teacher | Bhakti Yoga practitioner | Vedic scholar | "The soul is neither born, nor does it die" - Bhagavad Gita',
      'profilePhoto': 'https://i.pravatar.cc/300?img=58',
      'posts': [
        {
          'caption':
              '🙏 Namaste!\n\n"Yoga is the journey of the self, through the self, to the self." - Bhagavad Gita\n\nJoin us for morning prayers and kirtan. Let devotion fill your heart! 🪔✨',
          'type': 'text',
        },
      ],
    },
  ];

  // Function to seed all data
  static Future<void> seedAllData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Seeding database with sample leaders...'),
            ],
          ),
        ),
      );

      int successCount = 0;
      int errorCount = 0;

      for (var leaderData in _sampleLeaders) {
        try {
          // Check if user already exists
          final existingUsers = await _firestore
              .collection('users')
              .where('email', isEqualTo: leaderData['email'])
              .get();

          String userId;

          if (existingUsers.docs.isEmpty) {
            // Create Firebase Auth user
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: leaderData['email'] as String,
              password: leaderData['password'] as String,
            );

            userId = userCredential.user!.uid;

            // Create Firestore user document
            await _firestore.collection('users').doc(userId).set({
              'id': userId,
              'email': leaderData['email'],
              'name': leaderData['name'],
              'role': leaderData['role'],
              'faith': leaderData['faith'],
              'bio': leaderData['bio'],
              'profilePhotoUrl': leaderData['profilePhoto'],
              'followers': [],
              'following': [],
              'createdAt': FieldValue.serverTimestamp(),
              'lastSeen': DateTime.now(),
              'isOnline': false,
            });

            // Create posts for this leader
            final posts = leaderData['posts'] as List<Map<String, dynamic>>;
            for (var postData in posts) {
              final postId = _firestore.collection('posts').doc().id;
              await _firestore.collection('posts').doc(postId).set({
                'id': postId,
                'leaderId': userId,
                'leaderName': leaderData['name'],
                'leaderProfilePhotoUrl': leaderData['profilePhoto'],
                'caption': postData['caption'],
                'imageUrl': null,
                'videoUrl': null,
                'likedBy': [],
                'comments': [],
                'saves': [],
                'createdAt': DateTime.now().subtract(
                  Duration(days: posts.indexOf(postData) * 2),
                ),
                'updatedAt': DateTime.now(),
              });
            }

            successCount++;
          } else {
            debugPrint(
              'User ${leaderData['email']} already exists, skipping...',
            );
          }
        } catch (e) {
          errorCount++;
          debugPrint('Error creating leader ${leaderData['name']}: $e');
        }
      }

      // Sign out after seeding (so user can log in normally)
      await _auth.signOut();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Data Seeding Complete!'),
            content: Text(
              'Successfully created $successCount leaders with their posts!\n\n'
              '${errorCount > 0 ? "⚠️ $errorCount leaders already existed.\n\n" : ""}'
              'You can now:\n'
              '• Browse leaders in the Leaders tab\n'
              '• Follow them to see their posts\n'
              '• Like, comment, and interact\n\n'
              'Sample login:\n'
              'Email: pastor.john@faithconnect.app\n'
              'Password: Faith123!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Error'),
            content: Text('Failed to seed data: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Seed test reels with working video URLs
  static Future<void> seedReels(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get first leader to be the author (or create a test user)
      final currentUser = _auth.currentUser;
      String authorId;
      String authorName;
      String authorProfilePhoto;

      if (currentUser != null) {
        authorId = currentUser.uid;
        final userDoc = await _firestore
            .collection('users')
            .doc(authorId)
            .get();
        authorName = userDoc.data()?['name'] ?? 'Test User';
        authorProfilePhoto =
            userDoc.data()?['profilePhoto'] ??
            'https://i.pravatar.cc/300?img=1';
      } else {
        // Use a default test author
        authorId = 'test_author_123';
        authorName = 'Test Leader';
        authorProfilePhoto = 'https://i.pravatar.cc/300?img=1';
      }

      int successCount = 0;

      for (var reelData in _sampleReels) {
        try {
          await _firestore.collection('reels').add({
            'authorId': authorId,
            'authorName': authorName,
            'authorProfilePhoto': authorProfilePhoto,
            'videoUrl': reelData['videoUrl'],
            'caption': reelData['caption'],
            'thumbnailUrl': reelData['thumbnailUrl'],
            'hashtags': reelData['hashtags'],
            'likes': [],
            'comments': [],
            'views': 0,
            'createdAt': DateTime.now().subtract(
              Duration(hours: successCount * 2),
            ),
            'updatedAt': DateTime.now(),
          });
          successCount++;
          debugPrint('✅ Created reel: ${reelData['caption']}');
        } catch (e) {
          debugPrint('❌ Error creating reel: $e');
        }
      }

      if (context.mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Reels Seeded!'),
            content: Text(
              'Successfully created $successCount test reels!\n\n'
              'You can now view them in the Reels tab.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Error'),
            content: Text('Failed to seed reels: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
