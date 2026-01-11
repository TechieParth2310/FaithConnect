import 'dart:math';

class SpiritualQuotesService {
  // Spiritual quotes categorized by faith
  final Map<String, List<Map<String, String>>> _quotesByFaith = {
    'christianity': [
      {
        'quote':
            'Faith is taking the first step even when you don\'t see the whole staircase.',
        'author': 'Martin Luther King Jr.',
      },
      {
        'quote': 'Let your light shine before others.',
        'author': 'Matthew 5:16',
      },
      {
        'quote': 'Trust in the Lord with all your heart.',
        'author': 'Proverbs 3:5',
      },
      {'quote': 'Be still and know that I am God.', 'author': 'Psalm 46:10'},
      {
        'quote': 'Love is patient, love is kind.',
        'author': '1 Corinthians 13:4',
      },
      {
        'quote':
            'For God so loved the world that he gave his one and only Son.',
        'author': 'John 3:16',
      },
      {
        'quote': 'I can do all things through Christ who strengthens me.',
        'author': 'Philippians 4:13',
      },
      {
        'quote': 'The Lord is my shepherd; I shall not want.',
        'author': 'Psalm 23:1',
      },
    ],
    'islam': [
      {'quote': 'Indeed, with hardship comes ease.', 'author': 'Quran 94:6'},
      {
        'quote': 'Allah does not burden a soul beyond that it can bear.',
        'author': 'Quran 2:286',
      },
      {'quote': 'And He is with you wherever you are.', 'author': 'Quran 57:4'},
      {
        'quote': 'Verily, in the remembrance of Allah do hearts find rest.',
        'author': 'Quran 13:28',
      },
      {
        'quote': 'The best among you are those who have the best manners.',
        'author': 'Prophet Muhammad (PBUH)',
      },
      {
        'quote': 'Kindness is a mark of faith.',
        'author': 'Prophet Muhammad (PBUH)',
      },
      {'quote': 'Do not lose hope, nor be sad.', 'author': 'Quran 3:139'},
      {
        'quote': 'Allah is the light of the heavens and the earth.',
        'author': 'Quran 24:35',
      },
    ],
    'judaism': [
      {'quote': 'Love your neighbor as yourself.', 'author': 'Leviticus 19:18'},
      {
        'quote':
            'It is not your duty to finish the work, but neither are you at liberty to neglect it.',
        'author': 'Pirkei Avot 2:16',
      },
      {
        'quote':
            'The world stands on three things: Torah, service, and acts of loving kindness.',
        'author': 'Pirkei Avot 1:2',
      },
      {
        'quote':
            'Whoever saves a life, it is considered as if he saved an entire world.',
        'author': 'Talmud, Sanhedrin 37a',
      },
      {
        'quote': 'Do not be daunted by the enormity of the world\'s grief.',
        'author': 'Talmud',
      },
      {'quote': 'Seek peace and pursue it.', 'author': 'Psalm 34:14'},
      {
        'quote': 'You shall love the Lord your God with all your heart.',
        'author': 'Deuteronomy 6:5',
      },
    ],
    'general': [
      {
        'quote': 'The wound is the place where the Light enters you.',
        'author': 'Rumi',
      },
      {
        'quote': 'Peace comes from within. Do not seek it without.',
        'author': 'Buddha',
      },
      {
        'quote': 'Prayer is not asking. It is a longing of the soul.',
        'author': 'Gandhi',
      },
      {
        'quote': 'The soul always knows what to do to heal itself.',
        'author': 'Caroline Myss',
      },
      {
        'quote': 'Gratitude unlocks the fullness of life.',
        'author': 'Melody Beattie',
      },
      {
        'quote':
            'Your sacred space is where you can find yourself again and again.',
        'author': 'Joseph Campbell',
      },
      {
        'quote':
            'Faith is the bird that feels the light when the dawn is still dark.',
        'author': 'Rabindranath Tagore',
      },
      {
        'quote':
            'Let yourself be silently drawn by the strange pull of what you really love.',
        'author': 'Rumi',
      },
    ],
  };

  final Random _random = Random();

  /// Get a random quote for a specific faith
  Map<String, String> getQuoteForFaith(String faith) {
    final faithKey = faith.toLowerCase();
    final quotes = _quotesByFaith[faithKey] ?? _quotesByFaith['general']!;
    return quotes[_random.nextInt(quotes.length)];
  }

  /// Get daily quote (same for the whole day)
  Map<String, String> getDailyQuote([String? faith]) {
    // Use today's date as seed for consistent daily quote
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final dailyRandom = Random(seed);

    if (faith != null) {
      final faithKey = faith.toLowerCase();
      final quotes = _quotesByFaith[faithKey] ?? _quotesByFaith['general']!;
      return quotes[dailyRandom.nextInt(quotes.length)];
    }

    // Get from all quotes
    final allQuotes = <Map<String, String>>[];
    _quotesByFaith.forEach((key, quotes) {
      allQuotes.addAll(quotes);
    });

    return allQuotes[dailyRandom.nextInt(allQuotes.length)];
  }

  /// Get random quote from all faiths
  Map<String, String> getRandomQuote() {
    final allQuotes = <Map<String, String>>[];
    _quotesByFaith.forEach((key, quotes) {
      allQuotes.addAll(quotes);
    });
    return allQuotes[_random.nextInt(allQuotes.length)];
  }

  /// Get all quotes for a faith
  List<Map<String, String>> getQuotesForFaith(String faith) {
    final faithKey = faith.toLowerCase();
    return _quotesByFaith[faithKey] ?? _quotesByFaith['general']!;
  }
}
