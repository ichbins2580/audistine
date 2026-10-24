class TaskItem {
  final String id;
  final String title;
  final String? time; // 선택된 시간 (예: '오전 10:00')
  final bool isCompleted;
  final int? alarmMinutesBefore; // 알람 시점: 0(정시), 5(5분전), 10(10분전), 30(30분전), 60(1시간전), null(알람없음)
  final DateTime createdAt;
  final String forDate; // 'YYYY-MM-DD' 형태

  TaskItem({
    required this.id,
    required this.title,
    this.time,
    this.isCompleted = false,
    this.alarmMinutesBefore = 5,
    required this.createdAt,
    required this.forDate,
  });

  bool get hasAlarm => alarmMinutesBefore != null;

  String get alarmLabel {
    if (alarmMinutesBefore == null) return '';
    if (alarmMinutesBefore == 0) return '정시';
    if (alarmMinutesBefore == 60) return '1시간전';
    return '$alarmMinutesBefore분전';
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? time,
    bool? isCompleted,
    int? alarmMinutesBefore,
    bool clearAlarm = false,
    DateTime? createdAt,
    String? forDate,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      alarmMinutesBefore: clearAlarm ? null : (alarmMinutesBefore ?? this.alarmMinutesBefore),
      createdAt: createdAt ?? this.createdAt,
      forDate: forDate ?? this.forDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'time': time,
    'isCompleted': isCompleted,
    'alarmMinutesBefore': alarmMinutesBefore,
    'createdAt': createdAt.toIso8601String(),
    'forDate': forDate,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      time: json['time'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      alarmMinutesBefore: (json['alarmMinutesBefore'] as num?)?.toInt() ?? (json['hasFiveMinAlarm'] == true ? 5 : null),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      forDate: json['forDate'] as String? ?? '',
    );
  }
}
