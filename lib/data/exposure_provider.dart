import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../data/anxiety_cause.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/emotion.dart';

class ExposureProvider extends ChangeNotifier {
  List<String> selectedEmotions = [];
  String? photoPath;
  Map<String, String> photoPaths = {}; // 📸 사진 저장 구조 추가
  List<AnxietyCause> anxietyCauses = [];
  List<AnxietyCause> rawAnxietyCauses = [];
  int exposureLevel = 0;

  String currentScreen = '';
  bool isLoading = false;
  bool hasUnfinishedSession = false;

  void updateSelectedEmotions(List<String> emotions) {
    selectedEmotions = emotions;
    notifyListeners();
  }

  void updatePhotoPath(String? path) {
    photoPath = path;
    notifyListeners();
  }

  void updatePhotoForCause(String causeId, String photoPath) {
    photoPaths[causeId] = photoPath;
    notifyListeners();
  }

  String? getPhotoForCause(String causeId) {
    return photoPaths[causeId];
  }

  void updateAnxietyCauses(List<AnxietyCause> causes) {
    anxietyCauses = causes;
    notifyListeners();
  }

  void updateRawAnxietyCauseObjects(List<AnxietyCause> causes) {
    final uniqueCauses = <String, AnxietyCause>{};
    for (final cause in causes) {
      uniqueCauses[cause.id] = cause;
    }
    rawAnxietyCauses = uniqueCauses.values.toList();
    notifyListeners();
  }

  void updateExposureLevel(int level) {
    exposureLevel = level;
    notifyListeners();
  }

  void updateCurrentScreen(String screen) {
    currentScreen = screen;
    notifyListeners();
  }

  void updateHasUnfinishedSession(bool value) {
    hasUnfinishedSession = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void reset() {
    selectedEmotions = [];
    photoPath = null;
    photoPaths.clear();
    anxietyCauses = [];
    rawAnxietyCauses = [];
    exposureLevel = 0;
    currentScreen = '';
    isLoading = false;
    hasUnfinishedSession = false;
    notifyListeners();
  }

  void updateAnxietyCause(AnxietyCause updatedCause) {
    final index = rawAnxietyCauses.indexWhere((c) => c.id == updatedCause.id);
    if (index != -1) {
      rawAnxietyCauses[index] = updatedCause;
    }
    final index2 = anxietyCauses.indexWhere((c) => c.id == updatedCause.id);
    if (index2 != -1) {
      anxietyCauses[index2] = updatedCause;
    }
    notifyListeners();
  }

  void removeAnxietyCause(String id) {
    rawAnxietyCauses.removeWhere((c) => c.id == id);
    anxietyCauses.removeWhere((c) => c.id == id);
    photoPaths.remove(id);
    notifyListeners();
  }

  void reorderAnxietyCauses(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = rawAnxietyCauses.removeAt(oldIndex);
    rawAnxietyCauses.insert(newIndex, item);
    notifyListeners();
  }

  void initialize(List<AnxietyCause> causes, String initPhotoPath, List<String> emotions) {
    updateRawAnxietyCauseObjects(causes);
    updateAnxietyCauses(causes);
    updatePhotoPath(initPhotoPath);
    updateSelectedEmotions(emotions);
  }

  Future<void> saveAnxietyStateToFirestore(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(user.uid).set({
        'has_temporary_data': true,
        'current_screen': 'anxiety_ocean',
        'last_updated': FieldValue.serverTimestamp(),
        'photoPath': photoPath,
        'selectedEmotions': selectedEmotions,
      }, SetOptions(merge: true));

      final existingCauses = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_causes')
          .get();

      final batch = firestore.batch();
      for (var doc in existingCauses.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < rawAnxietyCauses.length; i++) {
        final cause = rawAnxietyCauses[i];
        final docRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('anxiety_causes')
            .doc(cause.id);

        batch.set(docRef, {
          'id': cause.id,
          'title': cause.title,
          'description': cause.description,
          'anxietyLevel': cause.anxietyLevel,
          'fishEmoji': cause.fishEmoji,
          'selectedEmotions': cause.selectedEmotions,
          'photoPath': photoPaths[cause.id],
          'order': i,
        });
      }

      await batch.commit();

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('저장 완료'),
            content: const Text('저장이 완료되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.settings.name == '/exposure');
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore 저장 중 오류: $e');
    }
  }

  Future<void> completeSession(BuildContext context, VoidCallback onCompleteDialog) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(user.uid).set({
        'has_temporary_data': false,
        'current_screen': '',
        'completed_at': FieldValue.serverTimestamp(),
        'photoPath': null,
        'selectedEmotions': null,
      }, SetOptions(merge: true));

      final existingCauses = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_causes')
          .get();

      final batch = firestore.batch();
      for (var doc in existingCauses.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      reset();

      if (context.mounted) {
        onCompleteDialog();
      }
    } catch (e) {
      debugPrint('세션 완료 처리 중 오류 발생: $e');
    }
  }

  Future<void> addAnxietyCause({
    required String title,
    required String description,
    required double anxietyLevel,
    required List<String> selectedEmotions,
  }) async {
    final isDuplicate = rawAnxietyCauses.any((c) =>
      c.title == title.trim() && c.description == description.trim());

    if (isDuplicate) return;

    final newCause = AnxietyCause(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
      anxietyLevel: anxietyLevel,
      fishEmoji: _getRandomUnusedEmoji(),
      selectedEmotions: selectedEmotions,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_causes')
          .doc(newCause.id)
          .set({
            'id': newCause.id,
            'title': newCause.title,
            'description': newCause.description,
            'anxietyLevel': newCause.anxietyLevel,
            'fishEmoji': newCause.fishEmoji,
            'selectedEmotions': selectedEmotions,
            'order': rawAnxietyCauses.length,
          });
    }

    rawAnxietyCauses.add(newCause);
    anxietyCauses.add(newCause);
    notifyListeners();
  }

  String _getRandomUnusedEmoji() {
    const emojis = ['🐟','🐠','🐡','🦈','🐋','🐳','🐬','🦐','🦑','🐙'];
    final used = rawAnxietyCauses.map((e) => e.fishEmoji).toSet();

    for (final emoji in emojis) {
      if (!used.contains(emoji)) return emoji;
    }

    return emojis[DateTime.now().millisecondsSinceEpoch % emojis.length];
  }

  List<Emotion> _customEmotions = [];

  List<Emotion> get allEmotions => [...predefinedEmotions, ..._customEmotions];

  Future<void> fetchCustomEmotions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('emotions')
        .get();

    _customEmotions = snapshot.docs.map((doc) {
      final data = doc.data();
      return Emotion(
        id: data['id'],
        emoji: data['emoji'],
        name: data['name'],
        isSelected: false,
      );
    }).toList();

    notifyListeners();
  }
}