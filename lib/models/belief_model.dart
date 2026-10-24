class BeliefTemplate {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String intermediateRule; // 삶의 규칙 (중간신념)
  final String coreFear;          // 밑바닥 두려움 (핵심신념)
  final String flexibleRule;       // 유연한 새 규칙 (적응적 신념)
  final String actionExperiment;   // 작은 행동 실험

  const BeliefTemplate({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.intermediateRule,
    required this.coreFear,
    required this.flexibleRule,
    required this.actionExperiment,
  });

  static const List<BeliefTemplate> presets = [
    BeliefTemplate(
      id: 'perfectionism',
      title: '완벽주의형',
      emoji: '🎯',
      description: '실수나 결함을 용납하지 못하고 늘 완벽을 추구하는 패턴',
      intermediateRule: '모든 일을 빈틈없이 완벽하게 해내야만 인정받을 수 있다.',
      coreFear: '나는 부족하고 무능한 사람이다.',
      flexibleRule: '실수해도 괜찮다. 실수는 성장의 과정이며, 완벽하지 않아도 내 가치는 충분하다.',
      actionExperiment: '오늘 작성하는 사소한 문서나 메시지의 작은 오타를 굳이 고치지 않고 넘어가 보기',
    ),
    BeliefTemplate(
      id: 'approval_seeking',
      title: '착한사람 (인정추구형)',
      emoji: '🤝',
      description: '거절을 못 하고 타인의 기대와 기분을 먼저 맞추려는 패턴',
      intermediateRule: '남들의 기분을 먼저 맞춰주고 거절하지 않아야 미움받거나 버림받지 않는다.',
      coreFear: '나는 있는 그대로의 모습으로는 사랑받을 수 없다.',
      flexibleRule: '모든 사람을 만족시킬 수는 없다. 거절하더라도 내 존재 가치는 훼손되지 않는다.',
      actionExperiment: '오늘 나에게 부담스러운 사소한 부탁 하나를 정중하게 거절해 보기',
    ),
    BeliefTemplate(
      id: 'excessive_control',
      title: '과도한 통제형',
      emoji: '🛡️',
      description: '불안을 피하기 위해 모든 상황을 미리 계획하고 통제하려는 패턴',
      intermediateRule: '모든 위험과 미래의 변수를 철저히 통제하고 대비해야만 안전하다.',
      coreFear: '세상은 너무나 위험하고, 나는 스스로를 지키기에 너무 취약하다.',
      flexibleRule: '모든 것을 통제할 수는 없다. 불확실성 속에서도 나는 충분히 잘 대처할 수 있다.',
      actionExperiment: '오늘 점심 메뉴를 계획 없이 발길 닿는 곳으로 정해보기',
    ),
    BeliefTemplate(
      id: 'self_sacrifice',
      title: '자기희생형',
      emoji: '🕯️',
      description: '내 감정과 욕구는 억누르고 오직 타인을 위해 양보하는 패턴',
      intermediateRule: '내 감정이나 욕구는 억누르고 양보해야만 갈등이 생기지 않고 평화롭다.',
      coreFear: '내 감정과 존재는 타인에게 별로 중요하지 않다.',
      flexibleRule: '내 감정과 욕구도 타인의 것만큼 존중받아야 할 소중한 권리다.',
      actionExperiment: '대화할 때 내가 좋아하는 것이나 나의 의견을 먼저 명확하게 표현해 보기',
    ),
    BeliefTemplate(
      id: 'avoidance_distancing',
      title: '거리두기 (회피형)',
      emoji: '🧱',
      description: '상처받는 것이 두려워 타인에게 깊은 마음을 열지 않는 패턴',
      intermediateRule: '남에게 너무 마음을 주거나 의지하지 않아야 상처받거나 배신당하지 않는다.',
      coreFear: '결국 사람들은 나를 실망시키거나 떠나갈 것이다.',
      flexibleRule: '상처받을 가능성이 있더라도, 진실하게 연결되는 관계는 삶에 깊은 의미를 준다.',
      actionExperiment: '가까운 사람에게 오늘 나의 사소한 고민이나 감정 하나를 솔직히 나눠보기',
    ),
    BeliefTemplate(
      id: 'impostor_defect',
      title: '가면증후군 (결함형)',
      emoji: '🎭',
      description: '남들에게 내 진짜 결함이나 부족한 모습이 들통날까 봐 불안한 패턴',
      intermediateRule: '나의 약점이나 서툰 점을 철저히 감추고 포장해야만 무시당하지 않는다.',
      coreFear: '내 진짜 본모습은 하자가 있고 사랑받을 자격이 없다.',
      flexibleRule: '누구에게나 서툰 점과 약점이 있다. 불완전한 모습 그대로도 존중받을 가치가 있다.',
      actionExperiment: '가까운 동료나 지인에게 내가 모르는 것이나 사소한 실수를 솔직히 털어놓아 보기',
    ),
    BeliefTemplate(
      id: 'learned_helplessness',
      title: '체념 (무기력형)',
      emoji: '🥀',
      description: '노력해도 상황이 달라지지 않을 것이라 믿고 쉽게 포기하는 패턴',
      intermediateRule: '어차피 해봤자 안 될 테니 아예 기대하지도, 시도하지도 않는 것이 덜 고통스럽다.',
      coreFear: '나는 내 인생의 어떤 것도 바꿀 수 없는 무력한 존재다.',
      flexibleRule: '모든 것을 바꿀 수는 없지만, 지금 내가 통제할 수 있는 작은 한 걸음은 분명히 있다.',
      actionExperiment: '내가 통제할 수 있는 아주 사소한 3분짜리 작업 하나를 정해 바로 완료해 보기',
    ),
    BeliefTemplate(
      id: 'dependency_indecision',
      title: '의존 (우유부단형)',
      emoji: '🪆',
      description: '스스로 판단하기 두려워 늘 타인의 결정과 확인에 의존하는 패턴',
      intermediateRule: '스스로 결정하면 반드시 잘못될 것이므로, 타인의 확신과 승인을 받아야만 안전하다.',
      coreFear: '나는 혼자서는 아무것도 제대로 결정하고 책임질 수 없는 미숙한 사람이다.',
      flexibleRule: '내 선택이 완벽하지 않아도 괜찮다. 실수하면서 배우고 스스로를 신뢰할 수 있다.',
      actionExperiment: '사소한 일상 선택(메뉴, 옷 등)을 남에게 묻지 않고 내 직관으로 10초 안에 결정해 보기',
    ),
  ];
}

class UserBeliefEntry {
  final String id;
  final String title;
  final String emoji;
  final String intermediateRule;
  final String coreFear;
  final String flexibleRule;
  final String actionExperiment;
  final bool isCompletedExperiment;
  final DateTime createdAt;
  final String? sourceThought; // 출발점이 된 생각 (하향 화살표 연계 시)

  UserBeliefEntry({
    required this.id,
    required this.title,
    this.emoji = '🌿',
    required this.intermediateRule,
    required this.coreFear,
    required this.flexibleRule,
    required this.actionExperiment,
    this.isCompletedExperiment = false,
    required this.createdAt,
    this.sourceThought,
  });

  UserBeliefEntry copyWith({
    String? id,
    String? title,
    String? emoji,
    String? intermediateRule,
    String? coreFear,
    String? flexibleRule,
    String? actionExperiment,
    bool? isCompletedExperiment,
    DateTime? createdAt,
    String? sourceThought,
  }) {
    return UserBeliefEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      intermediateRule: intermediateRule ?? this.intermediateRule,
      coreFear: coreFear ?? this.coreFear,
      flexibleRule: flexibleRule ?? this.flexibleRule,
      actionExperiment: actionExperiment ?? this.actionExperiment,
      isCompletedExperiment: isCompletedExperiment ?? this.isCompletedExperiment,
      createdAt: createdAt ?? this.createdAt,
      sourceThought: sourceThought ?? this.sourceThought,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'intermediateRule': intermediateRule,
    'coreFear': coreFear,
    'flexibleRule': flexibleRule,
    'actionExperiment': actionExperiment,
    'isCompletedExperiment': isCompletedExperiment,
    'createdAt': createdAt.toIso8601String(),
    'sourceThought': sourceThought,
  };

  factory UserBeliefEntry.fromJson(Map<String, dynamic> json) {
    return UserBeliefEntry(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '나의 마음 신념',
      emoji: json['emoji'] as String? ?? '🌿',
      intermediateRule: json['intermediateRule'] as String? ?? '',
      coreFear: json['coreFear'] as String? ?? '',
      flexibleRule: json['flexibleRule'] as String? ?? '',
      actionExperiment: json['actionExperiment'] as String? ?? '',
      isCompletedExperiment: json['isCompletedExperiment'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      sourceThought: json['sourceThought'] as String?,
    );
  }
}
