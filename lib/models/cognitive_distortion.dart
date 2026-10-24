class CognitiveDistortion {
  final String id;
  final String name;
  final String shortDesc;
  final String example;
  final String reframingQuestion;
  final List<String> patterns;

  const CognitiveDistortion({
    required this.id,
    required this.name,
    required this.shortDesc,
    required this.example,
    required this.reframingQuestion,
    required this.patterns,
  });
}

class CognitiveDistortionDatabase {
  static const List<CognitiveDistortion> all = [
    CognitiveDistortion(
      id: 'mind_reading',
      name: '마음 읽기 (독심술)',
      shortDesc: '상대방의 생각이나 의도를 명확한 근거 없이 부정적으로 단정 짓는 것',
      example: '"저 사람은 분명 날 싫어해서 아는 척도 안 한 거야."',
      reframingQuestion: '상대방의 마음을 확인할 수 있는 객관적인 증거가 있나요? 다른 사정이 있었던 것은 아닐까요?',
      patterns: [
        '싫어', '무시', '한심', '비웃', '욕할', '날 안 좋게', '생각할 거', '속으로는',
        '눈치', '실망', '못마땅', '날 싫', '날 안 좋아',
      ],
    ),
    CognitiveDistortion(
      id: 'black_and_white',
      name: '흑백논리 (이분법적 사고)',
      shortDesc: '중간이나 회색지대를 인정하지 않고 전부 아니면 전무로 극단적으로 판단하는 것',
      example: '"완벽하게 성공하지 못했으니 이번 일은 완전히 실패한 거야."',
      reframingQuestion: '0과 100 사이의 중간 회색지대는 없을까요? 부분적인 성과나 배움은 무엇인가요?',
      patterns: [
        '완전 망', '완전히 망', '전부 끝', '다 끝', '하나도 안', '완벽하지',
        '완벽해야', '실패작', '100% 망', '모두 엉망', '전혀 소용', '완전 망했',
      ],
    ),
    CognitiveDistortion(
      id: 'should_statements',
      name: '당위적 사고 (~해야만 해)',
      shortDesc: '자신이나 타인에게 융통성 없는 엄격한 규칙과 의무를 강요하는 것',
      example: '"나는 어떤 상황에서도 절대 실수해서는 안 돼."',
      reframingQuestion: '\'반드시 ~해야 한다\' 대신 \'~하면 더 좋겠다\'로 표현을 부드럽게 바꾸어볼 수 있을까요?',
      patterns: [
        '해야만', '해야 해', '하면 안', '해서는 안', '반드시', '틀림없이',
        '절대로', '당연히 ~해야', '마땅히', '무조건', '해야지',
      ],
    ),
    CognitiveDistortion(
      id: 'catastrophizing',
      name: '파국화 (재앙화)',
      shortDesc: '작은 실수나 부정적인 사건을 최악의 파멸적인 결과로 확대 해석하는 것',
      example: '"한 번 실수했으니 내 인생은 이제 끝장났어."',
      reframingQuestion: '내가 두려워하는 최악의 시나리오가 실제로 일어날 확률은 얼마나 되나요? 최악의 경우에도 대처할 방법은 무엇인가요?',
      patterns: [
        '끝장', '망했', '망하', '망함', '인생 끝', '파멸', '돌이킬 수 없', '최악',
        '감당할 수 없', '회복 불가능', '지옥', '끝이다',
      ],
    ),
    CognitiveDistortion(
      id: 'personalization',
      name: '개인화 (내 탓하기)',
      shortDesc: '자신이 통제할 수 없거나 다양한 원인이 있는 일의 책임을 전적으로 자신에게 돌리는 것',
      example: '"오늘 회의 분위기가 안 좋았던 것은 다 내가 부족해서야."',
      reframingQuestion: '이 상황에 영향을 미친 다른 외부 요인이나 상황적 배경은 없었나요? 전적으로 내 책임인가요?',
      patterns: [
        '나 때문', '내 탓', '내가 부족', '내가 못나', '내 잘못', '내가 문제',
        '내가 망쳐', '나만 없', '나 땜',
      ],
    ),
    CognitiveDistortion(
      id: 'overgeneralization',
      name: '과도한 일반화',
      shortDesc: '단 한 번의 부정적인 사건을 근거로 모든 상황이 항상 그럴 것이라고 단정 짓는 것',
      example: '"이번 면접에 떨어졌으니 나는 앞으로도 평생 어디에도 취업 못할 거야."',
      reframingQuestion: '이번 단 한 번의 경험을 모든 미래와 연결 짓고 있지는 않나요? 잘 풀렸던 예외는 없었나요?',
      patterns: [
        '항상 이래', '항상 나만', '항상', '매번', '늘 이래', '언제나', '한 번도',
        '평생', '앞으로도 계속', '매일 이 모양',
      ],
    ),
    CognitiveDistortion(
      id: 'labeling',
      name: '이름표 붙이기 (낙인찍기)',
      shortDesc: '하나의 행동이나 실수에 기반해 자신이나 타인에게 부정적인 고정관념의 꼬리표를 붙이는 것',
      example: '"나는 구제불능의 실패자이고 무능한 사람이야."',
      reframingQuestion: '그 행동이나 실수가 나라는 사람 전체의 가치를 규정할 수 있나요?',
      patterns: [
        '패배자', '실패자', '구제불능', '바보', '멍청이', '무능', '쓸모없는',
        '쓰레기', '바보같', '한심한', '찌질',
      ],
    ),
    CognitiveDistortion(
      id: 'emotional_reasoning',
      name: '감정적 추론',
      shortDesc: '자신의 부정적인 감정을 객관적인 사실이자 진실로 받아들이는 것',
      example: '"불안한 느낌이 드는 걸 보니 분명히 나쁜 일이 일어날 거야."',
      reframingQuestion: '내가 느끼는 감정과 눈앞에 존재하는 실제 사실을 분리해서 바라볼 수 있나요?',
      patterns: [
        '느낌이 그래', '기분이 그러니', '불안하니까 분명', '느낌상', '직감적으로',
      ],
    ),
  ];

  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// 입력된 생각(문장)을 분석하여 매칭되는 인지오류 목록을 반환합니다.
  static List<CognitiveDistortion> detectDistortions(String thought) {
    if (thought.trim().isEmpty) return [];

    final cleanText = thought.toLowerCase().replaceAll(_whitespaceRegex, ' ');
    final matched = <CognitiveDistortion>[];

    for (final dist in all) {
      bool isMatch = false;
      for (final p in dist.patterns) {
        if (cleanText.contains(p.toLowerCase())) {
          isMatch = true;
          break;
        }
      }
      if (isMatch) {
        matched.add(dist);
      }
    }

    return matched;
  }
}
