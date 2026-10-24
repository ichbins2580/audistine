import 'package:flutter/material.dart';
import '../models/mind_test_model.dart';
import '../screens/rest_tab.dart';
import '../theme/app_theme.dart';
import 'pleasant_activity_pool.dart';

/// 삶의 규칙의 6대 방어 메커니즘 아키타입
enum SurvivalRuleType {
  overachieving,      // 과잉 성취 & 완벽 방패
  pleasing,           // 과잉 순응 & 감정 조율사
  hyperControl,       // 과잉 통제 & 불안 레이더
  emotionalWall,      // 철벽 방어 & 정서적 요새
  hyperResponsibility,// 과잉 책임 & 침묵의 짊어짐
  preemptiveSurrender // 선제 포기 & 체념 방어막
}

/// 삶의 규칙의 경직도(Rigidity) 수준
enum RuleRigidityLevel {
  flexible,  // 0 ~ 35점 (유연한 적응)
  moderate,  // 36 ~ 69점 (주의적 긴장)
  rigid,     // 70 ~ 100점 (만성적 과부하)
}

extension RuleRigidityLevelExtension on RuleRigidityLevel {
  String get title {
    switch (this) {
      case RuleRigidityLevel.flexible:
        return '유연한 조절 상태';
      case RuleRigidityLevel.moderate:
        return '주의적 긴장 상태';
      case RuleRigidityLevel.rigid:
        return '만성적 과부하 상태';
    }
  }

  String get description {
    switch (this) {
      case RuleRigidityLevel.flexible:
        return '삶의 규칙을 상황에 따라 유연하게 끄고 켤 수 있으며, 심리적 에너지가 자유롭습니다.';
      case RuleRigidityLevel.moderate:
        return '스트레스나 위기 상황이 닥치면 규칙이 강하게 작동하여 몸과 마음에 피로가 쌓입니다.';
      case RuleRigidityLevel.rigid:
        return '규칙이 엄격한 내면의 감시관처럼 작동하여 만성적인 긴장과 자기 검열을 유발합니다.';
    }
  }

  Color get color {
    switch (this) {
      case RuleRigidityLevel.flexible:
        return AppColors.accentJade;
      case RuleRigidityLevel.moderate:
        return AppColors.accentBrass;
      case RuleRigidityLevel.rigid:
        return AppColors.accentVermilion;
    }
  }
}

/// 삶의 규칙 상세 프로필 정보
class SurvivalRuleProfile {
  final SurvivalRuleType type;
  final String title;
  final String shortTag;
  final String emoji;
  final String coreRulePhrase;       // 핵심 당위 규칙 명제 ("~해야만 ~하다")
  final String protectionOrigin;     // 과거 이 규칙이 나를 보호해준 기원
  final String currentCost;          // 현재 이 규칙이 치르게 하는 심리적 대가
  final String awarenessPhrase;      // 1단계: 알아차림 구호
  final String exceptionExperiment;   // 2단계: 작은 예외 허용 실험
  final String flexibleNewRule;      // 3단계: 새로운 유연한 규칙

  const SurvivalRuleProfile({
    required this.type,
    required this.title,
    required this.shortTag,
    required this.emoji,
    required this.coreRulePhrase,
    required this.protectionOrigin,
    required this.currentCost,
    required this.awarenessPhrase,
    required this.exceptionExperiment,
    required this.flexibleNewRule,
  });

  static const Map<SurvivalRuleType, SurvivalRuleProfile> profiles = {
    SurvivalRuleType.overachieving: SurvivalRuleProfile(
      type: SurvivalRuleType.overachieving,
      title: '과잉 성취 & 완벽 방패',
      shortTag: '완벽 방패',
      emoji: '🎯',
      coreRulePhrase: '한 치의 오점도 없이 완벽히 해내야만 비난받지 않고 가치를 인정받는다.',
      protectionOrigin: '과거 실수했을 때 받았던 비난이나 무시, 부족한 사람으로 보일까 봐 느꼈던 공포를 막기 위해 스스로에게 입힌 갑옷입니다.',
      currentCost: '끝없는 성과 압박과 만성 피로에 시달리며, 사소한 실수에도 극심한 자기 검열과 자책을 겪게 됩니다.',
      awarenessPhrase: '"아, 내 완벽 방패가 나를 지키려고 또 서두르고 있구나."',
      exceptionExperiment: '오늘 80% 정도 정성을 들인 사소한 작업을 "이 정도면 충분히 훌륭해"라며 스스로 마무리해 보기',
      flexibleNewRule: '실수해도 내 존재 가치는 안전하다. 완벽함보다 소중한 것은 나의 평온과 지속 가능한 성장이다.',
    ),
    SurvivalRuleType.pleasing: SurvivalRuleProfile(
      type: SurvivalRuleType.pleasing,
      title: '과잉 순응 & 감정 조율사',
      shortTag: '순응 조율',
      emoji: '🕊️',
      coreRulePhrase: '상대방의 기분과 필요를 먼저 맞춰주고 거절하지 않아야 버림받지 않고 안전하다.',
      protectionOrigin: '관계에서 소외되거나 미움받아 혼자가 될지도 모른다는 깊은 불안으로부터 나를 지키기 위해 발달한 레이더입니다.',
      currentCost: '내 진짜 감정과 욕구를 삼키느라 속으로 억울함과 서운함이 쌓이고, 타인의 눈치를 보느라 쉽게 방전됩니다.',
      awarenessPhrase: '"타인의 기분은 타인의 몫이며, 내가 모든 사람을 웃게 만들 필요는 없다."',
      exceptionExperiment: '오늘 부담스러운 부탁 하나에 "지금은 어려울 것 같아요"라고 정중하고 부드럽게 거절해 보기',
      flexibleNewRule: '거절하더라도 좋은 관계는 유지된다. 나의 경계와 욕구를 존중할 때 관계는 더 진실해진다.',
    ),
    SurvivalRuleType.hyperControl: SurvivalRuleProfile(
      type: SurvivalRuleType.hyperControl,
      title: '과잉 통제 & 불안 파수꾼',
      shortTag: '통제 파수꾼',
      emoji: '🏰',
      coreRulePhrase: '모든 상황과 변수를 미리 통제하고 쥐고 있어야만 파국을 막을 수 있다.',
      protectionOrigin: '예측하지 못한 혼란이나 무력한 상황에서 느꼈던 깊은 공포를 다시 겪지 않기 위해 세운 높은 성벽입니다.',
      currentCost: '뇌와 신경계가 늘 비상사태로 각성되어 있어 불확실성을 견디기 어렵고 휴식을 온전히 누리지 못합니다.',
      awarenessPhrase: '"내가 모든 것을 통제할 수는 없지만, 통제 밖의 일에서도 나는 잘 살아갈 수 있다."',
      exceptionExperiment: '오늘 계획에 없던 작은 돌발 상황이나 메뉴 선택을 즉흥에 맡겨보고 5분간 흐름을 지켜보기',
      flexibleNewRule: '통제권을 조금 내려놓아도 세상은 무너지지 않는다. 불확실성 속에도 예상치 못한 선물이 있다.',
    ),
    SurvivalRuleType.emotionalWall: SurvivalRuleProfile(
      type: SurvivalRuleType.emotionalWall,
      title: '철벽 방어 & 정서적 요새',
      shortTag: '철벽 요새',
      emoji: '🧱',
      coreRulePhrase: '누구에게도 약점을 보이거나 깊이 의지하지 않아야 배신이나 상처를 입지 않는다.',
      protectionOrigin: '믿었던 사람에게 입은 깊은 상처나 실망으로부터 내 연약한 마음을 봉인하기 위해 닫아건 철문입니다.',
      currentCost: '겉으로는 의연하고 독립적으로 보이지만, 속으로는 깊은 고립감과 공허함, 타인과의 거리감을 느낍니다.',
      awarenessPhrase: '"상처받을 위험이 있더라도, 진실하게 연결될 때 내 마음에 온기가 채워진다."',
      exceptionExperiment: '믿을 수 있는 가까운 사람에게 오늘 느낀 사소한 감정이나 고민 하나를 솔직히 털어놓아 보기',
      flexibleNewRule: '취약함을 드러내는 것은 나약함이 아닌 용기다. 안전한 사람에게는 마음의 빗장을 조금 열어도 괜찮다.',
    ),
    SurvivalRuleType.hyperResponsibility: SurvivalRuleProfile(
      type: SurvivalRuleType.hyperResponsibility,
      title: '과잉 책임 & 침묵의 짊어짐',
      shortTag: '과잉 책임',
      emoji: '🎒',
      coreRulePhrase: '내가 모든 짐을 짊어지고 참아내야만 집단과 관계가 무너지지 않는다.',
      protectionOrigin: '불안정하거나 갈등이 잦던 환경에서 문제를 수습하고 평화를 지키기 위해 일찍부터 어른이 되어야 했던 과거에서 비롯되었습니다.',
      currentCost: '남들의 짐까지 내 책임으로 떠안아 어깨가 무겁고, 힘들어도 도움을 청하지 못해 고독한 번아웃에 빠집니다.',
      awarenessPhrase: '"이것은 내 짐인가, 타인의 짐인가? 나는 세상의 모든 짐을 질 의무가 없다."',
      exceptionExperiment: '혼자 끙끙 앓던 사소한 일 하나를 동료나 지인에게 나누어 맡기거나 도움 요청해 보기',
      flexibleNewRule: '도움을 요청하는 것은 부끄러운 일이 아니다. 내 몫의 짐만 가볍게 질 때 더 오래 함께 걸을 수 있다.',
    ),
    SurvivalRuleType.preemptiveSurrender: SurvivalRuleProfile(
      type: SurvivalRuleType.preemptiveSurrender,
      title: '선제 포기 & 체념 방어막',
      shortTag: '선제 포기',
      emoji: '🥥',
      coreRulePhrase: '아예 기대하지 않고 시도하지 않아야 좌절과 수치심의 고통을 겪지 않는다.',
      protectionOrigin: '거듭된 실패나 거절로 인해 느꼈던 뼈아픈 무력감으로부터 자존심을 보호하기 위해 쳐둔 안전지대입니다.',
      currentCost: '잠재력과 기회 앞에서 지레 물러서게 되며, 삶에 설렘과 활력이 사라지고 무기력감이 굳어집니다.',
      awarenessPhrase: '"실패해도 내 존엄은 훼손되지 않는다. 시도 자체가 이미 아름다운 전진이다."',
      exceptionExperiment: '결과에 대한 부담 없이, 평소 해보고 싶었던 아주 사소한 행동(3분) 하나를 가볍게 시도해 보기',
      flexibleNewRule: '결과가 어떠하든 시도하는 모든 과정은 성장의 자산이다. 나는 다시 시작할 힘이 있다.',
    ),
  };
}

/// 삶의 규칙 문항 선택지 모델
class SurvivalRuleOption {
  final String id;
  final String text;
  final SurvivalRuleType archetype;
  final int rigidityWeight; // 1 ~ 3점

  const SurvivalRuleOption({
    required this.id,
    required this.text,
    required this.archetype,
    required this.rigidityWeight,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'archetype': archetype.name,
        'rigidityWeight': rigidityWeight,
      };

  factory SurvivalRuleOption.fromJson(Map<String, dynamic> json) {
    return SurvivalRuleOption(
      id: json['id'] as String,
      text: json['text'] as String,
      archetype: SurvivalRuleType.values.firstWhere(
        (e) => e.name == json['archetype'],
        orElse: () => SurvivalRuleType.overachieving,
      ),
      rigidityWeight: json['rigidityWeight'] as int? ?? 2,
    );
  }
}

/// 삶의 규칙 진단 문항 모델
class SurvivalRuleQuestion {
  final String id;
  final String situationTitle;
  final String questionPrompt;
  final String dilemmaContext;
  final List<SurvivalRuleOption> options;

  const SurvivalRuleQuestion({
    required this.id,
    required this.situationTitle,
    required this.questionPrompt,
    required this.dilemmaContext,
    required this.options,
  });

  static const List<SurvivalRuleQuestion> defaultQuestions = [
    // 1. 실수와 평가의 순간
    SurvivalRuleQuestion(
      id: 'sr_q1',
      situationTitle: '실수 & 결함의 순간',
      questionPrompt: '중요한 일이나 대화에서 사소한 실수를 저질렀을 때, 내 안에서 가장 먼저 작동하는 삶의 규칙은?',
      dilemmaContext: '누구나 실수할 수 있는 상황이지만...',
      options: [
        SurvivalRuleOption(
          id: 'sr1_a',
          text: '"한 치의 오점도 없었어야 했는데... 밤을 새워서라도 완벽하게 바로잡아야 해."',
          archetype: SurvivalRuleType.overachieving,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr1_b',
          text: '"상대방이 나 때문에 기분 상했을까 봐 거듭 사과하고 상대 반응만 살피게 돼."',
          archetype: SurvivalRuleType.pleasing,
          rigidityWeight: 2,
        ),
        SurvivalRuleOption(
          id: 'sr1_c',
          text: '"이 실수로 모든 게 틀어질까 봐 다음 발생 가능한 모든 시나리오를 다 통제하려 해."',
          archetype: SurvivalRuleType.hyperControl,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr1_d',
          text: '"어차피 내가 하는 일이 다 그렇지... 더 수치스러워지기 전에 그냥 손을 떼고 싶어."',
          archetype: SurvivalRuleType.preemptiveSurrender,
          rigidityWeight: 2,
        ),
      ],
    ),

    // 2. 무리한 부탁과 경계
    SurvivalRuleQuestion(
      id: 'sr_q2',
      situationTitle: '부탁 & 거절의 딜레마',
      questionPrompt: '내 일정도 빠듯한데 부담스러운 부탁이나 요구를 받았을 때, 내 맘을 옥죄는 규칙은?',
      dilemmaContext: '거절해도 정당한 상황이지만...',
      options: [
        SurvivalRuleOption(
          id: 'sr2_a',
          text: '"거절했다가 상대방이 실망하거나 나를 이기적이라고 볼까 봐 차마 거절 못 해."',
          archetype: SurvivalRuleType.pleasing,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr2_b',
          text: '"내가 맡아서 완벽하게 처리해내는 능력을 보여줘야 인정받을 수 있어."',
          archetype: SurvivalRuleType.overachieving,
          rigidityWeight: 2,
        ),
        SurvivalRuleOption(
          id: 'sr2_c',
          text: '"결국 이 일도 내가 다 짊어져야 일이 엉망이 되지 않고 유지될 거야."',
          archetype: SurvivalRuleType.hyperResponsibility,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr2_d',
          text: '"애초에 이런 곤란한 관계에 얽히지 않게 다음부턴 사람들과 더 거리를 둬야겠어."',
          archetype: SurvivalRuleType.emotionalWall,
          rigidityWeight: 2,
        ),
      ],
    ),

    // 3. 불확실성과 돌발 상황
    SurvivalRuleQuestion(
      id: 'sr_q3',
      situationTitle: '불확실성 & 돌발 변수',
      questionPrompt: '내 계획대로 흘러가지 않고 예기치 못한 변수나 위기가 닥쳤을 때 나를 지배하는 규칙은?',
      dilemmaContext: '세상 모든 일을 예측할 수는 없지만...',
      options: [
        SurvivalRuleOption(
          id: 'sr3_a',
          text: '"모든 변수를 내 손아귀에 쥐고 있어야만 해. 빈틈이 생기면 큰일 나."',
          archetype: SurvivalRuleType.hyperControl,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr3_b',
          text: '"이 모든 혼란을 내가 책임지고 해결해야만 해. 누구도 나만큼 감당 못 해."',
          archetype: SurvivalRuleType.hyperResponsibility,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr3_c',
          text: '"어차피 통제 안 될 거 미리 포기하고 기대치를 바닥으로 낮추는 게 덜 아파."',
          archetype: SurvivalRuleType.preemptiveSurrender,
          rigidityWeight: 2,
        ),
        SurvivalRuleOption(
          id: 'sr3_d',
          text: '"혼란스러워도 티 내지 않고 차갑고 냉정하게 내 감정을 차단해야 안전해."',
          archetype: SurvivalRuleType.emotionalWall,
          rigidityWeight: 2,
        ),
      ],
    ),

    // 4. 관계의 섭섭함과 거리두기
    SurvivalRuleQuestion(
      id: 'sr_q4',
      situationTitle: '상처 & 마음의 빗장',
      questionPrompt: '가까운 사람에게 서운하거나 상처받았을 때, 내 마음이 반사적으로 취하는 방어 규칙은?',
      dilemmaContext: '솔직한 대화로 풀 수도 있지만...',
      options: [
        SurvivalRuleOption(
          id: 'sr4_a',
          text: '"괜히 속마음 털어놔봤자 약점만 잡혀. 마음의 문을 닫고 혼자 삭히는 게 안전해."',
          archetype: SurvivalRuleType.emotionalWall,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr4_b',
          text: '"갈등이 커지면 관계가 깨질 테니, 내가 서운한 티 내지 않고 웃으며 넘어가야 해."',
          archetype: SurvivalRuleType.pleasing,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr4_c',
          text: '"내가 완벽한 사람이었다면 이런 대우를 받지 않았을 텐데... 더 완벽해져야 해."',
          archetype: SurvivalRuleType.overachieving,
          rigidityWeight: 2,
        ),
        SurvivalRuleOption(
          id: 'sr4_d',
          text: '"역시 사람은 믿을 게 못 돼. 인간관계 자체에 기대를 접자."',
          archetype: SurvivalRuleType.preemptiveSurrender,
          rigidityWeight: 3,
        ),
      ],
    ),

    // 5. 집단의 문제와 책임 분담
    SurvivalRuleQuestion(
      id: 'sr_q5',
      situationTitle: '역할 & 짊어짐의 무게',
      questionPrompt: '팀이나 가족, 모임에서 일이 삐걱거리거나 누군가 일을 미룰 때 내 안의 규칙은?',
      dilemmaContext: '함께 나누어야 할 짐이지만...',
      options: [
        SurvivalRuleOption(
          id: 'sr5_a',
          text: '"내가 다 짊어지고 밤새서라도 메워야 해. 내가 안 하면 결국 파탄 날 거야."',
          archetype: SurvivalRuleType.hyperResponsibility,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr5_b',
          text: '"남들에게 맡기면 불안해서 못 봐. 내가 A부터 Z까지 직접 확인하고 통제해야 해."',
          archetype: SurvivalRuleType.hyperControl,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr5_c',
          text: '"싫은 소리 했다가 분위기 어색해질까 봐 내가 그냥 참고 조금 더 하고 말지."',
          archetype: SurvivalRuleType.pleasing,
          rigidityWeight: 2,
        ),
        SurvivalRuleOption(
          id: 'sr5_d',
          text: '"남들에게 아쉬운 소리 하거나 부탁하느니, 내 일만 딱 끝내고 선을 긋겠어."',
          archetype: SurvivalRuleType.emotionalWall,
          rigidityWeight: 2,
        ),
      ],
    ),

    // 6. 새로운 도전과 기회
    SurvivalRuleQuestion(
      id: 'sr_q6',
      situationTitle: '도전 & 가능성의 문턱',
      questionPrompt: '내가 정말 원하던 새로운 기회나 꿈 앞에 섰을 때, 나를 가로막는 무의식 규칙은?',
      dilemmaContext: '설레는 마음도 분명 있지만...',
      options: [
        SurvivalRuleOption(
          id: 'sr6_a',
          text: '"어차피 도전했다가 실패하면 상처만 커. 아예 시도하지 않는 게 지혜로운 거야."',
          archetype: SurvivalRuleType.preemptiveSurrender,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr6_b',
          text: '"완벽하게 준비되고 성공이 100% 보장될 때까지는 절대 시작하면 안 돼."',
          archetype: SurvivalRuleType.overachieving,
          rigidityWeight: 3,
        ),
        SurvivalRuleOption(
          id: 'sr6_c',
          text: '"모든 잠재적 리스크와 실패 시나리오를 다 검증하고 통제할 수 있어야 해."',
          archetype: SurvivalRuleType.hyperControl,
          rigidityWeight: 2,
        ),
        SurvivalRuleOption(
          id: 'sr6_d',
          text: '"내가 지금 맡고 있는 다른 책임과 사람들을 두고 내 꿈을 좇는 건 이기적이야."',
          archetype: SurvivalRuleType.hyperResponsibility,
          rigidityWeight: 3,
        ),
      ],
    ),
  ];
}

/// 답변 데이터
class SurvivalRuleAnswer {
  final String questionId;
  final SurvivalRuleOption option;

  const SurvivalRuleAnswer({
    required this.questionId,
    required this.option,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'option': option.toJson(),
      };

  factory SurvivalRuleAnswer.fromJson(Map<String, dynamic> json) {
    return SurvivalRuleAnswer(
      questionId: json['questionId'] as String,
      option: SurvivalRuleOption.fromJson(json['option'] as Map<String, dynamic>),
    );
  }
}

/// 삶의 규칙 검사 종합 결과 모델
class SurvivalRuleTestResult {
  final String id;
  final DateTime createdAt;
  final List<SurvivalRuleAnswer> answers;
  final SurvivalRuleProfile dominantRule;
  final SurvivalRuleProfile? secondaryRule;
  final int rigidityScore; // 0 ~ 100점
  final RuleRigidityLevel rigidityLevel;
  final Map<SurvivalRuleType, int> archetypeScores;
  final String diagnosisLandscape;
  final RestPrescription prescription;
  final CurationItem curation;

  SurvivalRuleTestResult({
    required this.id,
    required this.createdAt,
    required this.answers,
    required this.dominantRule,
    this.secondaryRule,
    required this.rigidityScore,
    required this.rigidityLevel,
    required this.archetypeScores,
    required this.diagnosisLandscape,
    required this.prescription,
    required this.curation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'dominantRuleType': dominantRule.type.name,
        'secondaryRuleType': secondaryRule?.type.name,
        'rigidityScore': rigidityScore,
        'rigidityLevel': rigidityLevel.name,
        'archetypeScores': archetypeScores.map((k, v) => MapEntry(k.name, v)),
        'diagnosisLandscape': diagnosisLandscape,
        'prescription': prescription.toJson(),
        'curation': curation.toJson(),
      };

  factory SurvivalRuleTestResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List<dynamic>? ?? [];
    final answers = rawAnswers
        .map((a) => SurvivalRuleAnswer.fromJson(a as Map<String, dynamic>))
        .toList();

    final domName = json['dominantRuleType'] as String? ?? 'overachieving';
    final secName = json['secondaryRuleType'] as String?;

    final domType = SurvivalRuleType.values.firstWhere(
      (e) => e.name == domName,
      orElse: () => SurvivalRuleType.overachieving,
    );
    final secType = secName != null
        ? SurvivalRuleType.values.firstWhere(
            (e) => e.name == secName,
            orElse: () => SurvivalRuleType.pleasing,
          )
        : null;

    final domProfile =
        SurvivalRuleProfile.profiles[domType] ?? SurvivalRuleProfile.profiles[SurvivalRuleType.overachieving]!;
    final secProfile =
        secType != null ? SurvivalRuleProfile.profiles[secType] : null;

    final rigidityScore = json['rigidityScore'] as int? ?? 50;
    final rigidityLevelName = json['rigidityLevel'] as String? ?? 'moderate';
    final rigidityLevel = RuleRigidityLevel.values.firstWhere(
      (e) => e.name == rigidityLevelName,
      orElse: () => RuleRigidityLevel.moderate,
    );

    final rawArchetypeScores =
        json['archetypeScores'] as Map<String, dynamic>? ?? {};
    final archetypeScores = <SurvivalRuleType, int>{};
    for (final entry in rawArchetypeScores.entries) {
      final t = SurvivalRuleType.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => SurvivalRuleType.overachieving,
      );
      archetypeScores[t] = (entry.value as num?)?.toInt() ?? 0;
    }

    return SurvivalRuleTestResult(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      answers: answers,
      dominantRule: domProfile,
      secondaryRule: secProfile,
      rigidityScore: rigidityScore,
      rigidityLevel: rigidityLevel,
      archetypeScores: archetypeScores,
      diagnosisLandscape: json['diagnosisLandscape'] as String? ??
          domProfile.coreRulePhrase,
      prescription: RestPrescription.fromJson(
          json['prescription'] as Map<String, dynamic>? ?? {}),
      curation: CurationItem.fromJson(
          json['curation'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// 삶의 규칙 분석 엔진
  static SurvivalRuleTestResult analyze(List<SurvivalRuleAnswer> answers) {
    final typeScores = <SurvivalRuleType, int>{};
    for (final t in SurvivalRuleType.values) {
      typeScores[t] = 0;
    }

    int totalRigidityWeight = 0;
    int maxPossibleRigidity = answers.length * 3;

    for (final ans in answers) {
      typeScores[ans.option.archetype] =
          (typeScores[ans.option.archetype] ?? 0) + 1;
      totalRigidityWeight += ans.option.rigidityWeight;
    }

    // 랭킹 정렬
    final sortedTypes = typeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dominantType = sortedTypes.first.key;
    final secondaryType =
        sortedTypes.length > 1 && sortedTypes[1].value > 0 ? sortedTypes[1].key : null;

    final dominantProfile = SurvivalRuleProfile.profiles[dominantType]!;
    final secondaryProfile =
        secondaryType != null ? SurvivalRuleProfile.profiles[secondaryType] : null;

    // 경직도 계산 (0 ~ 100)
    final rigidityScore = ((totalRigidityWeight / (maxPossibleRigidity == 0 ? 1 : maxPossibleRigidity)) * 100).round().clamp(0, 100);

    RuleRigidityLevel level;
    if (rigidityScore <= 35) {
      level = RuleRigidityLevel.flexible;
    } else if (rigidityScore <= 69) {
      level = RuleRigidityLevel.moderate;
    } else {
      level = RuleRigidityLevel.rigid;
    }

    // 맞춤 처방 및 큐레이션 생성
    final prescription = _generatePrescription(dominantType, level);
    final curation = _generateCuration(dominantType);

    final diagnosisLandscape = '${dominantProfile.title} (${dominantProfile.coreRulePhrase})';

    return SurvivalRuleTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      answers: answers,
      dominantRule: dominantProfile,
      secondaryRule: secondaryProfile,
      rigidityScore: rigidityScore,
      rigidityLevel: level,
      archetypeScores: typeScores,
      diagnosisLandscape: diagnosisLandscape,
      prescription: prescription,
      curation: curation,
    );
  }

  static RestPrescription _generatePrescription(
      SurvivalRuleType type, RuleRigidityLevel level) {
    switch (type) {
      case SurvivalRuleType.overachieving:
        return const RestPrescription(
          targetMode: RestMode.imagery,
          title: '푸른 숲속 완벽함 내려놓기 심상',
          reason: '성과에 대한 긴장을 늦추고, 있는 그대로 충분한 내면의 쉼을 경험합니다.',
          actionLabel: '숲속 쉼터로 이동하기',
          icon: Icons.landscape_outlined,
        );
      case SurvivalRuleType.pleasing:
        return const RestPrescription(
          targetMode: RestMode.breathing,
          title: '내 중심을 찾는 자비 호흡',
          reason: '타인의 시선에서 벗어나 내 가슴의 온기와 욕구를 먼저 챙겨봅니다.',
          actionLabel: '자비 호흡하러 가기',
          icon: Icons.air,
        );
      case SurvivalRuleType.hyperControl:
        return const RestPrescription(
          targetMode: RestMode.meditation,
          title: '흐르는 물결 이완 명상',
          reason: '통제하려는 손아귀의 힘을 풀고 삶의 자연스러운 흐름을 신뢰해 봅니다.',
          actionLabel: '이완 명상하러 가기',
          icon: Icons.self_improvement_outlined,
        );
      case SurvivalRuleType.emotionalWall:
        return const RestPrescription(
          targetMode: RestMode.imagery,
          title: '따스한 벽난로 온기 심상',
          reason: '굳어있던 마음의 성벽을 부드럽게 녹이고 안전한 온기를 느낍니다.',
          actionLabel: '따스한 쉼터 가기',
          icon: Icons.fireplace_outlined,
        );
      case SurvivalRuleType.hyperResponsibility:
        return const RestPrescription(
          targetMode: RestMode.breathing,
          title: '어깨 짐 내려놓기 날숨',
          reason: '내 몫이 아닌 타인의 짐을 편안하게 내려놓고 가벼움을 되찾습니다.',
          actionLabel: '날숨 이완하러 가기',
          icon: Icons.air,
        );
      case SurvivalRuleType.preemptiveSurrender:
        return const RestPrescription(
          targetMode: RestMode.meditation,
          title: '작은 불씨를 지피는 용기 명상',
          reason: '좌절의 두려움을 딛고, 지금 할 수 있는 작은 한 걸음의 힘을 깨웁니다.',
          actionLabel: '용기 명상하러 가기',
          icon: Icons.self_improvement_outlined,
        );
    }
  }

  static CurationItem _generateCuration(SurvivalRuleType type, [int? seed]) {
    return PleasantActivityPool.getSurvivalRuleActivity(type, seed);
  }
}
