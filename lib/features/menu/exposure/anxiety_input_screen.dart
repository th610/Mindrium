import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../common/constants.dart';
import '../../../data/anxiety_cause.dart';
import '../../../data/exposure_provider.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/image_banner.dart';
import '../../../widgets/input_text_field.dart';
import '../../../widgets/navigation_button.dart';
import 'anxiety_photo_screen.dart';
import 'anxiety_ranking_screen.dart';

class AnxietyInputScreen extends StatefulWidget {
  const AnxietyInputScreen({super.key});

  @override
  State<AnxietyInputScreen> createState() => _AnxietyInputScreenState();
}

class _AnxietyInputScreenState extends State<AnxietyInputScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTemporaryState());
  }

  Future<void> _checkTemporaryState() async {
    final provider = context.read<ExposureProvider>();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      final shouldRestore = data?['has_temporary_data'] == true &&
          data?['current_screen'] == 'anxiety_ranking';

      if (shouldRestore) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('anxiety_causes')
            .orderBy('order')
            .get();

        final causes = snapshot.docs.map((doc) {
          final data = doc.data();
          return AnxietyCause(
            id: data['id'],
            title: data['title'],
            description: data['description'],
            anxietyLevel: data['anxietyLevel'],
            fishEmoji: data['fishEmoji'],
          );
        }).toList();

        if (causes.isNotEmpty && mounted) {
          provider.updateRawAnxietyCauseObjects(causes);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AnxietyRankingScreen(
                photoPath: '',
                selectedEmotions: [],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('임시 상태 확인 중 오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    double tempLevel = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          title: const Text('불안 원인', style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.all(AppSizes.padding),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputTextField(controller: _titleController, label: '불안한 감정의 원인'),
                const SizedBox(height: AppSizes.space),
                InputTextField(controller: _descriptionController, maxLines: 3, label: '상세 설명'),
                const SizedBox(height: AppSizes.space),
                const Divider(thickness: 1, color: AppColors.black12),
                const SizedBox(height: AppSizes.space),
                const Text('불안 정도', style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(
                      '${tempLevel.toInt()}',
                      style: const TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Slider(
                        value: tempLevel,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: '${tempLevel.toInt()}',
                        activeColor: Colors.indigo,
                        onChanged: (value) {
                          setDialogState(() {
                            tempLevel = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) return;

                final cause = AnxietyCause(
                  id: const Uuid().v4(),
                  title: _titleController.text,
                  description: _descriptionController.text,
                  anxietyLevel: tempLevel,
                  fishEmoji: _getRandomFishEmoji(),
                );

                final provider = context.read<ExposureProvider>();
                final updated = [...provider.rawAnxietyCauses, cause];
                provider.updateRawAnxietyCauseObjects(updated);

                _titleController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPhotoScreen() {
    final causes = context.read<ExposureProvider>().rawAnxietyCauses;
    if (causes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 하나의 불안 원인을 입력해주세요.')),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => const AnxietyPhotoScreen()));
  }

  String _getRandomFishEmoji() {
    const emojis = ['🐙', '🦐', '🦑', '🪼', '🐡', '🐠', '🐟', '🦈', '🐳', '🐬', '🐋'];
    return emojis[Random().nextInt(emojis.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final causes = context.watch<ExposureProvider>().rawAnxietyCauses;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '불안 원인 입력',
        confirmOnBack: true,
        confirmOnHome: true,
        onBack: () => Navigator.of(context).popUntil((route) => route.settings.name == '/exposure'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(onBack: null, onNext: _proceedToPhotoScreen),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const ImageBanner(imageSource: 'assets/image/anxiety_character.png'),
            const Padding(
              padding: EdgeInsets.all(AppSizes.padding),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '무엇이 당신을 '),
                    TextSpan(
                      text: '불안',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black,
                        decorationThickness: 1,
                      ),
                    ),
                    TextSpan(text: '하게 만드나요?'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Material(
                color: AppColors.indigo50,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                child: InkWell(
                  onTap: _showAddDialog,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: AppColors.indigo),
                        SizedBox(width: AppSizes.space),
                        Text(
                          '탭하여 불안 원인 입력하기',
                          style: TextStyle(
                            color: Colors.indigo,
                            fontSize: AppSizes.fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (causes.isNotEmpty)
              ...causes.map((cause) {
                final index = causes.indexOf(cause);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(color: AppColors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(cause.title, style: const TextStyle(fontSize: 20))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.indigo),
                            onPressed: () {
                              final updated = [...causes]..removeAt(index);
                              context.read<ExposureProvider>().updateRawAnxietyCauseObjects(updated);
                            },
                          ),
                        ],
                      ),
                      if (cause.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(cause.description, style: const TextStyle(color: Colors.grey)),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          border: Border.all(color: AppColors.black12),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Text('불안 정도: ${cause.anxietyLevel.toInt()}'),
                      ),
                    ],
                  ),
                );
              }),
            if (causes.isEmpty)
              const Center(
                child: Text('아직 입력된 내용이 없습니다', style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}