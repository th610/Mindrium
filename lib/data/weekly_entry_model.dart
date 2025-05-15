class WeeklyEntryModel {
  final String id; // 문서 ID == 주차 ID
  final String userId; // 사용자
  final String weeklyNote; // 주간 일기
  final String thoughtNote; // 생각 변화
  final double anxietyScore; // 불안 점수
  final List<String> emotions; // 감정 선택
  final DateTime date; // 날짜

  WeeklyEntryModel({
    required this.id,
    required this.userId,
    required this.weeklyNote,
    required this.thoughtNote,
    required this.anxietyScore,
    required this.emotions,
    required this.date,
  });

  int get weekId => int.parse(id);

  factory WeeklyEntryModel.fromJson(Map<String, dynamic> json) {
    return WeeklyEntryModel(
      id: json['id'],
      userId: json['userId'],
      weeklyNote: json['weeklyNote'],
      thoughtNote: json['thoughtNote'],
      anxietyScore: (json['anxietyScore'] as num).toDouble(),
      emotions: (json['emotions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.padLeft(3, '0'),
    'userId': userId,
    'weeklyNote': weeklyNote,
    'thoughtNote': thoughtNote,
    'anxietyScore': anxietyScore,
    'emotions': emotions,
    'date': date.toIso8601String(),
  };

  WeeklyEntryModel copyWith({
    String? weeklyNote,
    String? thoughtNote,
    double? anxietyScore,
    List<String>? emotions,
    DateTime? date,
  }) {
    return WeeklyEntryModel(
      id: id,
      userId: userId,
      weeklyNote: weeklyNote ?? this.weeklyNote,
      thoughtNote: thoughtNote ?? this.thoughtNote,
      anxietyScore: anxietyScore ?? this.anxietyScore,
      emotions: emotions ?? this.emotions,
      date: date ?? this.date,
    );
  }
}
