import 'package:flutter/material.dart';
import '../models/belief_model.dart';
import '../models/mind_test_model.dart';
import '../screens/rest_tab.dart';
import 'pleasant_activity_pool.dart';

/// 핵심신념 검사 개별 문항 옵션
class BeliefTestOption {
  final String id;
  final String text;
  final String templateId; // perfectionism, approval_seeking, etc.
  final int weight; // 가중치 1 ~ 3

  const BeliefTestOption({
    required this.id,
    required this.text,
    required this.templateId,
    this.weight = 2,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'templateId': templateId,
        'weight': weight,
      };

  factory BeliefTestOption.fromJson(Map<String, dynamic> json) {
    return BeliefTestOption(
      id: json['id'] as String,
      text: json['text'] as String,
      templateId: json['templateId'] as String,
      weight: json['weight'] as int? ?? 2,
    );
  }
}

/// 핵심신념 검사 문항 모델
class BeliefTestQuestion {
  final String id;
  final String title;
  final String subtitle;
  final String categoryTag;
  final List<BeliefTestOption> options;

  const BeliefTestQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    required this.options,
  });

  static const List<BeliefTestQuestion> defaultQuestions = [
    // 1. 실수 및 실패 상황
    BeliefTestQuestion(
      id: 'bq_1',
      title: '내가 맡은 일에서 예상치 못한 실수나 결함이 생겼을 때',
      subtitle: '나를 가장 옥죄어 오는 내면의 생각은 무엇인가요?',
      categoryTag: '실수 & 결함',
      options: [
        BeliefTestOption(
          id: 'bq1_a',
          text: '"완벽하게 해내지 못하면 내 가치가 떨어지고 무능해 보여."',
          templateId: 'perfectionism',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq1_b',
          text: '"남들에게 내 진짜 결함과 부족한 모습이 들통난 것 같아 불안해."',
          templateId: 'impostor_defect',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq1_c',
          text: '"어차피 노력해도 안 될 일이었어. 그냥 다 그만두고 싶어."',
          templateId: 'learned_helplessness',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq1_d',
          text: '"내가 모든 변수를 더 철저히 통제하고 확인했어야 했는데..."',
          templateId: 'excessive_control',
          weight: 2,
        ),
      ],
    ),

    // 2. 대인관계 및 부탁 상황
    BeliefTestQuestion(
      id: 'bq_2',
      title: '부담스럽거나 곤란한 부탁을 받았을 때',
      subtitle: '거절하기 직전 내 머릿속을 스치는 가장 큰 불안은?',
      categoryTag: '관계 & 거절',
      options: [
        BeliefTestOption(
          id: 'bq2_a',
          text: '"거절하면 상대가 나를 싫어하거나 관계가 깨질까 봐 두려워."',
          templateId: 'approval_seeking',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq2_b',
          text: '"내 기분은 참고 내가 좀 손해 보더라도 참는 게 분란을 막는 길이야."',
          templateId: 'self_sacrifice',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq2_c',
          text: '"사람들과 너무 엮이지 말고 적당히 거리두고 피하는 게 안전해."',
          templateId: 'avoidance_distancing',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq2_d',
          text: '"이걸 어떻게 거절해야 할지 다른 사람에게 물어보고 확인받아야겠어."',
          templateId: 'dependency_indecision',
          weight: 2,
        ),
      ],
    ),

    // 3. 미래와 불확실성 상황
    BeliefTestQuestion(
      id: 'bq_3',
      title: '앞일이 불확실하고 예상할 수 없는 변화가 찾아왔을 때',
      subtitle: '내 마음에 가장 먼저 켜지는 방어기제는 무엇인가요?',
      categoryTag: '미래 & 통제',
      options: [
        BeliefTestOption(
          id: 'bq3_a',
          text: '"모든 위험과 시나리오를 미리 100% 계획해두지 않으면 잠이 안 와."',
          templateId: 'excessive_control',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq3_b',
          text: '"혼자서는 올바른 결정을 내릴 수 없어. 누군가 대신 결정해주면 좋겠어."',
          templateId: 'dependency_indecision',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq3_c',
          text: '"내가 완벽하게 통제해서 최고의 결과물로 증명해 보여야 해."',
          templateId: 'perfectionism',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq3_d',
          text: '"어차피 미래는 내가 바꿀 수 없으니 그냥 생각 안 하고 포기할래."',
          templateId: 'learned_helplessness',
          weight: 2,
        ),
      ],
    ),

    // 4. 감정 표현과 타인의 시선
    BeliefTestQuestion(
      id: 'bq_4',
      title: '속으로 서운하거나 화가 났을 때',
      subtitle: '내 감정을 밖으로 드러내지 못하는 가장 깊은 이유는?',
      categoryTag: '감정 & 표현',
      options: [
        BeliefTestOption(
          id: 'bq4_a',
          text: '"내 감정이나 욕구는 타인에게 별로 중요하지 않으니 묻어두는 게 나아."',
          templateId: 'self_sacrifice',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq4_b',
          text: '"괜히 속마음을 털어놨다가 나중에 상처받거나 약점 잡힐까 봐."',
          templateId: 'avoidance_distancing',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq4_c',
          text: '"좋은 사람으로 남아야 미움받지 않고 인정받을 수 있으니까."',
          templateId: 'approval_seeking',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq4_d',
          text: '"화내는 내 모습이 너무 미숙하고 결함투성이로 보일까 봐."',
          templateId: 'impostor_defect',
          weight: 2,
        ),
      ],
    ),

    // 5. 중요한 선택과 결정
    BeliefTestQuestion(
      id: 'bq_5',
      title: '인생의 중요한 갈림길이나 결정을 내려야 할 때',
      subtitle: '스스로 결정을 주저하게 만드는 생각은?',
      categoryTag: '선택 & 결단',
      options: [
        BeliefTestOption(
          id: 'bq5_a',
          text: '"내 선택이 잘못될까 봐 두려워 남들의 조언과 확신이 없으면 못 움직여."',
          templateId: 'dependency_indecision',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq5_b',
          text: '"한 치의 오점도 없는 완벽한 선택이어야만 해. 섣불리 결정할 수 없어."',
          templateId: 'perfectionism',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq5_c',
          text: '"돌발 변수가 생겨 통제를 벗어날까 봐 모든 리스크를 다 따져봐야 해."',
          templateId: 'excessive_control',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq5_d',
          text: '"어차피 내가 어떤 선택을 하든 인생이 달라지진 않을 거야."',
          templateId: 'learned_helplessness',
          weight: 2,
        ),
      ],
    ),

    // 6. 칭찬과 성과를 받았을 때
    BeliefTestQuestion(
      id: 'bq_6',
      title: '주변에서 나를 크게 칭찬하거나 인정해줄 때',
      subtitle: '칭찬을 순수하게 기뻐하지 못하고 스치는 생각은?',
      categoryTag: '칭찬 & 인정',
      options: [
        BeliefTestOption(
          id: 'bq6_a',
          text: '"운이 좋았을 뿐이야. 조만간 내 진짜 실력의 밑천이 드러날 텐데..."',
          templateId: 'impostor_defect',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq6_b',
          text: '"이번엔 잘했지만 다음에도 완벽해야 해. 기대치가 높아져서 더 부담돼."',
          templateId: 'perfectionism',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq6_c',
          text: '"이 기대를 저버리지 않으려면 앞으로도 남들의 부탁을 거절하면 안 돼."',
          templateId: 'approval_seeking',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq6_d',
          text: '"친해져서 너무 가까워지면 결국 실망하고 떠나갈 텐데..."',
          templateId: 'avoidance_distancing',
          weight: 2,
        ),
      ],
    ),

    // 7. 혼자만의 휴식 시간
    BeliefTestQuestion(
      id: 'bq_7',
      title: '아무것도 하지 않고 가만히 쉬고 있을 때',
      subtitle: '편안히 쉬지 못하고 나를 괴롭히는 마음의 소리는?',
      categoryTag: '휴식 & 자책',
      options: [
        BeliefTestOption(
          id: 'bq7_a',
          text: '"이렇게 게으르게 쉬고 있으면 남들에게 뒤처지고 무가치한 사람 같아."',
          templateId: 'perfectionism',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq7_b',
          text: '"나만 편히 쉬고 있으면 다른 사람들에게 미안하고 죄책감이 들어."',
          templateId: 'self_sacrifice',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq7_c',
          text: '"앞으로 닥칠 일들을 지금 미리 정리하고 통제해두어야 마음이 놓여."',
          templateId: 'excessive_control',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq7_d',
          text: '"쉬어도 충전이 안 되고, 아무 의욕도 안 생기는 무기력함에 갇힌 기분이야."',
          templateId: 'learned_helplessness',
          weight: 2,
        ),
      ],
    ),

    // 8. 상처와 고립의 순간
    BeliefTestQuestion(
      id: 'bq_8',
      title: '관계에서 상처를 입거나 소외감을 느꼈을 때',
      subtitle: '마음의 문을 걸어 잠그며 스스로에게 속삭이는 말은?',
      categoryTag: '상처 & 보호',
      options: [
        BeliefTestOption(
          id: 'bq8_a',
          text: '"결국 믿을 사람은 나뿐이야. 누구에게도 깊은 마음을 주지 말자."',
          templateId: 'avoidance_distancing',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq8_b',
          text: '"내가 더 완벽하고 착하게 맞춰줬어야 했는데, 내 잘못이야."',
          templateId: 'approval_seeking',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq8_c',
          text: '"내 진짜 부족하고 볼품없는 모습 때문에 외면당한 거야."',
          templateId: 'impostor_defect',
          weight: 2,
        ),
        BeliefTestOption(
          id: 'bq8_d',
          text: '"내가 참았어야 했는데... 내 감정을 표현한 게 후회돼."',
          templateId: 'self_sacrifice',
          weight: 2,
        ),
      ],
    ),
  ];
}

/// 사용자의 답변 기록
class BeliefTestAnswer {
  final String questionId;
  final BeliefTestOption option;

  const BeliefTestAnswer({
    required this.questionId,
    required this.option,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'option': option.toJson(),
      };

  factory BeliefTestAnswer.fromJson(Map<String, dynamic> json) {
    return BeliefTestAnswer(
      questionId: json['questionId'] as String,
      option: BeliefTestOption.fromJson(json['option'] as Map<String, dynamic>),
    );
  }
}

/// 핵심신념 검사 종합 결과 모델
class BeliefTestResult {
  final String id;
  final DateTime createdAt;
  final List<BeliefTestAnswer> answers;
  final BeliefTemplate dominantTemplate;
  final BeliefTemplate? secondaryTemplate;
  final Map<String, int> scores; // templateId -> score
  final String diagnosisTitle;
  final String diagnosisSummary;
  final RestPrescription prescription;
  final CurationItem curation;

  BeliefTestResult({
    required this.id,
    required this.createdAt,
    required this.answers,
    required this.dominantTemplate,
    this.secondaryTemplate,
    required this.scores,
    required this.diagnosisTitle,
    required this.diagnosisSummary,
    required this.prescription,
    required this.curation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'dominantTemplateId': dominantTemplate.id,
        'secondaryTemplateId': secondaryTemplate?.id,
        'scores': scores,
        'diagnosisTitle': diagnosisTitle,
        'diagnosisSummary': diagnosisSummary,
        'prescription': prescription.toJson(),
        'curation': curation.toJson(),
      };

  factory BeliefTestResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List<dynamic>? ?? [];
    final answers = rawAnswers
        .map((a) => BeliefTestAnswer.fromJson(a as Map<String, dynamic>))
        .toList();

    final domId = json['dominantTemplateId'] as String? ?? 'perfectionism';
    final secId = json['secondaryTemplateId'] as String?;

    final dom = BeliefTemplate.presets.firstWhere(
      (t) => t.id == domId,
      orElse: () => BeliefTemplate.presets.first,
    );

    final sec = secId != null
        ? BeliefTemplate.presets.firstWhere(
            (t) => t.id == secId,
            orElse: () => BeliefTemplate.presets[1],
          )
        : null;

    final rawScores = json['scores'] as Map<String, dynamic>? ?? {};
    final scores = <String, int>{};
    rawScores.forEach((k, v) {
      scores[k] = (v as num?)?.toInt() ?? 0;
    });

    return BeliefTestResult(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      answers: answers,
      dominantTemplate: dom,
      secondaryTemplate: sec,
      scores: scores,
      diagnosisTitle: json['diagnosisTitle'] as String? ?? dom.title,
      diagnosisSummary: json['diagnosisSummary'] as String? ?? dom.description,
      prescription: RestPrescription.fromJson(
          json['prescription'] as Map<String, dynamic>? ?? {}),
      curation: CurationItem.fromJson(
          json['curation'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// 핵심신념 분석 엔진
  static BeliefTestResult analyze(List<BeliefTestAnswer> answers) {
    final scoreMap = <String, int>{};
    for (final t in BeliefTemplate.presets) {
      scoreMap[t.id] = 0;
    }

    for (final ans in answers) {
      final tId = ans.option.templateId;
      scoreMap[tId] = (scoreMap[tId] ?? 0) + ans.option.weight;
    }

    // 랭킹 정렬
    final sorted = scoreMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dominantId = sorted.isNotEmpty ? sorted.first.key : 'perfectionism';
    final dominant = BeliefTemplate.presets.firstWhere(
      (t) => t.id == dominantId,
      orElse: () => BeliefTemplate.presets.first,
    );

    BeliefTemplate? secondary;
    if (sorted.length > 1 && sorted[1].value > 0) {
      secondary = BeliefTemplate.presets.firstWhere(
        (t) => t.id == sorted[1].key,
        orElse: () => BeliefTemplate.presets[1],
      );
    }

    // 맞춤 처방 및 큐레이션 도출
    RestPrescription prescription;

    switch (dominant.id) {
      case 'perfectionism':
        prescription = const RestPrescription(
          targetMode: RestMode.breathing,
          title: '불완전함 허용 이완 호흡',
          reason: '완벽해야 한다는 팽팽한 신경 긴장을 풀고 있는 그대로의 나를 수용합니다.',
          actionLabel: '마음쉼터에서 호흡하기',
          icon: Icons.air,
        );
        break;

      case 'approval_seeking':
      case 'self_sacrifice':
        prescription = const RestPrescription(
          targetMode: RestMode.imagery,
          title: '나만의 안전한 마음 요새 심상화',
          reason: '타인의 시선에서 벗어나 오롯이 나만을 위한 고요한 공간을 마음에 세웁니다.',
          actionLabel: '마음쉼터에서 풍경 감상하기',
          icon: Icons.landscape_outlined,
        );
        break;

      case 'excessive_control':
      case 'dependency_indecision':
        prescription = const RestPrescription(
          targetMode: RestMode.meditation,
          title: '불확실성 수용 명상',
          reason: '통제할 수 없는 미래의 걱정을 흘려보내고 현재의 호흡에 안착합니다.',
          actionLabel: '마음쉼터에서 명상하기',
          icon: Icons.self_improvement_outlined,
        );
        break;

      default:
        prescription = const RestPrescription(
          targetMode: RestMode.imagery,
          title: '평온의 심상화 풍경 여행',
          reason: '마음속 은신처에서 안전함과 온기를 충전하여 내면의 힘을 회복합니다.',
          actionLabel: '마음쉼터에서 회복하기',
          icon: Icons.landscape_outlined,
        );
        break;
    }

    final curation = PleasantActivityPool.getBeliefActivity(dominant.id);

    return BeliefTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      answers: answers,
      dominantTemplate: dominant,
      secondaryTemplate: secondary,
      scores: scoreMap,
      diagnosisTitle: '${dominant.emoji} ${dominant.title}',
      diagnosisSummary: dominant.description,
      prescription: prescription,
      curation: curation,
    );
  }
}
