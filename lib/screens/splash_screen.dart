import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'landing_screen.dart';
import 'main_wrapper.dart';

/// Minimal premium splash that matches the locked brand direction.
///
/// Contract:
/// - Full-screen, centered mark + app name (+ subtle tagline)
/// - Uses locked palette (#6C63FF etc.)
/// - Runs app initialization while visible
/// - Routes to the correct destination WITHOUT flicker
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFEFEFFF);
  static const _primary = Color(0xFF6C63FF);
  static const _charcoal = Color(0xFF1F2937);
  static const _softGray = Color(0xFFF6F7FB);

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  Future<Widget>? _destinationFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scaleIn = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Start initialization immediately.
    _destinationFuture = _resolveDestination();

    // Navigate only after BOTH:
    // - Min display time (premium pacing)
    // - Destination resolved (no blank/black flicker)
    unawaited(_navigateWhenReady());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Widget> _resolveDestination() async {
    // Firebase is already initialized in main(). Here we decide where to go.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LandingScreen();
    }

    try {
      // Load the full user model so MainWrapper can pick the correct UI.
      // This prevents a role-flicker after splash.
      final authService = AuthService();
      await authService.getUserById(user.uid);
    } catch (_) {
      // If something transient fails, we still allow the app to proceed.
    }

    return const MainWrapper();
  }

  Future<void> _navigateWhenReady() async {
    const minDuration = Duration(milliseconds: 1800);
    const maxDuration = Duration(milliseconds: 2500);

    final startedAt = DateTime.now();
    final destination = await _destinationFuture!;
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = minDuration - elapsed;

    if (remaining.isNegative) {
      // Already displayed long enough.
    } else {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    // Hard cap: if initialization was very quick, we still already waited min.
    // If init was very slow, we proceed as soon as it completes (but we don't
    // intentionally block beyond maxDuration).
    final totalDisplayed = DateTime.now().difference(startedAt);
    if (totalDisplayed > maxDuration) {
      // proceed immediately
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          // Soft, premium gradient (subtle; not flashy)
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bg, _softGray],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: _scaleIn.value,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mark (never cropped): fixed box + FittedBox + contain.
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: const SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: _FallbackMark(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'FaithConnect',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: _charcoal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Spiritual • Calm • Connected',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: 52,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackMark extends StatelessWidget {
  const _FallbackMark();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _FallbackMarkPainter()),
    );
  }
}

class _FallbackMarkPainter extends CustomPainter {
  static const _primary = Color(0xFF6C63FF);
  static const _primaryDark = Color(0xFF5A52E0);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke1 = Paint()
      ..color = _primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stroke2 = Paint()
      ..color = _primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    final left = Path()
      ..moveTo(center.dx - r * 0.18, center.dy - r * 0.28)
      ..cubicTo(
        center.dx - r * 0.42,
        center.dy - r * 0.12,
        center.dx - r * 0.42,
        center.dy + r * 0.12,
        center.dx,
        center.dy + r * 0.30,
      );

    final right = Path()
      ..moveTo(center.dx + r * 0.18, center.dy - r * 0.28)
      ..cubicTo(
        center.dx + r * 0.42,
        center.dy - r * 0.12,
        center.dx + r * 0.42,
        center.dy + r * 0.12,
        center.dx,
        center.dy + r * 0.30,
      );

    final link = Path()
      ..moveTo(center.dx - r * 0.18, center.dy)
      ..cubicTo(
        center.dx - r * 0.08,
        center.dy - r * 0.08,
        center.dx + r * 0.08,
        center.dy - r * 0.08,
        center.dx + r * 0.18,
        center.dy,
      );

    canvas.drawPath(left, stroke1);
    canvas.drawPath(right, stroke2);

    final linkPaint = Paint()
      ..color = _primary.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(link, linkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
