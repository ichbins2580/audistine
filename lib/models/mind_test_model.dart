import 'package:flutter/material.dart';
import '../screens/rest_tab.dart';
import '../theme/app_theme.dart';
import 'pleasant_activity_pool.dart';

/// 감정의 4가지 주요 영역 (에너지 × 유쾌성)
enum EmotionCategory {
  vitality, // 활력 / 열정 (고각성 긍정)
  peace, // 평온 / 충전 (저각성 긍정)
  tension, // 긴장 / 부담 (고각성 부정)
  depletion, // 방전 / 소진 (저각성 부정)
}

/// 개별 감정 형용사 단어 모델
class EmotionWord {
  final String id;
  final String label;
  final EmotionCategory category;
  final String description;

  const EmotionWord({
    required this.id,
    required this.label,
    required this.category,
    required this.description,
  });

  Color get tagColor {
    switch (category) {
      case EmotionCategory.vitality:
        return AppColors.accentBrass; // 따뜻한 황동/코랄
      case EmotionCategory.peace:
        return AppColors.accentJade; // 비취/녹음
      case EmotionCategory.tension:
        return AppColors.accentVermilion; // 단청 주홍/레드
      case EmotionCategory.depletion:
        return AppColors.accentNavy; // 차분한 감청/먹빛
    }
  }

  String get categoryLabel {
    switch (category) {
      case EmotionCategory.vitality:
        return '활력·열정';
      case EmotionCategory.peace:
        return '평온·충전';
      case EmotionCategory.tension:
        return '긴장·부담';
      case EmotionCategory.depletion:
        return '방전·소진';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category.name,
        'description': description,
      };

  factory EmotionWord.fromJson(Map<String, dynamic> json) {
    return EmotionWord(
      id: json['id'] as String,
      label: json['label'] as String,
      category: EmotionCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => EmotionCategory.peace,
      ),
      description: json['description'] as String? ?? '',
    );
  }

  /// 24개 감정 형용사 기본 데이터셋
  static const List<EmotionWord> defaultWords = [
    // [1] 활력 / 열정 (고각성 긍정)
    EmotionWord(id: 'v1', label: '설레는', category: EmotionCategory.vitality, description: '가슴이 두근거리고 기분 좋은 기대감이 솟아나요'),
    EmotionWord(id: 'v2', label: '뿌듯한', category: EmotionCategory.vitality, description: '내가 해낸 일이나 오늘 하루에 큰 보람을 느껴요'),
    EmotionWord(id: 'v3', label: '자신있는', category: EmotionCategory.vitality, description: '스스로 해낼 수 있다는 든든한 힘이 느껴져요'),
    EmotionWord(id: 'v4', label: '열정적인', category: EmotionCategory.vitality, description: '어떤 일에 깊이 몰입하고 에너지가 솟구쳐요'),
    EmotionWord(id: 'v5', label: '신나는', category: EmotionCategory.vitality, description: '발걸음이 가볍고 마음이 들떠 즐거워요'),
    EmotionWord(id: 'v6', label: '생기있는', category: EmotionCategory.vitality, description: '몸과 마음에 맑고 신선한 에너지가 돌아요'),

    // [2] 평온 / 충전 (저각성 긍정)
    EmotionWord(id: 'p1', label: '편안한', category: EmotionCategory.peace, description: '몸과 마음의 긴장이 풀리고 아늑해요'),
    EmotionWord(id: 'p2', label: '아늑한', category: EmotionCategory.peace, description: '포근하고 따뜻한 보호를 받는 느낌이에요'),
    EmotionWord(id: 'p3', label: '담담한', category: EmotionCategory.peace, description: '크게 흔들리지 않고 고요하게 중심을 잡고 있어요'),
    EmotionWord(id: 'p4', label: '감사한', category: EmotionCategory.peace, description: '주변의 사소한 것들에도 고마운 마음이 차올라요'),
    EmotionWord(id: 'p5', label: '홀가분한', category: EmotionCategory.peace, description: '마음을 짓누르던 짐을 내려놓아 가벼워요'),
    EmotionWord(id: 'p6', label: '여유로운', category: EmotionCategory.peace, description: '서두르지 않고 시간과 공간을 편안하게 누려요'),

    // [3] 긴장 / 부담 (고각성 부정)
    EmotionWord(id: 't1', label: '조급한', category: EmotionCategory.tension, description: '시간에 쫓기거나 마음이 바빠 안절부절못해요'),
    EmotionWord(id: 't2', label: '초조한', category: EmotionCategory.tension, description: '앞일이 걱정되어 가슴이 두근거리고 불안해요'),
    EmotionWord(id: 't3', label: '화가나는', category: EmotionCategory.tension, description: '속에서 무언가 치밀어 오르고 답답해요'),
    EmotionWord(id: 't4', label: '답답한', category: EmotionCategory.tension, description: '원하는 대로 풀리지 않아 가슴이 막힌 것 같아요'),
    EmotionWord(id: 't5', label: '압박받는', category: EmotionCategory.tension, description: '책임감이나 주변의 기대에 짓눌리는 느낌이에요'),
    EmotionWord(id: 't6', label: '혼란스러운', category: EmotionCategory.tension, description: '생각이 너무 많아 갈피를 잡기 어려워요'),

    // [4] 방전 / 소진 (저각성 부정)
    EmotionWord(id: 'd1', label: '지친', category: EmotionCategory.depletion, description: '에너지가 고갈되어 쉬고 싶은 마음뿐이에요'),
    EmotionWord(id: 'd2', label: '무기력한', category: EmotionCategory.depletion, description: '아무것도 하기 싫고 의욕이 생기지 않아요'),
    EmotionWord(id: 'd3', label: '외로운', category: EmotionCategory.depletion, description: '세상에 홀로 남겨진 듯 쓸쓸한 기분이에요'),
    EmotionWord(id: 'd4', label: '서글픈', category: EmotionCategory.depletion, description: '이유 없이 가슴 한구석이 시리고 아려와요'),
    EmotionWord(id: 'd5', label: '멍한', category: EmotionCategory.depletion, description: '머릿속이 하얘지고 초점이 흐려져요'),
    EmotionWord(id: 'd6', label: '허무한', category: EmotionCategory.depletion, description: '의미를 찾기 어렵고 마음이 공허해요'),
  ];
}

/// 사용자가 선택한 감정과 체감 강도 (1: 은은함, 2: 뚜렷함, 3: 깊음)
class SelectedEmotion {
  final EmotionWord word;
  int intensity; // 1, 2, 3

  SelectedEmotion({
    required this.word,
    this.intensity = 2,
  });

  String get intensityLabel {
    switch (intensity) {
      case 1:
        return '은은하게 스쳐요';
      case 3:
        return '마음에 깊이 머물러요';
      case 2:
      default:
        return '뚜렷하게 머물러요';
    }
  }

  Map<String, dynamic> toJson() => {
        'word': word.toJson(),
        'intensity': intensity,
      };

  factory SelectedEmotion.fromJson(Map<String, dynamic> json) {
    return SelectedEmotion(
      word: EmotionWord.fromJson(json['word'] as Map<String, dynamic>),
      intensity: json['intensity'] as int? ?? 2,
    );
  }
}

/// 유쾌한 일상 활동 추천 (행동 활성화 / Pleasant Activities)
class CurationItem {
  final String category; // 'relax', 'rest', 'stroll', 'nature', 'connect', etc.
  final String categoryLabel;
  final String tag;
  final String title;
  final String subtitle;
  final String recommendationReason;
  final IconData icon;

  const CurationItem({
    required this.category,
    required this.categoryLabel,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.recommendationReason,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'categoryLabel': categoryLabel,
        'tag': tag,
        'title': title,
        'subtitle': subtitle,
        'recommendationReason': recommendationReason,
      };

  factory CurationItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as String? ?? 'relax';
    IconData icon = Icons.spa_outlined;
    if (cat == 'rest' || cat == 'sleep') icon = Icons.bed_outlined;
    if (cat == 'stroll' || cat == 'walk') icon = Icons.directions_walk_outlined;
    if (cat == 'nature' || cat == 'sun' || cat == 'breeze') icon = Icons.wb_sunny_outlined;
    if (cat == 'connect' || cat == 'love') icon = Icons.favorite_border;
    if (cat == 'music' || cat == 'audio') icon = Icons.headphones_outlined;
    if (cat == 'clean' || cat == 'organize') icon = Icons.cleaning_services_outlined;
    if (cat == 'explore' || cat == 'choice') icon = Icons.explore_outlined;
    if (cat == 'pause' || cat == 'timer') icon = Icons.timer_outlined;
    if (cat == 'smile' || cat == 'self' || cat == 'self_priority') icon = Icons.sentiment_satisfied_alt;
    if (cat == 'tea' || cat == 'water' || cat == 'mindfulness') icon = Icons.water_drop_outlined;
    if (cat == 'coffee') icon = Icons.local_cafe_outlined;
    if (cat == 'book') icon = Icons.menu_book_outlined;
    if (cat == 'art') icon = Icons.palette_outlined;

    return CurationItem(
      category: cat,
      categoryLabel: json['categoryLabel'] as String? ?? '유쾌한 활동',
      tag: json['tag'] as String? ?? '마음 케어',
      title: json['title'] as String? ?? '편안한 일상 활동',
      subtitle: json['subtitle'] as String? ?? '오늘 고생한 나를 위한 작은 쉼',
      recommendationReason: json['recommendationReason'] as String? ?? '',
      icon: icon,
    );
  }
}

/// 마음쉼터 처방 액션
class RestPrescription {
  final RestMode targetMode;
  final String title;
  final String reason;
  final String actionLabel;
  final IconData icon;

  const RestPrescription({
    required this.targetMode,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'targetMode': targetMode.name,
        'title': title,
        'reason': reason,
        'actionLabel': actionLabel,
      };

  factory RestPrescription.fromJson(Map<String, dynamic> json) {
    final modeName = json['targetMode'] as String? ?? 'breathing';
    final mode = RestMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => RestMode.breathing,
    );
    IconData icon = Icons.air;
    if (mode == RestMode.imagery) icon = Icons.landscape_outlined;
    if (mode == RestMode.meditation) icon = Icons.self_improvement_outlined;

    return RestPrescription(
      targetMode: mode,
      title: json['title'] as String? ?? '마음쉼터 호흡',
      reason: json['reason'] as String? ?? '편안한 호흡으로 심신을 안정시킵니다.',
      actionLabel: json['actionLabel'] as String? ?? '마음쉼터로 이동하기',
      icon: icon,
    );
  }
}

/// 마음 검사 종합 결과 모델
class MindTestResult {
  final String id;
  final DateTime createdAt;
  final List<SelectedEmotion> selectedEmotions;
  final String atmosphereTitle;
  final String atmosphereDesc;
  final String dynamicsMessage;
  final RestPrescription prescription;
  final CurationItem curation;
  final Map<EmotionCategory, double> categoryRatios;

  MindTestResult({
    required this.id,
    required this.createdAt,
    required this.selectedEmotions,
    required this.atmosphereTitle,
    required this.atmosphereDesc,
    required this.dynamicsMessage,
    required this.prescription,
    required this.curation,
    required this.categoryRatios,
  });

  SelectedEmotion? get dominantEmotion {
    if (selectedEmotions.isEmpty) return null;
    return selectedEmotions.reduce((a, b) => a.intensity >= b.intensity ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'selectedEmotions': selectedEmotions.map((e) => e.toJson()).toList(),
        'atmosphereTitle': atmosphereTitle,
        'atmosphereDesc': atmosphereDesc,
        'dynamicsMessage': dynamicsMessage,
        'prescription': prescription.toJson(),
        'curation': curation.toJson(),
        'categoryRatios': categoryRatios.map((k, v) => MapEntry(k.name, v)),
      };

  factory MindTestResult.fromJson(Map<String, dynamic> json) {
    final rawEmotions = json['selectedEmotions'] as List<dynamic>? ?? [];
    final emotions = rawEmotions
        .map((e) => SelectedEmotion.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawRatios = json['categoryRatios'] as Map<String, dynamic>? ?? {};
    final ratios = <EmotionCategory, double>{};
    for (final cat in EmotionCategory.values) {
      ratios[cat] = (rawRatios[cat.name] as num?)?.toDouble() ?? 0.0;
    }

    return MindTestResult(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      selectedEmotions: emotions,
      atmosphereTitle: json['atmosphereTitle'] as String? ?? '마음의 지형도',
      atmosphereDesc: json['atmosphereDesc'] as String? ?? '',
      dynamicsMessage: json['dynamicsMessage'] as String? ?? '',
      prescription: RestPrescription.fromJson(
          json['prescription'] as Map<String, dynamic>? ?? {}),
      curation: CurationItem.fromJson(
          json['curation'] as Map<String, dynamic>? ?? {}),
      categoryRatios: ratios,
    );
  }

  /// 사용자가 선택한 감정들과 강도를 분석하여 독창적인 마음 프로필 결과를 산출하는 엔진
  static MindTestResult analyze(List<SelectedEmotion> selections, [int? seed]) {
    if (selections.isEmpty) {
      // 기본값
      final defaultWord = EmotionWord.defaultWords.first;
      selections = [SelectedEmotion(word: defaultWord, intensity: 2)];
    }

    // 1. 카테고리별 가중치 합산 (Intensity 반영)
    final weights = <EmotionCategory, int>{
      EmotionCategory.vitality: 0,
      EmotionCategory.peace: 0,
      EmotionCategory.tension: 0,
      EmotionCategory.depletion: 0,
    };

    int totalWeight = 0;
    for (final sel in selections) {
      weights[sel.word.category] = (weights[sel.word.category] ?? 0) + sel.intensity;
      totalWeight += sel.intensity;
    }

    final ratios = <EmotionCategory, double>{};
    for (final cat in EmotionCategory.values) {
      ratios[cat] = totalWeight > 0 ? (weights[cat]! / totalWeight) : 0.25;
    }

    final dominantCat = weights.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final topEmotion = selections.reduce((a, b) => a.intensity >= b.intensity ? a : b);

    // 긍정 비율 & 부정 비율
    final posWeight = weights[EmotionCategory.vitality]! + weights[EmotionCategory.peace]!;
    final negWeight = weights[EmotionCategory.tension]! + weights[EmotionCategory.depletion]!;

    // 2. 마음 지형도 타이틀 및 상세 텍스처 결정
    String atmoTitle;
    String atmoDesc;
    String dynamics;
    RestPrescription prescription;

    // 복합 감정 메시지 작성
    if (posWeight > 0 && negWeight > 0) {
      // 긍정과 부정이 공존하는 아름다운 복합 감정
      if (dominantCat == EmotionCategory.tension || dominantCat == EmotionCategory.depletion) {
        dynamics = "지금은 '${topEmotion.word.label}' 마음이 짙게 머물러 있지만, 내면에는 긍정의 불씨가 함께 숨 쉬고 있어요. 마음에 잠시 쉴 틈을 주면 긍정의 빛이 더 크게 차오를 거예요.";
      } else {
        dynamics = "'${topEmotion.word.label}' 활력 속에서도 은은한 긴장이나 피로가 함께 느껴집니다. 나아가고자 하는 열정과 쉬고 싶은 마음이 균형을 이루려 하고 있어요.";
      }
    } else if (negWeight == 0) {
      dynamics = "맑고 따뜻한 감정들이 마음에 자리하고 있습니다. 오늘 경험한 평온과 기쁨을 편안하게 음미해 보세요.";
    } else {
      dynamics = "지금은 무리해서 힘을 내기보다, 지치고 긴장된 마음을 있는 그대로 인정하고 보듬어주어야 할 때입니다. 모든 감정은 자연스럽게 흘러가기 마련입니다.";
    }

    // 카테고리별 맞춤 처방 설정
    switch (dominantCat) {
      case EmotionCategory.tension:
        atmoTitle = "바람이 거세게 이는 숲";
        atmoDesc = "생각과 책임감이 많아 신경계의 긴장도가 높아진 상태입니다. 몸과 마음의 속도를 한 템포 늦추는 이완이 필요합니다.";
        prescription = const RestPrescription(
          targetMode: RestMode.breathing,
          title: "4-7-8 긴급 이완 호흡",
          reason: "들숨과 날숨의 리듬을 조절하여 곤두선 자율신경계를 부드럽게 안정시킵니다.",
          actionLabel: "마음쉼터에서 호흡 시작하기",
          icon: Icons.air,
        );
        break;

      case EmotionCategory.depletion:
        atmoTitle = "안개 낀 고요한 호숫가";
        atmoDesc = "마음의 에너지가 다소 소진되어 충전과 휴식이 필요한 상태입니다. 자극을 줄이고 포근하게 쉬어가는 시간이 도움 됩니다.";
        prescription = const RestPrescription(
          targetMode: RestMode.imagery,
          title: "평온의 심상화 풍경 여행",
          reason: "아름다운 자연 풍경과 백색 소음을 바라보며 지친 마음 에너지를 채웁니다.",
          actionLabel: "마음쉼터에서 풍경 감상하기",
          icon: Icons.landscape_outlined,
        );
        break;

      case EmotionCategory.vitality:
        atmoTitle = "햇살이 눈부신 푸른 언덕";
        atmoDesc = "내면의 추진력과 긍정 에너지가 풍부한 상태입니다. 새로운 도전이나 몰입에 아주 좋은 컨디션입니다.";
        prescription = const RestPrescription(
          targetMode: RestMode.meditation,
          title: "몰입과 감사의 고요 명상",
          reason: "좋은 에너지가 흩어지지 않도록 중심을 잡고 깊은 감사의 순간을 기록합니다.",
          actionLabel: "마음쉼터에서 명상하기",
          icon: Icons.self_improvement_outlined,
        );
        break;

      case EmotionCategory.peace:
        atmoTitle = "햇살이 머무는 툇마루";
        atmoDesc = "물결 없이 잔잔하고 평온한 상태입니다. 내면의 균형이 잘 잡혀 있으며 안락함을 느끼고 있습니다.";
        prescription = const RestPrescription(
          targetMode: RestMode.meditation,
          title: "3분 마음챙김 명상",
          reason: "현재의 맑고 고요한 마음을 오래도록 간직할 수 있도록 가만히 호흡을 지켜봅니다.",
          actionLabel: "마음쉼터에서 명상하기",
          icon: Icons.self_improvement_outlined,
        );
        break;
    }

    final curation = PleasantActivityPool.getEmotionActivity(dominantCat, seed);

    return MindTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      selectedEmotions: selections,
      atmosphereTitle: atmoTitle,
      atmosphereDesc: atmoDesc,
      dynamicsMessage: dynamics,
      prescription: prescription,
      curation: curation,
      categoryRatios: ratios,
    );
  }
}
