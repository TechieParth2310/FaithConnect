import 'package:flutter/material.dart';
import '../utils/gradient_theme.dart';
import '../services/spiritual_quotes_service.dart';

class WisdomScreen extends StatefulWidget {
  const WisdomScreen({super.key});

  @override
  State<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends State<WisdomScreen> {
  final SpiritualQuotesService _quotesService = SpiritualQuotesService();
  List<String> _wisdomQuotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWisdom();
  }

  void _loadWisdom() {
    setState(() => _isLoading = true);
    final quotes = List.generate(5, (_) {
      final quote = _quotesService.getRandomQuote();
      return quote['quote'] ?? 'Wisdom quote';
    });
    setState(() {
      _wisdomQuotes = quotes;
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
          'Wisdom Library',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadWisdom,
            tooltip: 'Refresh Wisdom',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadWisdom(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _wisdomQuotes.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: GradientTheme.cardDecoration(borderRadius: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GradientTheme.pastelSkyBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF6366F1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _wisdomQuotes[index],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: GradientTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
