/*
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/anxiety_state_provider.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import '../../../data/anxiety_cause.dart';
import '../../../widgets/anxiety_fish.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class AnxietyDeleteScreen extends StatefulWidget {
  final List<AnxietyCause> anxietyCauses;
  final String photoPath;
  final List<String> selectedEmotions;

  const AnxietyDeleteScreen({
    super.key,
    required this.anxietyCauses,
    required this.photoPath,
    required this.selectedEmotions,
  });

  @override
  State<AnxietyDeleteScreen> createState() => _AnxietyDeleteScreenState();
}

class _AnxietyDeleteScreenState extends State<AnxietyDeleteScreen> {
  late List<AnxietyCause> _anxietyCauses;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _anxietyLevel = 3;

  @override
  void initState() {
    super.initState();
    _anxietyCauses = List.from(context.watch<AnxietyStateProvider>().anxietyCauses);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddAnxietyDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _anxietyLevel = 3;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('새로운 불안 추가하기'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '불안 원인',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '설명 (선택사항)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '불안 정도',
                        style: TextStyle(
                          fontSize: AppSizes.fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return Slider(
                            value: _anxietyLevel,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _anxietyLevel.round().toString(),
                            onChanged: (value) {
                              setDialogState(() {
                                _anxietyLevel = value;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) {
                    return;
                  }

                  final newCause = AnxietyCause(
                    id: const Uuid().v4(),
                    title: _titleController.text,
                    description: _descriptionController.text,
                    anxietyLevel: _anxietyLevel,
                    fishEmoji: _getRandomFishEmoji(),
                  );

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('anxiety_causes')
                          .add({
                            'id': newCause.id,
                            'title': newCause.title,
                            'description': newCause.description,
                            'anxietyLevel': newCause.anxietyLevel,
                            'fishEmoji': newCause.fishEmoji,
                          });
                    }
                  } catch (e) {
                    print('Firebase 에러 발생: $e');
                  }

                  setState(() {
                    _anxietyCauses.add(newCause);
                  });

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4B5FD6),
                ),
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(AnxietyCause cause) {
    _titleController.text = cause.title;
    _descriptionController.text = cause.description;
    _anxietyLevel = cause.anxietyLevel;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('불안 수정하기'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '불안 원인',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '설명 (선택사항)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '불안 정도',
                        style: TextStyle(
                          fontSize: AppSizes.fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return Slider(
                            value: _anxietyLevel,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _anxietyLevel.round().toString(),
                            onChanged: (value) {
                              setDialogState(() {
                                _anxietyLevel = value;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(cause);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('극복'),
              ),
              FilledButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) {
                    return;
                  }

                  final updatedCause = AnxietyCause(
                    id: cause.id,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    anxietyLevel: _anxietyLevel,
                    fishEmoji: cause.fishEmoji,
                  );

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final querySnapshot =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('anxiety_causes')
                              .where('id', isEqualTo: cause.id)
                              .get();

                      if (querySnapshot.docs.isNotEmpty) {
                        await querySnapshot.docs.first.reference.update({
                          'title': updatedCause.title,
                          'description': updatedCause.description,
                          'anxietyLevel': updatedCause.anxietyLevel,
                          'fishEmoji': updatedCause.fishEmoji,
                        });
                      }
                    }
                  } catch (e) {
                    print('Firebase 에러 발생: $e');
                  }

                  setState(() {
                    final index = _anxietyCauses.indexWhere(
                      (c) => c.id == cause.id,
                    );
                    if (index != -1) {
                      _anxietyCauses[index] = updatedCause;
                    }
                  });

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4B5FD6),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
    );
  }

  void _showCompletionScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '잘하셨어요!!',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5FD6),
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  child: Image.asset(
                    'assets/image/completion.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                const Text(
                  '불안은 누구나\n느낄 수 있는 감정입니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSizes.space),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        debugPrint('========== 노출치료 데이터 저장 시작 ==========');
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          debugPrint('현재 로그인된 사용자 ID: ${user.uid}');
                          debugPrint('저장할 불안 원인 개수: ${_anxietyCauses.length}');
                          debugPrint('사진 경로: ${widget.photoPath}');
                          debugPrint('선택된 감정: ${widget.selectedEmotions}');

                          // 노출치료 완료 데이터 저장
                          final docRef = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('exposure_completions')
                              .add({
                                'completedAt': FieldValue.serverTimestamp(),
                                'anxietyCauses':
                                    _anxietyCauses
                                        .map(
                                          (cause) => {
                                            'id': cause.id,
                                            'title': cause.title,
                                            'description': cause.description,
                                            'anxietyLevel': cause.anxietyLevel,
                                            'fishEmoji': cause.fishEmoji,
                                          },
                                        )
                                        .toList(),
                                'photoPath': widget.photoPath,
                                'selectedEmotions': widget.selectedEmotions,
                                'sessionDate': DateTime.now().toIso8601String(),
                              });

                          // 저장된 데이터 확인
                          final savedDoc = await docRef.get();
                          debugPrint('저장 성공!');
                          debugPrint('문서 ID: ${savedDoc.id}');
                          debugPrint('저장된 데이터: ${savedDoc.data()}');
                          debugPrint('========== 노출치료 데이터 저장 완료 ==========');
                        } else {
                          debugPrint('오류: 사용자가 로그인되어 있지 않습니다.');
                        }

                        if (!mounted) return;

                        // 홈 화면으로 이동 (로그인 상태 유지)
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/home', (route) => false);
                      } catch (e, stackTrace) {
                        debugPrint('========== 오류 발생 ==========');
                        debugPrint('데이터 저장 중 오류: $e');
                        debugPrint('스택 트레이스: $stackTrace');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('데이터 저장 중 오류가 발생했습니다.')),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B5FD6),
                      padding: const EdgeInsets.all(AppSizes.padding),
                    ),
                    child: const Text(
                      '이제 괜찮아요',
                      style: TextStyle(fontSize: AppSizes.fontSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAnxietyCause(AnxietyCause cause) async {
    setState(() {
      _anxietyCauses.remove(cause);
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('anxiety_causes')
                .where('id', isEqualTo: cause.id)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.delete();
        }
      }
    } catch (e) {
      print('Firebase 에러 발생: $e');
    }

    if (mounted) {
      _showCongratulationsDialog();

      if (_anxietyCauses.isEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showCompletionScreen();
          }
        });
      }
    }
  }

  void _showDeleteConfirmation(AnxietyCause cause) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('불안 극복하기'),
            content: Text('정말로 "${cause /*.title?*/}" 불안을 극복하셨나요?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('아니요'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAnxietyCause(cause);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4B5FD6),
                ),
                child: const Text('네'),
              ),
            ],
          ),
    );
  }

  void _showCongratulationsDialog() {
    final encouragements = [
      '불안 물고기는 내가 다 먹어버렸어~',
      '한 걸음 더 성장했네요!',
      '불안은 이제 안녕~',
    ];
    final random = Random();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '걱정마요!',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5FD6),
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  child: Image.asset(
                    'assets/image/completion.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                Text(
                  encouragements[random.nextInt(encouragements.length)],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B5FD6),
                      padding: const EdgeInsets.all(AppSizes.padding),
                    ),
                    child: const Text('좋아요!', style: TextStyle(fontSize: AppSizes.fontSize)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRandomFishEmoji() {
    const fishEmojis = [
      '🐙',
      '🦐',
      '🦑',
      '🪼',
      '🐡',
      '🐠',
      '🐟',
      '🦈',
      '🐳',
      '🐬',
      '🐋',
    ];
    return fishEmojis[Random().nextInt(fishEmojis.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '물고기의 바다'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: _anxietyCauses.length,
              itemBuilder: (context, index) {
                final cause = _anxietyCauses[index];
                return Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: GestureDetector(
                    onDoubleTap: () => _showEditDialog(cause),
                    child: AnxietyFish(
                      anxietyCause: cause,
                      index: index,
                      initialX:
                          Random().nextDouble() *
                          MediaQuery.of(context).size.width,
                      initialY:
                          Random().nextDouble() *
                          MediaQuery.of(context).size.height,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _showAddAnxietyDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      padding: const EdgeInsets.all(AppSizes.padding),
                    ),
                    child: const Text(
                      '더 추가하기',
                      style: TextStyle(fontSize: AppSizes.fontSize, color: Color(0xFF4B5FD6)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.space),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B5FD6),
                      padding: const EdgeInsets.all(AppSizes.padding),
                    ),
                    child: const Text('다음으로', style: TextStyle(fontSize: AppSizes.fontSize)),
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