import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 5가지 대표 기분 유형
enum MoodType {
  peaceful('평온', '😊'),
  energetic('활기', '🌿'),
  tired('지침', '🌧️'),
  anxious('불안', '💭'),
  angry('답답', '🔥');

  final String label;
  final String emoji;
  const MoodType(this.label, this.emoji);

  static MoodType fromString(String str) {
    switch (str.toLowerCase()) {
      case 'energetic':
        return MoodType.energetic;
      case 'anxious':
        return MoodType.anxious;
      case 'tired':
        return MoodType.tired;
      case 'angry':
        return MoodType.angry;
      case 'peaceful':
      default:
        return MoodType.peaceful;
    }
  }
}

/// "오늘의 명언" JSON 구조를 반영한 모델
class Quote {
  final int id;
  final String source; // 출처 (예: 장자 - 인간세편)
  final String original; // 원문 (한자 등). 영어 명언이면 빈 문자열
  final String reading; // 독음. 영어 명언이면 빈 문자열
  final String english; // 영어 번역
  final String translation; // 한글 의미(직역/의역)
  final String commentary; // 해설(의미 풀이)
  final String mood; // 무드 태그 (peaceful, energetic, etc.)

  const Quote({
    this.id = 0,
    required this.source,
    required this.original,
    required this.reading,
    required this.english,
    required this.translation,
    required this.commentary,
    this.mood = 'peaceful',
  });

  static final RegExp _hangulOrHanjaRegex =
      RegExp(r'[\u3131-\uD79D\u4E00-\u9FFF]');

  /// original이 비어있거나 한자가 포함되지 않은 경우 영어/일반 명언으로 간주
  bool get isOriginalEnglish {
    if (original.trim().isEmpty) return true;
    final hasHangulOrHanja = _hangulOrHanjaRegex.hasMatch(original);
    return !hasHangulOrHanja;
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: (json['id'] as num?)?.toInt() ?? 0,
      source: (json['source'] as String?) ?? '',
      original: (json['original'] as String?) ?? '',
      reading: (json['reading'] as String?) ?? '',
      english: (json['english'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      commentary: (json['commentary'] as String?) ?? '',
      mood: (json['mood'] as String?) ?? 'peaceful',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'original': original,
        'reading': reading,
        'english': english,
        'translation': translation,
        'commentary': commentary,
        'mood': mood,
      };
}

/// tale.json 파일에서 명언 목록을 로드하고 날짜별 시드로 결정적 추출을 수행하는 레포지토리
class QuoteRepository {
  static const String _deviceSeedKey = 'audistine_device_seed';
  static List<Quote>? _cachedQuotes;

  /// assets/tale.json 로드
  static Future<List<Quote>> loadQuotes() async {
    if (_cachedQuotes != null && _cachedQuotes!.isNotEmpty) {
      return _cachedQuotes!;
    }
    try {
      final jsonString = await rootBundle.loadString('assets/tale.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedQuotes = jsonList.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedQuotes!;
    } catch (e) {
      debugPrint('명언 데이터 로드 실패 ($e), 기본 명언 사용');
      return [];
    }
  }

  /// 기기 고유 시드 번호 조회 또는 생성 (기기별로 고유하면서 매일 변경되는 일관된 명언 제공)
  static Future<int> getOrCreateDeviceSeed(SharedPreferences prefs) async {
    int? seed = prefs.getInt(_deviceSeedKey);
    if (seed == null) {
      seed = Random().nextInt(10000);
      await prefs.setInt(_deviceSeedKey, seed);
    }
    return seed;
  }

  /// 특정 날짜와 시드에 따른 오늘의 명언 반환
  static Quote getDailyQuote(List<Quote> quotes, DateTime date, int seed) {
    if (quotes.isEmpty) {
      return const Quote(
        id: 0,
        source: 'audistine',
        original: '',
        reading: '',
        english: 'Peace comes from within. Do not seek it without.',
        translation: '평온은 내면에서 오는 것이니, 밖에서 찾지 말라.',
        commentary: '마음의 평화는 외부의 환경이 아닌 내면의 고요함에서 비롯됩니다.',
        mood: 'peaceful',
      );
    }
    final dayKey = int.parse('${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}');
    final index = (dayKey + seed) % quotes.length;
    return quotes[index];
  }
}
