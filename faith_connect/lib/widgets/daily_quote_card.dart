import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/spiritual_quotes_service.dart';

class DailyQuoteCard extends StatefulWidget {
  final String? userFaith; // Optional: to show faith-specific quotes

  const DailyQuoteCard({super.key, this.userFaith});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  final SpiritualQuotesService _quotesService = SpiritualQuotesService();
  late Map<String, String> _dailyQuote;
  bool _animateIn = false;

  @override
  void initState() {
    super.initState();
    _dailyQuote = _quotesService.getDailyQuote(widget.userFaith);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateIn = true);
    });
  }

  void _shareQuote() {
    final text =
        '"${_dailyQuote['quote']}"\n\n- ${_dailyQuote['author']}\n\nShared via FaithConnect';
    Share.share(text);
  }

  void _copyQuote() {
    final text = '"${_dailyQuote['quote']}"\n\n- ${_dailyQuote['author']}';
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _getNewQuote() {
    setState(() {
      _dailyQuote = _quotesService.getRandomQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    const heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
    );

    final overlayGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.12),
        Colors.white.withOpacity(0.07),
        Colors.black.withOpacity(0.05),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      opacity: _animateIn ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        offset: _animateIn ? Offset.zero : const Offset(0, 0.04),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: heroGradient,
            borderRadius: radius,
            border: Border.all(color: Colors.white12, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(gradient: overlayGradient),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Daily Inspiration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: _getNewQuote,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                            tooltip: 'Refresh',
                            splashRadius: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"${_dailyQuote['quote']}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 2,
                          color: Colors.white.withOpacity(0.45),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _dailyQuote['author'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _IconPillButton(
                          icon: Icons.copy,
                          tooltip: 'Copy',
                          onPressed: _copyQuote,
                        ),
                        const SizedBox(width: 6),
                        _IconPillButton(
                          icon: Icons.share,
                          tooltip: 'Share',
                          onPressed: _shareQuote,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconPillButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }
}
