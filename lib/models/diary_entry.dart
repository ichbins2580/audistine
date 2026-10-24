enum DiaryType {
  structuredCbt, // 5단계 인지 기록지
  free,          // 자유 서술 일기 / 명언 메모
}

/// 감정 일기 및 명언 메모 데이터 모델
class DiaryEntry {
  final String id;
  final DateTime createdAt;
  final DiaryType type;
  final String moodEmoji;
  final String moodLabel;
  final String title;
  final String content;

  // 5단계 인지 기록지 필드
  final String situation;
  final String thought;
  final String emotion;
  final String alternativeThought;
  final String action;
  final List<String> detectedDistortions;

  // 명언 메모 연동 필드
  final String quoteOriginal;
  final String quoteReading;
  final String quoteTranslation;
  final String quoteSource;
  final String quoteEnglish;
  final String quoteCommentary;

  DiaryEntry({
    required this.id,
    required this.createdAt,
    this.type = DiaryType.structuredCbt,
    this.moodEmoji = '😊',
    this.moodLabel = '평온',
    this.title = '',
    this.content = '',
    this.situation = '',
    this.thought = '',
    this.emotion = '',
    this.alternativeThought = '',
    this.action = '',
    this.detectedDistortions = const [],
    this.quoteOriginal = '',
    this.quoteReading = '',
    this.quoteTranslation = '',
    this.quoteSource = '',
    this.quoteEnglish = '',
    this.quoteCommentary = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'type': type.name,
    'moodEmoji': moodEmoji,
    'moodLabel': moodLabel,
    'title': title,
    'content': content,
    'situation': situation,
    'thought': thought,
    'emotion': emotion,
    'alternativeThought': alternativeThought,
    'action': action,
    'detectedDistortions': detectedDistortions,
    'quoteOriginal': quoteOriginal,
    'quoteReading': quoteReading,
    'quoteTranslation': quoteTranslation,
    'quoteSource': quoteSource,
    'quoteEnglish': quoteEnglish,
    'quoteCommentary': quoteCommentary,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    DiaryType parseType(String? typeStr) {
      if (typeStr == 'free') return DiaryType.free;
      return DiaryType.structuredCbt;
    }

    return DiaryEntry(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      type: parseType(json['type'] as String?),
      moodEmoji: json['moodEmoji'] as String? ?? '😊',
      moodLabel: json['moodLabel'] as String? ?? '평온',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      situation: json['situation'] as String? ?? '',
      thought: json['thought'] as String? ?? '',
      emotion: json['emotion'] as String? ?? '',
      alternativeThought: json['alternativeThought'] as String? ?? '',
      action: json['action'] as String? ?? '',
      detectedDistortions: (json['detectedDistortions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      quoteOriginal: json['quoteOriginal'] as String? ?? '',
      quoteReading: json['quoteReading'] as String? ?? '',
      quoteTranslation: json['quoteTranslation'] as String? ?? '',
      quoteSource: json['quoteSource'] as String? ?? '',
      quoteEnglish: json['quoteEnglish'] as String? ?? '',
      quoteCommentary: json['quoteCommentary'] as String? ?? '',
    );
  }
}
