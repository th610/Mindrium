/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/anxiety_state_provider.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import '../../../data/anxiety_cause.dart';
import '../../../data/emotion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AnxietyResultScreen extends StatefulWidget {
  final List<AnxietyCause> anxietyCauses;
  final Map<String, String> anxietyPhotos;
  final Map<String, List<Emotion>> selectedEmotions;
  final VoidCallback onConfirm;

  const AnxietyResultScreen({
    super.key,
    required this.anxietyCauses,
    required this.anxietyPhotos,
    required this.selectedEmotions,
    required this.onConfirm,
  });

  @override
  State<AnxietyResultScreen> createState() => _AnxietyResultScreenState();
}

class _AnxietyResultScreenState extends State<AnxietyResultScreen> {
  bool _isLoading = false;

  Future<void> _saveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final firestore = FirebaseFirestore.instance;
      final exposureRef =
          firestore
              .collection('users')
              .doc(user.uid)
              .collection('exposures')
              .doc();

      // Firestore에 먼저 문서 생성
      final exposureData = {
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'causes': await Future.wait(
          widget.anxietyCauses.map((cause) async {
            final photoPath = widget.anxietyPhotos[cause.id];
            String? photoUrl;

            if (photoPath != null) {
              final file = File(photoPath);
              if (await file.exists()) {
                try {
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final fileName = '${timestamp}_${cause.id}.jpg';
                  final photoRef = FirebaseStorage.instance
                      .ref()
                      .child('exposures')
                      .child(user.uid)
                      .child(fileName);

                  // 메타데이터 설정
                  final metadata = SettableMetadata(
                    contentType: 'image/jpeg',
                    customMetadata: {
                      'userId': user.uid,
                      'causeId': cause.id,
                      'timestamp': timestamp.toString(),
                    },
                  );

                  // 파일 업로드
                  await photoRef.putFile(file, metadata);
                  photoUrl = await photoRef.getDownloadURL();
                } catch (e) {
                  debugPrint('사진 업로드 실패 (${cause.id}): $e');
                }
              }
            }

            final emotions = context.watch<AnxietyStateProvider>().selectedEmotions[cause.id]
              ?.where((e) => e.isSelected)
              .toList() ?? [];
            final selectedEmotions =
                emotions
                    .where((e) => e.isSelected)
                    .map((e) => {'id': e.id, 'emoji': e.emoji, 'name': e.name})
                    .toList();

            return {
              'id': cause.id,
              'title': cause.title,
              'description': cause.description,
              'anxietyLevel': cause.anxietyLevel,
              'photoUrl': photoUrl,
              'emotions': selectedEmotions,
            };
          }),
        ),
      };

      // Firestore에 데이터 저장
      await exposureRef.set(exposureData);

      if (mounted) {
        widget.onConfirm();
      }
    } catch (e) {
      debugPrint('저장 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(title: '선택 내용 확인'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '선택한 불안 원인과 감정',
                    style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.space),
                  ...widget.anxietyCauses.asMap().entries.map((entry) { final index = entry.key; final cause = entry.value;
                    final photoPath = widget.anxietyPhotos[cause.id];
                    final emotions = context.watch<AnxietyStateProvider>().selectedEmotions[cause.id]
                      ?.where((e) => e.isSelected)
                      .toList() ?? [];
                    if (photoPath == null && emotions.isEmpty) {
                      return const SizedBox();
                    }

                    return Card(
                      margin: const EdgeInsets.all(AppSizes.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photoPath != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.file(
                                  File(photoPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(AppSizes.padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cause.title,
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (emotions.isNotEmpty) ...[
                                  const SizedBox(height: AppSizes.space),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        emotions.asMap().entries.map((entry) {
                                          final emotion = entry.value;
                                          return Container(
                                            padding: const EdgeInsets.all(AppSizes.padding),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF4B5FD6,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(AppSizes.borderRadius),
                                            ),
                                            child: Text(
                                              '${emotion.emoji} ${emotion.name}',
                                              style: const TextStyle(
                                                color: Color(0xFF4B5FD6),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3E6FF),
                      foregroundColor: const Color(0xFF4B5FD6),
                      elevation: 0,
                      padding: const EdgeInsets.all(AppSizes.padding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    child: const Text(
                      '수정하기',
                      style: TextStyle(
                        fontSize: AppSizes.fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.space),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B5FD6),
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 0,
                      padding: const EdgeInsets.all(AppSizes.padding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                            : const Text(
                              '저장하고 계속하기',
                              style: TextStyle(
                                fontSize: AppSizes.fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/