import 'package:flutter/material.dart';
import '../services/prayer_times_service.dart';

class PrayerTimesCard extends StatefulWidget {
  final String faith;

  const PrayerTimesCard({super.key, required this.faith});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  Map<String, dynamic>? _nextPrayer;

  @override
  void initState() {
    super.initState();
    _loadNextPrayer();
  }

  void _loadNextPrayer() {
    // Default location (can be replaced with actual user location)
    final next = _prayerService.getNextPrayer(
      latitude: 40.7128,
      longitude: -74.0060,
    );
    setState(() {
      _nextPrayer = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.faith.toLowerCase() != 'islam' &&
        widget.faith.toLowerCase() != 'christianity' &&
        widget.faith.toLowerCase() != 'judaism') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade400, Colors.cyan.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAllPrayerTimes(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAllPrayerTimes,
                      icon: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'All Times',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (widget.faith.toLowerCase() == 'islam' &&
                    _nextPrayer != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Prayer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nextPrayer!['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(_nextPrayer!['time']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'in ${_prayerService.getTimeRemainingText(_nextPrayer!['remaining'])}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    _getDailyVerse(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.faith.toLowerCase()) {
      case 'islam':
        return 'Prayer Times';
      case 'christianity':
        return 'Prayer Times';
      case 'judaism':
        return 'Prayer Times';
      default:
        return 'Daily Reflection';
    }
  }

  String _getDailyVerse() {
    return _prayerService.getDailyVerse(widget.faith);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showAllPrayerTimes() {
    Map<String, String> times;

    switch (widget.faith.toLowerCase()) {
      case 'islam':
        final islamicTimes = _prayerService.calculatePrayerTimes(
          latitude: 40.7128,
          longitude: -74.0060,
        );
        times = islamicTimes.map(
          (key, value) => MapEntry(key, _formatTime(value)),
        );
        break;
      case 'christianity':
        times = _prayerService.getChristianPrayerTimes();
        break;
      case 'judaism':
        times = _prayerService.getJewishPrayerTimes();
        break;
      default:
        times = {};
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getTitle(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...times.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.teal.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
