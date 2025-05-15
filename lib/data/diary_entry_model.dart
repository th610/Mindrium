import 'package:cloud_firestore/cloud_firestore.dart';

// 감정일기 하나를 표현하는 데이터 모델
class DiaryEntryModel {
  final String id; // daysSinceJoin ID
  final String userId; // 사용자 ID
  final DateTime date; // 작성된 날짜 및 시간
  final List<String> emotion; // 선택한 감정 이름
  final String note; // 사용자가 작성한 메모
  final PhotoModel? photo; // 선택적으로 첨부된 사진

  DiaryEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.emotion,
    required this.note,
    required this.photo,
  });

  int get dayId => int.parse(id);

  // Firestore 업로드용 JSON 변환
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'emotion': emotion,
    'note': note,
    'photo': photo?.toJson(),
  };

  // JSON 데이터를 모델 객체로 변환
  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) =>
      DiaryEntryModel(
        id: json['id'],
        userId: json['userId'],
        date: (json['date'] as Timestamp).toDate(),
        emotion: (json['emotion'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [],
        note: json['note'],
        photo: json['photo'] != null
            ? PhotoModel.fromJson(json['photo']) // photo가 있으면 파싱
            : null,
      );

  // 수정용 copyWith
  DiaryEntryModel copyWith({
    DateTime? date,
    List<String>? emotion,
    String? note,
    PhotoModel? photo,
  }) {
    return DiaryEntryModel(
      id: id, // 수정 불가 (고유 ID)
      userId: userId, // 수정 불가 (사용자 구분)
      date: date ?? this.date,
      emotion: emotion ?? this.emotion,
      note: note ?? this.note,
      photo: photo ?? this.photo,
    );
  }
}

// 첨부된 사진 정보 모델
class PhotoModel {
  final String id; // 고유 ID
  final String path; // 로컬 경로나 Firebase Storage 경로
  final DateTime timestamp; // 사진이 찍힌 시간 또는 첨부된 시간

  PhotoModel({
    required this.id,
    required this.path,
    required this.timestamp,
  });

  // JSON으로 변환 (Firestore 업로드용)
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'timestamp': timestamp.toIso8601String(),
  };

  // JSON에서 객체로 파싱
  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
    id: json['id'],
    path: json['path'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

