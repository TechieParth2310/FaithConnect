import 'package:flutter/material.dart';
import '../utils/gradient_theme.dart';
import '../services/spiritual_quotes_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final SpiritualQuotesService _quotesService = SpiritualQuotesService();
  String _currentPrayer = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  void _loadPrayer() {
    setState(() => _isLoading = true);
    final prayer = _quotesService.getRandomQuote();
    setState(() {
      _currentPrayer = prayer['quote'] ?? 'May peace be with you.';
      _isLoading = false;
    });
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
          'Prayer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadPrayer,
            tooltip: 'Refresh Prayer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: GradientTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: GradientTheme.primaryGradient.colors[2]
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _currentPrayer,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: GradientTheme.cardDecoration(borderRadius: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: GradientTheme.pastelPink,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFEC4899),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Prayer Time',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: GradientTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Take a moment for prayer and reflection. Connect with your faith and find inner peace.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: GradientTheme.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
