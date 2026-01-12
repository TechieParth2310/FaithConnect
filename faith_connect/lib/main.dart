import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message: ${message.notification?.title}');
}

// Request notification permission (Android 13+)
Future<void> requestNotificationPermission() async {
  if (kIsWeb) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🔔 Notification permission status: ${settings.authorizationStatus}');
  
  // Verify FCM token is generated after permission is granted
  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    try {
      String? token = await messaging.getToken();
      if (token != null) {
        print('✅ FCM TOKEN: $token');
      } else {
        print('❌ FCM TOKEN: null - token generation failed');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  } else {
    print('⚠️ Notification permission denied - FCM token will not be generated');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request notification permission (Android 13+)
  // This must be called after Firebase initialization
  await requestNotificationPermission();

  // Set up background message handler for FCM
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Set persistence to LOCAL for web to maintain login across refreshes
  // Note: setPersistence is only supported on web, not on mobile
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  // Initialize push notifications and save FCM token for existing user
  if (!kIsWeb) {
    final pushService = PushNotificationService();
    await pushService.initialize();

    // If user is already logged in, save their FCM token
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await pushService.saveTokenToUser(currentUser.uid);
      print('📱 FCM token saved for existing user: ${currentUser.uid}');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOnlineStatus(true);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Initialize deep link handling
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link when app is launched
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri.toString());
        }
      },
      onError: (err) {
        debugPrint('Error handling deep link: $err');
      },
    );
  }

  // Handle deep link navigation
  void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      debugPrint('Handling deep link: $link');

      // Wait for navigation to be ready
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        // Parse the deep link
        if (uri.pathSegments.isEmpty) return;

        final type = uri.pathSegments[0]; // 'post' or 'reel'
        final id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

        if (id == null) return;

        // Navigate based on link type
        if (type == 'post') {
          // Navigate to post detail
          debugPrint('Opening post: $id');
          // TODO: Navigate to post detail screen
        } else if (type == 'reel') {
          // Navigate to reel
          debugPrint('Opening reel: $id');
          // TODO: Navigate to reel screen with specific reel
        }
      });
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App comes to foreground
        _updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
        // App goes to background
        _updateOnlineStatus(false);
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call received)
        break;
      case AppLifecycleState.detached:
        // App is detached
        _updateOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await _authService.updateOnlineStatus(userId, isOnline);
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting app flow
      debugPrint('Error updating online status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FaithConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
