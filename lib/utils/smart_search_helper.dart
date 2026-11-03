import 'dart:math';

class SmartSearchHelper {
  static String normalizeText(String input) {
    String s = input.toLowerCase().trim();
    const Map<String, String> accents = {
      'ά': 'α',
      'έ': 'ε',
      'ή': 'η',
      'ί': 'ι',
      'ϊ': 'ι',
      'ΐ': 'ι',
      'ό': 'ο',
      'ύ': 'υ',
      'ϋ': 'υ',
      'ΰ': 'υ',
      'ώ': 'ω',
      'ς': 'σ',
    };
    accents.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return _collapseDuplicates(s);
  }

  static String toPhonetic(String input) {
    String s = normalizeText(input);
    final Map<String, String> digraphs = {
      'ντ': 'd',
      'μπ': 'b',
      'γκ': 'g',
      'γγ': 'g',
      'τσ': 'ts',
      'τζ': 'tz',
      'ου': 'u',
      'αι': 'e',
      'ει': 'i',
      'οι': 'i',
      'υι': 'i',
      'αυ': 'av',
      'ευ': 'ev',
      'θ': 'th',
      'χ': 'ch',
      'ψ': 'ps',
      'cc': 'ts',
      'ch': 'ts',
      'sh': 's',
      'ph': 'f',
    };
    digraphs.forEach((k, v) {
      s = s.replaceAll(k, v);
    });

    final Map<String, String> chars = {
      'α': 'a',
      'β': 'v',
      'γ': 'g',
      'δ': 'd',
      'ε': 'e',
      'ζ': 'z',
      'η': 'i',
      'ι': 'i',
      'κ': 'k',
      'λ': 'l',
      'μ': 'm',
      'ν': 'n',
      'ξ': 'x',
      'ο': 'o',
      'π': 'p',
      'ρ': 'r',
      'σ': 's',
      'τ': 't',
      'υ': 'i',
      'φ': 'f',
      'ω': 'o',
      'c': 'k',
      'y': 'i',
      'w': 'o',
      'q': 'k',
    };
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      String ch = s[i];
      buf.write(chars[ch] ?? ch);
    }
    return _collapseDuplicates(buf.toString());
  }

  static String _collapseDuplicates(String s) {
    if (s.isEmpty) return s;
    StringBuffer b = StringBuffer();
    b.write(s[0]);
    for (int i = 1; i < s.length; i++) {
      if (s[i] != s[i - 1]) {
        b.write(s[i]);
      }
    }
    return b.toString();
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[b.length];
  }

  static bool matches(String productName, String rawQuery) {
    if (rawQuery.trim().isEmpty) return true;

    final String normProduct = normalizeText(productName);
    final String phonProduct = toPhonetic(productName);
    final List<String> productWordsNorm =
        normProduct.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final List<String> productWordsPhon =
        phonProduct.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final List<String> queryTokens =
        rawQuery.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    for (final rawToken in queryTokens) {
      final String normToken = normalizeText(rawToken);
      final String phonToken = toPhonetic(rawToken);

      if (normProduct.contains(normToken) || phonProduct.contains(phonToken)) {
        continue;
      }

      bool tokenMatchedFuzzy = false;
      int maxAllowedDistance = normToken.length >= 6
          ? 2
          : (normToken.length >= 3 ? 1 : 0);

      if (maxAllowedDistance > 0) {
        for (final word in productWordsNorm) {
          final String prefix = word.length > normToken.length
              ? word.substring(0, normToken.length)
              : word;
          if (_levenshtein(normToken, word) <= maxAllowedDistance ||
              _levenshtein(normToken, prefix) <= 1) {
            tokenMatchedFuzzy = true;
            break;
          }
        }
        if (!tokenMatchedFuzzy) {
          for (final word in productWordsPhon) {
            final String prefix = word.length > phonToken.length
                ? word.substring(0, phonToken.length)
                : word;
            if (_levenshtein(phonToken, word) <= maxAllowedDistance ||
                _levenshtein(phonToken, prefix) <= 1) {
              tokenMatchedFuzzy = true;
              break;
            }
          }
        }
      }

      if (!tokenMatchedFuzzy) return false;
    }

    return true;
  }
}