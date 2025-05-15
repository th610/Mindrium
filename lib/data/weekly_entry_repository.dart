import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/data/weekly_entry_model.dart';

// 주간 일기 공통 인터페이스
abstract class WeeklyEntryRepository {
  Future<List<WeeklyEntryModel>> fetchAllWeeklyEntriesForUser(String userId);

  Future<WeeklyEntryModel?> fetchWeeklyDiaryByWeekId({
    required String userId,
    required String weekId,
  });

  Future<void> saveWeeklyDiary(WeeklyEntryModel diary);
}

// main 용 dummy repo
class DummyWeeklyEntryRepository implements WeeklyEntryRepository {
  @override
  Future<List<WeeklyEntryModel>> fetchAllWeeklyEntriesForUser(String userId) async => [];

  @override
  Future<WeeklyEntryModel?> fetchWeeklyDiaryByWeekId({required String userId, required String weekId,}) async => null;

  @override
  Future<void> saveWeeklyDiary(WeeklyEntryModel diary) async {}
}

// Firestore 저장소
class FirestoreWeeklyEntryRepository implements WeeklyEntryRepository {
  final _firestore = FirebaseFirestore.instance;

  // 전체 주차 조회
  @override
  Future<List<WeeklyEntryModel>> fetchAllWeeklyEntriesForUser(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weekly_entries')
        .orderBy('id')
        .get();

    return snapshot.docs.map((doc) => WeeklyEntryModel.fromJson(doc.data())).toList();
  }

  // 주차 기준 조회
  @override
  Future<WeeklyEntryModel?> fetchWeeklyDiaryByWeekId({
    required String userId,
    required String weekId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weekly_entries')
        .doc(weekId)
        .get();

    if (!doc.exists) return null;

    return WeeklyEntryModel.fromJson(doc.data()!);
  }

  // 저장
  @override
  Future<void> saveWeeklyDiary(WeeklyEntryModel diary) async {
    await _firestore
        .collection('users')
        .doc(diary.userId)
        .collection('weekly_entries')
        .doc(diary.id)
        .set(diary.toJson());
  }
}

