class PrayerTimesService {
  // Calculate prayer times based on location and date
  Map<String, DateTime> calculatePrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();

    // Simplified prayer time calculation
    // In production, use a proper library like adhan
    final times = <String, DateTime>{};

    // Fajr (Dawn) - approximately 1.5 hours before sunrise
    times['Fajr'] = DateTime(now.year, now.month, now.day, 5, 30);

    // Sunrise
    times['Sunrise'] = DateTime(now.year, now.month, now.day, 6, 30);

    // Dhuhr (Noon) - approximately solar noon
    times['Dhuhr'] = DateTime(now.year, now.month, now.day, 12, 30);

    // Asr (Afternoon)
    times['Asr'] = DateTime(now.year, now.month, now.day, 15, 45);

    // Maghrib (Sunset)
    times['Maghrib'] = DateTime(now.year, now.month, now.day, 18, 15);

    // Isha (Night)
    times['Isha'] = DateTime(now.year, now.month, now.day, 19, 45);

    return times;
  }

  // Get next prayer time
  Map<String, dynamic> getNextPrayer({
    required double latitude,
    required double longitude,
  }) {
    final times = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );

    final now = DateTime.now();
    final prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    for (final name in prayerNames) {
      final time = times[name]!;
      if (time.isAfter(now)) {
        return {'name': name, 'time': time, 'remaining': time.difference(now)};
      }
    }

    // If no prayer left today, return Fajr tomorrow
    final fajrTomorrow = times['Fajr']!.add(const Duration(days: 1));
    return {
      'name': 'Fajr',
      'time': fajrTomorrow,
      'remaining': fajrTomorrow.difference(now),
    };
  }

  // Get formatted time remaining
  String getTimeRemainingText(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  // Christian prayer times (simplified)
  Map<String, String> getChristianPrayerTimes() {
    return {
      'Morning Prayer': '6:00 AM',
      'Midday Prayer': '12:00 PM',
      'Evening Prayer': '6:00 PM',
      'Night Prayer': '9:00 PM',
    };
  }

  // Jewish prayer times (simplified)
  Map<String, String> getJewishPrayerTimes() {
    return {
      'Shacharit (Morning)': '7:00 AM',
      'Mincha (Afternoon)': '3:30 PM',
      'Maariv (Evening)': '7:00 PM',
    };
  }

  // Get daily verse based on faith
  String getDailyVerse(String faith) {
    final verses = _getVersesByFaith(faith);
    final index = DateTime.now().day % verses.length;
    return verses[index];
  }

  List<String> _getVersesByFaith(String faith) {
    switch (faith.toLowerCase()) {
      case 'christianity':
        return [
          '"For God so loved the world that he gave his one and only Son." - John 3:16',
          '"I can do all things through Christ who strengthens me." - Philippians 4:13',
          '"The Lord is my shepherd; I shall not want." - Psalm 23:1',
          '"Trust in the Lord with all your heart." - Proverbs 3:5',
          '"Be still and know that I am God." - Psalm 46:10',
          '"Love your neighbor as yourself." - Mark 12:31',
          '"Let your light shine before others." - Matthew 5:16',
          '"Faith is confidence in what we hope for." - Hebrews 11:1',
          '"The Lord is my light and my salvation." - Psalm 27:1',
          '"God is love." - 1 John 4:8',
        ];
      case 'islam':
        return [
          '"Indeed, with hardship comes ease." - Quran 94:6',
          '"Allah does not burden a soul beyond that it can bear." - Quran 2:286',
          '"And He is with you wherever you are." - Quran 57:4',
          '"Verily, in the remembrance of Allah do hearts find rest." - Quran 13:28',
          '"Do not lose hope, nor be sad." - Quran 3:139',
          '"Allah is the light of the heavens and the earth." - Quran 24:35',
          '"Patience is of two kinds: patience over what pains you." - Hadith',
          '"The best among you are those who have the best manners." - Hadith',
          '"Kindness is a mark of faith." - Hadith',
          '"Whoever relieves a believer of distress in this world..." - Hadith',
        ];
      case 'judaism':
        return [
          '"Love your neighbor as yourself." - Leviticus 19:18',
          '"Seek peace and pursue it." - Psalm 34:14',
          '"You shall love the Lord your God with all your heart." - Deuteronomy 6:5',
          '"Justice, justice shall you pursue." - Deuteronomy 16:20',
          '"The world stands on three things: Torah, service, and acts of loving kindness." - Pirkei Avot 1:2',
          '"It is not your duty to finish the work, but neither are you at liberty to neglect it." - Pirkei Avot 2:16',
          '"Whoever saves a life, it is as if he saved an entire world." - Talmud',
          '"Do not be daunted by the enormity of the world\'s grief." - Talmud',
          '"The day is short, and the work is much." - Pirkei Avot 2:15',
          '"Say little and do much." - Pirkei Avot 1:15',
        ];
      default:
        return [
          '"Peace comes from within. Do not seek it without." - Buddha',
          '"The wound is the place where the Light enters you." - Rumi',
          '"Prayer is not asking. It is a longing of the soul." - Gandhi',
          '"Gratitude unlocks the fullness of life." - Melody Beattie',
          '"The soul always knows what to do to heal itself." - Caroline Myss',
          '"Your sacred space is where you can find yourself again." - Joseph Campbell',
          '"Faith is the bird that feels the light when the dawn is still dark." - Tagore',
          '"Let yourself be silently drawn by what you really love." - Rumi',
          '"In the end, only three things matter: how much you loved, how gently you lived, and how gracefully you let go." - Buddha',
          '"The best time to plant a tree was 20 years ago. The second best time is now." - Proverb',
        ];
    }
  }
}
