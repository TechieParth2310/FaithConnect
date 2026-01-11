import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';

/// AI-Generated Test Data Service
/// This creates sample spiritual content to test the app
class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostService _postService = PostService();

  // Sample spiritual leaders data
  final List<Map<String, dynamic>> _sampleLeaders = [
    {
      'name': 'Father Michael Chen',
      'email': 'father.michael@faithconnect.com',
      'faith': FaithType.christianity,
      'bio':
          'Catholic priest sharing daily reflections on faith, hope, and love. Guiding souls toward spiritual peace. 🙏',
      'profilePhotoUrl': 'https://i.pravatar.cc/300?img=12',
    },
    {
      'name': 'Imam Abdullah Rahman',
      'email': 'imam.abdullah@faithconnect.com',
      'faith': FaithType.islam,
      'bio':
          'Islamic scholar and teacher. Sharing wisdom from the Quran and Hadith. Leading Friday prayers at Central Mosque. ☪️',
      'profilePhotoUrl': 'https://i.pravatar.cc/300?img=33',
    },
    {
      'name': 'Rabbi Sarah Goldman',
      'email': 'rabbi.sarah@faithconnect.com',
      'faith': FaithType.judaism,
      'bio':
          'Reform Rabbi passionate about Jewish wisdom and traditions. Teaching Torah and Talmud. Shabbat Shalom! ✡️',
      'profilePhotoUrl': 'https://i.pravatar.cc/300?img=47',
    },
    {
      'name': 'Pastor David Thompson',
      'email': 'pastor.david@faithconnect.com',
      'faith': FaithType.christianity,
      'bio':
          'Leading worship and spreading the Gospel. Youth pastor helping the next generation find their faith. ⛪',
      'profilePhotoUrl': 'https://i.pravatar.cc/300?img=56',
    },
    {
      'name': 'Sister Maria Lopez',
      'email': 'sister.maria@faithconnect.com',
      'faith': FaithType.christianity,
      'bio':
          'Nun and spiritual counselor. Dedicated to prayer, service, and helping those in need. 🕊️',
      'profilePhotoUrl': 'https://i.pravatar.cc/300?img=44',
    },
  ];

  // Sample spiritual posts
  final List<Map<String, dynamic>> _samplePosts = [
    {
      'caption':
          'Start your day with gratitude. Count your blessings, not your problems. Every sunrise is a gift from God. 🌅 #MorningPrayer #Gratitude #Faith',
      'imageUrl':
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
    },
    {
      'caption':
          'The power of prayer can move mountains. Never underestimate what God can do through faith. 🙏 #Prayer #Strength #Believe',
      'imageUrl':
          'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800',
    },
    {
      'caption':
          'In times of darkness, be the light. Share kindness, spread love, and help others find their way. ✨ #BeTheLight #Kindness #Love',
      'imageUrl':
          'https://images.unsplash.com/photo-1518281361980-b26bfd556770?w=800',
    },
    {
      'caption':
          'Forgiveness is not just for others, it\'s for yourself. Let go of anger and embrace peace. 💙 #Forgiveness #Peace #Healing',
      'imageUrl':
          'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=800',
    },
    {
      'caption':
          'Your faith journey is unique. Don\'t compare yourself to others. Walk your path with confidence. 🛤️ #FaithJourney #Unique #SpiritualGrowth',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
    },
    {
      'caption':
          'Community is where faith grows. Together we are stronger, together we can do more. 🤝 #Community #Together #Unity',
      'imageUrl':
          'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800',
    },
    {
      'caption':
          'Meditation and reflection bring clarity. Take time each day to connect with the divine. 🧘‍♀️ #Meditation #Reflection #InnerPeace',
      'imageUrl':
          'https://images.unsplash.com/photo-1545389336-cf090694435e?w=800',
    },
    {
      'caption':
          'Scripture reading: "For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future." - Jeremiah 29:11 📖 #Scripture #Hope #Faith',
      'imageUrl':
          'https://images.unsplash.com/photo-1519491050282-cf00c82424b4?w=800',
    },
    {
      'caption':
          'Love your neighbor as yourself. This is the foundation of all faiths. Spread compassion today. ❤️ #Love #Compassion #GoldenRule',
      'imageUrl':
          'https://images.unsplash.com/photo-1529070538774-1843cb3265df?w=800',
    },
    {
      'caption':
          'Worship is more than words - it\'s a lifestyle. Live each day as an offering of praise. 🎵 #Worship #Praise #LiveFully',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
    },
  ];

  // Sample inspirational quotes
  final List<String> _spiritualQuotes = [
    'Faith is taking the first step even when you don\'t see the whole staircase. - Martin Luther King Jr.',
    'Peace comes from within. Do not seek it without. - Buddha',
    'The wound is the place where the Light enters you. - Rumi',
    'Let your light shine before others. - Matthew 5:16',
    'Prayer is not asking. It is a longing of the soul. - Gandhi',
    'Trust in the Lord with all your heart. - Proverbs 3:5',
    'Be still and know that I am God. - Psalm 46:10',
    'Love is patient, love is kind. - 1 Corinthians 13:4',
  ];

  /// Create sample religious leaders
  Future<List<String>> createSampleLeaders() async {
    List<String> leaderIds = [];

    print('🌟 Creating sample religious leaders...');

    for (var leaderData in _sampleLeaders) {
      try {
        // Create auth account
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: leaderData['email'],
              password: 'FaithConnect2024!',
            );

        final userId = userCredential.user!.uid;

        // Create user document
        final user = UserModel(
          id: userId,
          name: leaderData['name'],
          email: leaderData['email'],
          role: UserRole.religiousLeader,
          faith: leaderData['faith'],
          bio: leaderData['bio'],
          profilePhotoUrl: leaderData['profilePhotoUrl'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(userId).set(user.toMap());

        leaderIds.add(userId);
        print('✅ Created leader: ${leaderData['name']}');
      } catch (e) {
        print('⚠️ Error creating ${leaderData['name']}: $e');
        // Leader might already exist, try to get their ID
        try {
          final existingUser = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: leaderData['email'],
                password: 'FaithConnect2024!',
              );
          leaderIds.add(existingUser.user!.uid);
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
    }

    return leaderIds;
  }

  /// Create sample posts for leaders
  Future<void> createSamplePosts(List<String> leaderIds) async {
    if (leaderIds.isEmpty) {
      print('⚠️ No leaders available to create posts');
      return;
    }

    print('📝 Creating sample spiritual posts...');

    int postIndex = 0;
    for (var postData in _samplePosts) {
      try {
        // Rotate through leaders
        final leaderId = leaderIds[postIndex % leaderIds.length];

        // Get leader info
        final leaderDoc = await _firestore
            .collection('users')
            .doc(leaderId)
            .get();
        final leader = UserModel.fromFirestore(leaderDoc);

        // Create post
        await _postService.createPost(
          leaderId: leaderId,
          leaderName: leader.name,
          caption: postData['caption'],
          imageUrl: postData['imageUrl'],
          leaderProfilePhotoUrl: leader.profilePhotoUrl,
        );

        print('✅ Created post: ${postData['caption'].substring(0, 50)}...');
        postIndex++;
      } catch (e) {
        print('⚠️ Error creating post: $e');
      }
    }
  }

  /// Create sample worshipers
  Future<List<String>> createSampleWorshipers() async {
    List<String> worshiperIds = [];

    final sampleWorshipers = [
      {
        'name': 'Emma Johnson',
        'email': 'emma.j@example.com',
        'faith': FaithType.christianity,
        'bio': 'Seeking daily inspiration and spiritual growth 🙏',
      },
      {
        'name': 'Mohammed Ali',
        'email': 'mohammed.a@example.com',
        'faith': FaithType.islam,
        'bio': 'Faithful believer, prayer warrior ☪️',
      },
      {
        'name': 'Rachel Cohen',
        'email': 'rachel.c@example.com',
        'faith': FaithType.judaism,
        'bio': 'Torah student, loving life ✡️',
      },
    ];

    print('👥 Creating sample worshipers...');

    for (var worshiperData in sampleWorshipers) {
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: worshiperData['email'] as String,
              password: 'FaithConnect2024!',
            );
        final userId = userCredential.user!.uid;

        final user = UserModel(
          id: userId,
          name: worshiperData['name'] as String,
          email: worshiperData['email'] as String,
          role: UserRole.worshiper,
          faith: worshiperData['faith'] as FaithType,
          bio: worshiperData['bio'] as String,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(userId).set(user.toMap());

        worshiperIds.add(userId);
        print('✅ Created worshiper: ${worshiperData['name']}');
      } catch (e) {
        print('⚠️ Error creating ${worshiperData['name']}: $e');
      }
    }

    return worshiperIds;
  }

  /// Seed all data at once
  Future<void> seedAllData() async {
    try {
      print('\n🌱 Starting FaithConnect Data Seeding...\n');

      // Create leaders
      final leaderIds = await createSampleLeaders();
      print('\n✅ Created ${leaderIds.length} religious leaders\n');

      // Create posts
      await createSamplePosts(leaderIds);
      print('\n✅ Created ${_samplePosts.length} spiritual posts\n');

      // Create worshipers
      final worshiperIds = await createSampleWorshipers();
      print('\n✅ Created ${worshiperIds.length} worshipers\n');

      print('🎉 Data seeding complete!\n');
      print('📧 Test Accounts:');
      print('Leader: father.michael@faithconnect.com / FaithConnect2024!');
      print('Leader: imam.abdullah@faithconnect.com / FaithConnect2024!');
      print('Leader: rabbi.sarah@faithconnect.com / FaithConnect2024!');
      print('Worshiper: emma.j@example.com / FaithConnect2024!');
      print('\n');
    } catch (e) {
      print('❌ Error seeding data: $e');
    }
  }

  /// Get a random spiritual quote
  String getRandomQuote() {
    return _spiritualQuotes[DateTime.now().millisecond %
        _spiritualQuotes.length];
  }
}
