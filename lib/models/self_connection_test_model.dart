import 'package:flutter/material.dart';
import '../screens/rest_tab.dart';
import '../theme/app_theme.dart';
import 'mind_test_model.dart';
import 'pleasant_activity_pool.dart';

/// 자존감 절대 영역 (3대 기둥)
enum SelfEsteemDomain {
  selfAcceptance, // 자기 수용 (실수/결점 수용력)
  selfEfficacy, // 자기 신뢰 (주도권 및 문제해결력)
  selfBoundaries, // 자기 경계 (인정 독립성 및 거절력)
}

/// 외로움 및 연결감 절대 영역
enum LonelinessDomain {
  intimateConnection, // 정서적 친밀감 (심층 유대감)
  socialConnection, // 사회적 소속감 (일상적 소속감)
  solitudePower, // 고독 자생력 (혼자 있는 평온함)
}

/// 절대 기준 충족 상태
enum DomainStatus {
  sufficient, // 충족 (건강하고 단단함)
  moderate, // 주의 (약간의 피로/흔들림)
  depleted, // 결핍 (충전 및 보살핌 필요)
}

extension DomainStatusExtension on DomainStatus {
  String get label {
    switch (this) {
      case DomainStatus.sufficient:
        return '충족';
      case DomainStatus.moderate:
        return '보통';
      case DomainStatus.depleted:
        return '충전 필요';
    }
  }

  Color get color {
    switch (this) {
      case DomainStatus.sufficient:
        return AppColors.accentJade;
      case DomainStatus.moderate:
        return AppColors.accentBrass;
      case DomainStatus.depleted:
        return AppColors.accentVermilion;
    }
  }
}

/// 자존감 절대 평가 유형
enum SelfEsteemType {
  solidCore, // 단단한 중심형 (3영역 고루 안정)
  conditionalAchievement, // 조건부 성취형 (효능감은 높으나 자기 수용 부족)
  peoplePleaser, // 친절한 소진형 (경계선 약화로 타인 인정 추구)
  restNeeded, // 내면 쉼 필요형 (전반적 지지력 저하)
}

extension SelfEsteemTypeExtension on SelfEsteemType {
  String get title {
    switch (this) {
      case SelfEsteemType.solidCore:
        return '단단한 중심형';
      case SelfEsteemType.conditionalAchievement:
        return '조건부 성취형';
      case SelfEsteemType.peoplePleaser:
        return '친절한 소진형';
      case SelfEsteemType.restNeeded:
        return '내면 쉼 필요형';
    }
  }

  String get summary {
    switch (this) {
      case SelfEsteemType.solidCore:
        return '외부 평가에 휘둘리지 않고 스스로를 존중하며 중심을 잘 잡고 있습니다.';
      case SelfEsteemType.conditionalAchievement:
        return '해내는 힘은 뛰어나지만, 실수했을 때 스스로에게 엄격한 편입니다.';
      case SelfEsteemType.peoplePleaser:
        return '타인을 배려하느라 자신의 감정과 경계를 지키는 데 에너지를 쓰고 있습니다.';
      case SelfEsteemType.restNeeded:
        return '지친 마음으로 인해 나를 긍정적으로 바라보는 에너지가 일시적으로 낮아져 있습니다.';
    }
  }
}

/// 외로움 절대 스펙트럼 레벨
enum LonelinessLevel {
  fertileSolitude, // Lv 1: 풍요로운 고독 (자생력 충만)
  transientThirst, // Lv 2: 일시적 온기 갈증 (피로로 인한 가벼운 그리움)
  emotionalDisconnect, // Lv 3: 정서적 단절감 (군중 속의 고독)
  deepIsolation, // Lv 4: 깊은 고립감 (세상과 단절된 쓸쓸함)
}

extension LonelinessLevelExtension on LonelinessLevel {
  int get levelIndex {
    switch (this) {
      case LonelinessLevel.fertileSolitude:
        return 1;
      case LonelinessLevel.transientThirst:
        return 2;
      case LonelinessLevel.emotionalDisconnect:
        return 3;
      case LonelinessLevel.deepIsolation:
        return 4;
    }
  }

  String get title {
    switch (this) {
      case LonelinessLevel.fertileSolitude:
        return '풍요로운 고독 (Lv.1)';
      case LonelinessLevel.transientThirst:
        return '일시적 온기 갈증 (Lv.2)';
      case LonelinessLevel.emotionalDisconnect:
        return '정서적 단절감 (Lv.3)';
      case LonelinessLevel.deepIsolation:
        return '깊은 고립감 (Lv.4)';
    }
  }

  String get summary {
    switch (this) {
      case LonelinessLevel.fertileSolitude:
        return '혼자 있는 시간을 자신과의 대화와 휴식으로 즐길 수 있는 건강한 상태입니다.';
      case LonelinessLevel.transientThirst:
        return '피로하거나 일상에 지쳐 가벼운 온기와 공감이 잠시 그리운 상태입니다.';
      case LonelinessLevel.emotionalDisconnect:
        return '주변에 사람은 있지만, 진정으로 나를 알아주는 연결이 부족하다고 느낍니다.';
      case LonelinessLevel.deepIsolation:
        return '세상에 홀로 남겨진 듯한 깊은 외로움으로 따뜻한 정서적 안전망이 필요합니다.';
    }
  }
}

/// 절대 평가 문항 옵션
class SelfConnectionOption {
  final String id;
  final String text;
  final int score; // 0: 결핍, 1: 보통, 2: 충족
  final String tag;

  const SelfConnectionOption({
    required this.id,
    required this.text,
    required this.score,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'score': score,
        'tag': tag,
      };

  factory SelfConnectionOption.fromJson(Map<String, dynamic> json) {
    return SelfConnectionOption(
      id: json['id'] as String,
      text: json['text'] as String,
      score: json['score'] as int? ?? 1,
      tag: json['tag'] as String? ?? '',
    );
  }
}

/// 절대 평가 문항 모델
class SelfConnectionQuestion {
  final String id;
  final String title;
  final String subtitle;
  final bool isSelfEsteem; // true: 자존감, false: 외로움/연결감
  final dynamic domain; // SelfEsteemDomain or LonelinessDomain
  final List<SelfConnectionOption> options;

  const SelfConnectionQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isSelfEsteem,
    required this.domain,
    required this.options,
  });

  static const List<SelfConnectionQuestion> defaultQuestions = [
    // [자존감 1] 자기 수용
    SelfConnectionQuestion(
      id: 'se_q1',
      title: '기대했던 일에서 실수하거나 일이 틀어졌을 때',
      subtitle: '나 자신을 향한 내면의 첫 반응은 어디에 가깝나요?',
      isSelfEsteem: true,
      domain: SelfEsteemDomain.selfAcceptance,
      options: [
        SelfConnectionOption(
          id: 'se1_a',
          text: '"누구나 그럴 수 있지, 배움의 기회야." 스스로를 너그럽게 다독인다.',
          score: 2,
          tag: '자기 자비',
        ),
        SelfConnectionOption(
          id: 'se1_b',
          text: '겉으로는 넘기려 하지만 속으로는 아쉬워하며 계속 곱씹는다.',
          score: 1,
          tag: '은은한 자책',
        ),
        SelfConnectionOption(
          id: 'se1_c',
          text: '"난 왜 늘 이럴까..." 자책하며 나 자신이 한심하고 부끄럽다.',
          score: 0,
          tag: '가혹한 비난',
        ),
      ],
    ),

    // [자존감 2] 자기 신뢰 (주도권/효능감)
    SelfConnectionQuestion(
      id: 'se_q2',
      title: '새로운 도전이나 어려운 선택의 순간을 마주했을 때',
      subtitle: '내 안에서 느껴지는 믿음의 무게는 어떠한가요?',
      isSelfEsteem: true,
      domain: SelfEsteemDomain.selfEfficacy,
      options: [
        SelfConnectionOption(
          id: 'se2_a',
          text: '불안하더라도 "결국 어떻게든 길을 찾을 것"이라는 신뢰가 있다.',
          score: 2,
          tag: '내면의 주도성',
        ),
        SelfConnectionOption(
          id: 'se2_b',
          text: '해낼 수는 있겠지만 실패가 두려워 타인의 확인과 확신에 의지한다.',
          score: 1,
          tag: '조건부 확신',
        ),
        SelfConnectionOption(
          id: 'se2_c',
          text: '어차피 잘 해내지 못할 것 같아 무기력해지고 결정을 회피하고 싶다.',
          score: 0,
          tag: '자기 불신',
        ),
      ],
    ),

    // [자존감 3] 자기 경계 (인정 독립성)
    SelfConnectionQuestion(
      id: 'se_q3',
      title: '주변의 기대나 곤란한 부탁을 받았을 때',
      subtitle: '타인의 시선 앞에서 내 마음의 기준은 어떻게 작동하나요?',
      isSelfEsteem: true,
      domain: SelfEsteemDomain.selfBoundaries,
      options: [
        SelfConnectionOption(
          id: 'se3_a',
          text: '내 감정과 에너지를 존중하며 미안함 없이 정중히 거절할 수 있다.',
          score: 2,
          tag: '건강한 경계',
        ),
        SelfConnectionOption(
          id: 'se3_b',
          text: '거절하면 관계가 틀어질까 두려워 억지로 응하고 속으로 후회한다.',
          score: 0,
          tag: '인정 욕구',
        ),
        SelfConnectionOption(
          id: 'se3_c',
          text: '상대방의 사소한 기분 변화나 표정에도 하루 종일 눈치를 본다.',
          score: 0,
          tag: '경계선 약화',
        ),
      ],
    ),

    // [외로움 1] 정서적 친밀감
    SelfConnectionQuestion(
      id: 'ln_q1',
      title: '마음이 무너질 듯 지치고 불안할 때',
      subtitle: '가면 없이 내 밑바닥 감정을 솔직히 털어놓을 대상이 있나요?',
      isSelfEsteem: false,
      domain: LonelinessDomain.intimateConnection,
      options: [
        SelfConnectionOption(
          id: 'ln1_a',
          text: '판단 없이 내 이야기를 있는 그대로 들어줄 든든한 존재가 있다.',
          score: 2,
          tag: '정서적 안전망',
        ),
        SelfConnectionOption(
          id: 'ln1_b',
          text: '사람은 있지만, 걱정 끼칠까 봐 속마음은 숨기고 괜찮은 척한다.',
          score: 1,
          tag: '마음의 빗장',
        ),
        SelfConnectionOption(
          id: 'ln1_c',
          text: '내 속마음을 털어놓을 곳이 전혀 없어 혼자 삭히고 견딘다.',
          score: 0,
          tag: '정서적 단절',
        ),
      ],
    ),

    // [외로움 2] 사회적 소속감
    SelfConnectionQuestion(
      id: 'ln_q2',
      title: '사람들과 함께 어울리는 일상 속에서',
      subtitle: '무리 속에 있을 때 내 마음이 느끼는 연결감은 어떠한가요?',
      isSelfEsteem: false,
      domain: LonelinessDomain.socialConnection,
      options: [
        SelfConnectionOption(
          id: 'ln2_a',
          text: '자연스럽게 편안함을 느끼며 내가 이 자리에 환영받는다고 느낀다.',
          score: 2,
          tag: '자연스러운 유대',
        ),
        SelfConnectionOption(
          id: 'ln2_b',
          text: '겉으로는 잘 어울리지만 마음 한구석엔 어딘가 겉도는 느낌이 든다.',
          score: 1,
          tag: '군중 속 소외',
        ),
        SelfConnectionOption(
          id: 'ln2_c',
          text: '사람들 사이에 있을수록 오히려 더 큰 이질감과 피로를 느낀다.',
          score: 0,
          tag: '사회적 고립감',
        ),
      ],
    ),

    // [외로움 3] 고독 자생력 (Solitude)
    SelfConnectionQuestion(
      id: 'ln_q3',
      title: '약속 없이 오롯이 혼자 보내는 주말이나 저녁 시간',
      subtitle: '혼자만의 고독은 나에게 어떤 의미로 다가오나요?',
      isSelfEsteem: false,
      domain: LonelinessDomain.solitudePower,
      options: [
        SelfConnectionOption(
          id: 'ln3_a',
          text: '나를 돌보고 에너지를 채우는 평온하고 소중한 휴식 시간이다.',
          score: 2,
          tag: '풍요로운 쉼',
        ),
        SelfConnectionOption(
          id: 'ln3_b',
          text: '편하긴 하지만 스마트폰을 보며 알 수 없는 공허함이 스친다.',
          score: 1,
          tag: '은은한 공허',
        ),
        SelfConnectionOption(
          id: 'ln3_c',
          text: '세상에서 나만 잊혀진 듯 쓸쓸하고 혼자 있는 시간이 불안하다.',
          score: 0,
          tag: '고립 불안',
        ),
      ],
    ),
  ];
}

/// 사용자의 문항 선택 기록
class SelfConnectionAnswer {
  final String questionId;
  final SelfConnectionOption option;

  const SelfConnectionAnswer({
    required this.questionId,
    required this.option,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'option': option.toJson(),
      };

  factory SelfConnectionAnswer.fromJson(Map<String, dynamic> json) {
    return SelfConnectionAnswer(
      questionId: json['questionId'] as String,
      option: SelfConnectionOption.fromJson(
          json['option'] as Map<String, dynamic>),
    );
  }
}

/// 자존감 & 외로움 절대 평가 종합 결과
class SelfConnectionTestResult {
  final String id;
  final DateTime createdAt;
  final List<SelfConnectionAnswer> answers;

  // 자존감 분석
  final SelfEsteemType selfEsteemType;
  final Map<SelfEsteemDomain, DomainStatus> selfEsteemDomainStatuses;
  final int selfEsteemTotalScore; // 0 ~ 6

  // 외로움/연결감 분석
  final LonelinessLevel lonelinessLevel;
  final Map<LonelinessDomain, DomainStatus> lonelinessDomainStatuses;
  final int connectionTotalScore; // 0 ~ 6

  // 2D 종합 마음 지형도
  final String landscapeTitle;
  final String landscapeSubtitle;
  final String insightNarrative;
  final RestPrescription prescription;
  final CurationItem curation;

  SelfConnectionTestResult({
    required this.id,
    required this.createdAt,
    required this.answers,
    required this.selfEsteemType,
    required this.selfEsteemDomainStatuses,
    required this.selfEsteemTotalScore,
    required this.lonelinessLevel,
    required this.lonelinessDomainStatuses,
    required this.connectionTotalScore,
    required this.landscapeTitle,
    required this.landscapeSubtitle,
    required this.insightNarrative,
    required this.prescription,
    required this.curation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'selfEsteemType': selfEsteemType.name,
        'selfEsteemDomainStatuses': selfEsteemDomainStatuses
            .map((k, v) => MapEntry(k.name, v.name)),
        'selfEsteemTotalScore': selfEsteemTotalScore,
        'lonelinessLevel': lonelinessLevel.name,
        'lonelinessDomainStatuses': lonelinessDomainStatuses
            .map((k, v) => MapEntry(k.name, v.name)),
        'connectionTotalScore': connectionTotalScore,
        'landscapeTitle': landscapeTitle,
        'landscapeSubtitle': landscapeSubtitle,
        'insightNarrative': insightNarrative,
        'prescription': prescription.toJson(),
        'curation': curation.toJson(),
      };

  factory SelfConnectionTestResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List<dynamic>? ?? [];
    final answers = rawAnswers
        .map((a) => SelfConnectionAnswer.fromJson(a as Map<String, dynamic>))
        .toList();

    final seType = SelfEsteemType.values.firstWhere(
      (e) => e.name == json['selfEsteemType'],
      orElse: () => SelfEsteemType.solidCore,
    );

    final lnLevel = LonelinessLevel.values.firstWhere(
      (e) => e.name == json['lonelinessLevel'],
      orElse: () => LonelinessLevel.fertileSolitude,
    );

    final rawSeStatuses =
        json['selfEsteemDomainStatuses'] as Map<String, dynamic>? ?? {};
    final seStatuses = <SelfEsteemDomain, DomainStatus>{};
    for (final domain in SelfEsteemDomain.values) {
      final val = rawSeStatuses[domain.name] as String?;
      seStatuses[domain] = DomainStatus.values.firstWhere(
        (s) => s.name == val,
        orElse: () => DomainStatus.sufficient,
      );
    }

    final rawLnStatuses =
        json['lonelinessDomainStatuses'] as Map<String, dynamic>? ?? {};
    final lnStatuses = <LonelinessDomain, DomainStatus>{};
    for (final domain in LonelinessDomain.values) {
      final val = rawLnStatuses[domain.name] as String?;
      lnStatuses[domain] = DomainStatus.values.firstWhere(
        (s) => s.name == val,
        orElse: () => DomainStatus.sufficient,
      );
    }

    return SelfConnectionTestResult(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      answers: answers,
      selfEsteemType: seType,
      selfEsteemDomainStatuses: seStatuses,
      selfEsteemTotalScore: json['selfEsteemTotalScore'] as int? ?? 5,
      lonelinessLevel: lnLevel,
      lonelinessDomainStatuses: lnStatuses,
      connectionTotalScore: json['connectionTotalScore'] as int? ?? 5,
      landscapeTitle: json['landscapeTitle'] as String? ?? '평온의 숲',
      landscapeSubtitle: json['landscapeSubtitle'] as String? ?? '',
      insightNarrative: json['insightNarrative'] as String? ?? '',
      prescription: RestPrescription.fromJson(
          json['prescription'] as Map<String, dynamic>? ?? {}),
      curation: CurationItem.fromJson(
          json['curation'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// 절대 평가 분석 엔진
  static SelfConnectionTestResult analyze(List<SelfConnectionAnswer> answers) {
    int seScore = 0;
    int lnScore = 0;

    final seDomainScores = <SelfEsteemDomain, int>{
      SelfEsteemDomain.selfAcceptance: 0,
      SelfEsteemDomain.selfEfficacy: 0,
      SelfEsteemDomain.selfBoundaries: 0,
    };

    final lnDomainScores = <LonelinessDomain, int>{
      LonelinessDomain.intimateConnection: 0,
      LonelinessDomain.socialConnection: 0,
      LonelinessDomain.solitudePower: 0,
    };

    for (final ans in answers) {
      final q = SelfConnectionQuestion.defaultQuestions.firstWhere(
        (q) => q.id == ans.questionId,
        orElse: () => SelfConnectionQuestion.defaultQuestions.first,
      );

      if (q.isSelfEsteem) {
        seScore += ans.option.score;
        seDomainScores[q.domain as SelfEsteemDomain] =
            (seDomainScores[q.domain as SelfEsteemDomain] ?? 0) +
                ans.option.score;
      } else {
        lnScore += ans.option.score;
        lnDomainScores[q.domain as LonelinessDomain] =
            (lnDomainScores[q.domain as LonelinessDomain] ?? 0) +
                ans.option.score;
      }
    }

    // 1. 도메인별 절대 충족도 상태 결정 (2: sufficient, 1: moderate, 0: depleted)
    final seDomainStatuses = <SelfEsteemDomain, DomainStatus>{};
    seDomainScores.forEach((domain, score) {
      if (score >= 2) {
        seDomainStatuses[domain] = DomainStatus.sufficient;
      } else if (score == 1) {
        seDomainStatuses[domain] = DomainStatus.moderate;
      } else {
        seDomainStatuses[domain] = DomainStatus.depleted;
      }
    });

    final lnDomainStatuses = <LonelinessDomain, DomainStatus>{};
    lnDomainScores.forEach((domain, score) {
      if (score >= 2) {
        lnDomainStatuses[domain] = DomainStatus.sufficient;
      } else if (score == 1) {
        lnDomainStatuses[domain] = DomainStatus.moderate;
      } else {
        lnDomainStatuses[domain] = DomainStatus.depleted;
      }
    });

    // 2. 자존감 유형 판정
    SelfEsteemType seType;
    final seAccept = seDomainStatuses[SelfEsteemDomain.selfAcceptance]!;
    final seEfficacy = seDomainStatuses[SelfEsteemDomain.selfEfficacy]!;
    final seBound = seDomainStatuses[SelfEsteemDomain.selfBoundaries]!;

    if (seAccept == DomainStatus.sufficient &&
        seEfficacy == DomainStatus.sufficient &&
        seBound == DomainStatus.sufficient) {
      seType = SelfEsteemType.solidCore;
    } else if (seScore <= 1 ||
        (seAccept == DomainStatus.depleted && seEfficacy == DomainStatus.depleted)) {
      // 전반적으로 자기 수용과 자기 신뢰가 모두 바닥나 쉼이 긴급한 상태
      seType = SelfEsteemType.restNeeded;
    } else if (seEfficacy == DomainStatus.sufficient &&
        seAccept != DomainStatus.sufficient) {
      seType = SelfEsteemType.conditionalAchievement;
    } else if (seBound == DomainStatus.depleted ||
        (seBound == DomainStatus.moderate && seAccept != DomainStatus.depleted)) {
      seType = SelfEsteemType.peoplePleaser;
    } else {
      seType = SelfEsteemType.restNeeded;
    }

    // 3. 외로움 스펙트럼 판정 (lnScore: 6~0)
    // 5~6: fertileSolitude, 3~4: transientThirst, 2: emotionalDisconnect, 0~1: deepIsolation
    LonelinessLevel lnLevel;
    if (lnScore >= 5) {
      lnLevel = LonelinessLevel.fertileSolitude;
    } else if (lnScore >= 3) {
      lnLevel = LonelinessLevel.transientThirst;
    } else if (lnScore == 2) {
      lnLevel = LonelinessLevel.emotionalDisconnect;
    } else {
      lnLevel = LonelinessLevel.deepIsolation;
    }

    // 4. 2D 결합 마음 지형도 및 처방/큐레이션 도출
    String title;
    String subtitle;
    String narrative;
    RestPrescription prescription;
    String activityKey;

    final bool isHighEsteem =
        seType == SelfEsteemType.solidCore || seScore >= 4;
    final bool isLowEsteem =
        seType == SelfEsteemType.restNeeded || seScore <= 2;
    final bool isLonely = lnLevel == LonelinessLevel.emotionalDisconnect ||
        lnLevel == LonelinessLevel.deepIsolation;

    if (isHighEsteem && !isLonely) {
      // 1) 풍요로운 숲
      title = '푸르른 생명의 숲';
      subtitle = '자신을 온전히 사랑하며 따뜻한 유대를 나누는 상태';
      narrative =
          '내면의 뿌리가 단단하게 자리 잡고 있으며, 혼자 있는 시간과 타인과의 연결 모두에서 편안한 균형을 이루고 있습니다. 지금의 건강한 리듬을 소중히 음미해 보세요.';
      prescription = const RestPrescription(
        targetMode: RestMode.meditation,
        title: '3분 감사 & 중심잡기 명상',
        reason: '맑고 단단한 내면의 호흡을 느끼며 삶의 긍정 에너지를 깊이 저장합니다.',
        actionLabel: '마음쉼터에서 명상하기',
        icon: Icons.self_improvement_outlined,
      );
      activityKey = 'solid_connected';
    } else if (isHighEsteem && isLonely) {
      // 2) 자생적 탐험가 / 고요한 별빛
      title = '달빛 비추는 고요한 언덕';
      subtitle = '혼자만의 자생력은 높지만 깊은 온기가 그리운 상태';
      narrative =
          '스스로 삶을 꾸려가는 힘은 충분하지만, 마음 한구석에서는 계산 없이 내 진심을 나눌 수 있는 따뜻한 정서적 온기를 기다리고 있습니다. 작은 안부 하나를 먼저 건네보아도 좋아요.';
      prescription = const RestPrescription(
        targetMode: RestMode.imagery,
        title: '평온의 심상화 풍경 여행',
        reason: '따뜻한 노을과 자연의 온기를 상상하며 마음에 부드러운 온기를 채웁니다.',
        actionLabel: '마음쉼터에서 풍경 감상하기',
        icon: Icons.landscape_outlined,
      );
      activityKey = 'solid_lonely';
    } else if (!isHighEsteem && !isLonely) {
      // 3) 친절한 소진 / 타인 지향적 온기
      title = '물안개 낀 잔잔한 포구';
      subtitle = '타인과의 관계는 좋으나 나 자신을 돌볼 틈이 필요한 상태';
      narrative =
          '남들의 기분과 부탁을 들어주느라 정작 내 마음의 경계선이 얇아져 있습니다. 타인의 인정을 얻기 위해 애쓰지 않아도, 당신은 이미 그 자체로 충분히 가치 있는 사람입니다.';
      prescription = const RestPrescription(
        targetMode: RestMode.breathing,
        title: '나를 보호하는 경계선 호흡',
        reason: '외부로 향했던 주의를 오롯이 내 몸과 마음에 돌려놓는 이완 호흡입니다.',
        actionLabel: '마음쉼터에서 호흡하기',
        icon: Icons.air,
      );
      activityKey = 'fragile_connected';
    } else if (isLowEsteem && isLonely) {
      // 4) 비 내리는 쉼터 (긴급 자기자비)
      title = '비 내리는 따뜻한 오두막';
      subtitle = '자책과 고립감으로 지쳐 다정한 자기 위로가 필요한 상태';
      narrative =
          '세상에 홀로 남겨진 듯 쓸쓸하고, 마음속 비판자의 목소리에 힘이 많이 빠져 있습니다. 지금은 어떤 자극도 내려놓고, 따뜻한 담요를 덮듯 나 자신을 너그럽게 안아주어야 할 시간입니다.';
      prescription = const RestPrescription(
        targetMode: RestMode.imagery,
        title: '자기 자비 심상화 & 4-7-8 이완 호흡',
        reason: '자책을 멈추고 안전한 심리적 피난처에서 마음 에너지를 회복합니다.',
        actionLabel: '마음쉼터에서 회복하기',
        icon: Icons.landscape_outlined,
      );
      activityKey = 'fragile_lonely';
    } else {
      // 5) 은은한 구름 낀 하늘 (보통/균형)
      title = '바람이 쉬어가는 툇마루';
      subtitle = '내면과 관계의 균형을 찾아가며 정돈하는 상태';
      narrative =
          '일상의 작은 흔들림 속에서도 중심을 회복하려는 자연스러운 과정에 있습니다. 마음의 신호에 귀 기울이며 차분하게 호흡을 가다듬어 보세요.';
      prescription = const RestPrescription(
        targetMode: RestMode.meditation,
        title: '3분 마음챙김 호흡 명상',
        reason: '현재의 호흡 감각에 집중하며 마음의 고요한 여백을 넓힙니다.',
        actionLabel: '마음쉼터에서 명상하기',
        icon: Icons.self_improvement_outlined,
      );
      activityKey = 'balanced';
    }

    final curation = PleasantActivityPool.getSelfConnectionActivity(activityKey);

    return SelfConnectionTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      answers: answers,
      selfEsteemType: seType,
      selfEsteemDomainStatuses: seDomainStatuses,
      selfEsteemTotalScore: seScore,
      lonelinessLevel: lnLevel,
      lonelinessDomainStatuses: lnDomainStatuses,
      connectionTotalScore: lnScore,
      landscapeTitle: title,
      landscapeSubtitle: subtitle,
      insightNarrative: narrative,
      prescription: prescription,
      curation: curation,
    );
  }
}
