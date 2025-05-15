import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';

// 일기 저장소 인터페이스
abstract class DiaryEntryRepository {
  Future<void> saveEntry(DiaryEntryModel entry);

  Future<List<DiaryEntryModel>> fetchAllEntriesForUser(String userId);

  Future<List<DiaryEntryModel>> fetchEntriesByWeek({
    required String userId,
    required int weekNumber,
  });

  Future<DiaryEntryModel?> fetchEntryByDaysSinceJoin({
    required String userId,
    required String id,
  });

  Future<DiaryEntryModel?> fetchEntriesByDate({
    required String userId,
    required DateTime date,
  });
}

// main 용 dummy repo
class DummyDiaryEntryRepository implements DiaryEntryRepository {
  @override
  Future<List<DiaryEntryModel>> fetchAllEntriesForUser(String userId) async => [];

  @override
  Future<DiaryEntryModel?> fetchEntriesByDate({required String userId, required DateTime date}) async => null;

  @override
  Future<List<DiaryEntryModel>> fetchEntriesByWeek({required String userId, required int weekNumber,}) async => [];

  @override
  Future<DiaryEntryModel?> fetchEntryByDaysSinceJoin({required String userId, required String id,}) async => null;

  @override
  Future<void> saveEntry(DiaryEntryModel entry) async {}
}


// firestore 기반 구현체
class FirestoreDiaryEntryRepository implements DiaryEntryRepository {
  final _firestore = FirebaseFirestore.instance;

  // 일기 저장
  @override
  Future<void> saveEntry(DiaryEntryModel entry) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(entry.userId)
        .collection('daily_entries')
        .doc(entry.id);

    await docRef.set(entry.toJson()); // photo 포함 전체 모델을 Json으로 저장
  }

  // 해당 사용자의 전체 일기 가져오기 (정렬 포함)
  @override
  Future<List<DiaryEntryModel>> fetchAllEntriesForUser(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_entries')
        .orderBy('id')
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntryModel.fromJson(doc.data()))
        .toList();
  }

  // 특정 주차의 일기 가져오기 (예: 1주차 = 1~7일차)
  @override
  Future<List<DiaryEntryModel>> fetchEntriesByWeek({
    required String userId,
    required int weekNumber,
  }) async {
    final start = (weekNumber - 1) * 7 + 1;
    final end = start + 6;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_entries')
        .orderBy('id')
        .where('id', isGreaterThanOrEqualTo: start.toString().padLeft(3, '0')) // String 비교를 위해 001 식으로 저장
        .where('id', isLessThanOrEqualTo: end.toString().padLeft(3, '0'))
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntryModel.fromJson(doc.data()))
        .toList();
  }

  // 특정 날짜 id의 일기 가져오기
  @override
  Future<DiaryEntryModel?> fetchEntryByDaysSinceJoin({
    required String userId,
    required String id,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_entries')
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return DiaryEntryModel.fromJson(doc.data()!);
  }

  // 특정 날짜의 일기 가져오기
  @override
  Future<DiaryEntryModel?> fetchEntriesByDate({
    required String userId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_entries')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DiaryEntryModel.fromJson(snapshot.docs.first.data());
  }

}

