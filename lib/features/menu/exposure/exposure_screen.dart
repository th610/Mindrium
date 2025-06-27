import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/anxiety_cause.dart';
import '../../../data/exposure_provider.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/internal_action_button.dart';
import '../../../widgets/card_container.dart';
import '../../../widgets/image_banner.dart';
import '../../../common/constants.dart';
import 'anxiety_input_screen.dart';
import 'anxiety_ocean_screen.dart';

class ExposureScreen extends StatefulWidget {
  const ExposureScreen({super.key});

  @override
  State<ExposureScreen> createState() => _ExposureScreenState();
}

class _ExposureScreenState extends State<ExposureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSessionIfExists();
    });
  }

  Future<void> _restoreSessionIfExists() async {
    final provider = context.read<ExposureProvider>();

    provider.setLoading(true);
    provider.updateHasUnfinishedSession(false);
    provider.updateAnxietyCauses([]);
    provider.updatePhotoPath(null);
    provider.updateSelectedEmotions([]);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        provider.setLoading(false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      final hasTemporaryData = data?['has_temporary_data'] ?? false;
      final currentScreen = data?['current_screen'] ?? '';

      if (!hasTemporaryData || currentScreen != 'anxiety_ocean') {
        provider.setLoading(false);
        return;
      }

      final causeDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_causes')
          .orderBy('order')
          .get();

      final causes = causeDocs.docs.map((doc) {
        final data = doc.data();
        return AnxietyCause(
          id: data['id'],
          title: data['title'],
          description: data['description'] ?? '',
          anxietyLevel: (data['anxietyLevel'] as num).toDouble(),
          fishEmoji: data['fishEmoji'] ?? '🐟',
          selectedEmotions: List<String>.from(data['selectedEmotions'] ?? []),
        );
      }).toList();

      if (causes.isNotEmpty && mounted) {
        provider.updateAnxietyCauses(causes);
        provider.updateRawAnxietyCauseObjects(causes);
        provider.updatePhotoPath(data?['photoPath']);
        provider.updateSelectedEmotions(List<String>.from(data?['selectedEmotions'] ?? []));
        provider.updateHasUnfinishedSession(true);
      }
    } catch (e) {
      debugPrint('세션 확인 중 오류 발생: $e');
    } finally {
      if (mounted) {
        provider.setLoading(false);
      }
    }
  }

  Future<void> _continueUnfinishedSession() async {
    final provider = context.read<ExposureProvider>();

    if (provider.rawAnxietyCauses.isEmpty) {
      debugPrint('저장된 불안 원인이 없습니다.');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'has_temporary_data': true,
          'current_screen': 'anxiety_ocean',
          'last_updated': FieldValue.serverTimestamp(),
          'photoPath': provider.photoPath,
          'selectedEmotions': provider.selectedEmotions,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('세션 저장 중 오류 발생: $e');
    }
    if (!mounted) return;

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnxietyOceanScreen(
            anxietyCauses: provider.rawAnxietyCauses,
            photoPath: provider.photoPath!,
            selectedEmotions: provider.selectedEmotions,
            entrySource: 'exposure_screen',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExposureProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B5FD6)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(title: '노출 훈련'),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            const ImageBanner(
              imageSource: 'assets/image/mindrium.png',
            ),
            const SizedBox(height: AppSizes.space),
            CardContainer(
              title: '가이드',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    child: Text(
                      '불안한 상황에 직면하고 그 감정을 기록하면서,\n점차 불안을 극복해냅니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  const Text(
                    '공포나 불안의 대상을 사진으로 남겨 봅니다.',
                    style: TextStyle(fontSize: AppSizes.fontSize),
                  ),
                  const SizedBox(height: AppSizes.space),
                  const Text(
                    '두려움에 대한 민감도를 낮추고 회피 없이 상황을 받아들입니다.',
                    style: TextStyle(fontSize: AppSizes.fontSize),
                  ),
                  const SizedBox(height: AppSizes.space),
                  if (provider.hasUnfinishedSession) ...[
                    const Text(
                      '진행 중인 노출치료가 있습니다.',
                      style: TextStyle(
                        fontSize: AppSizes.fontSize,
                        color: Color(0xFF4B5FD6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '이어서 진행하시겠습니까?',
                      style: TextStyle(fontSize: AppSizes.fontSize, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: AppSizes.space),
                  Center(
                    child: InternalActionButton(
                      text: '시작하기',
                      onPressed: () {
                        if (provider.hasUnfinishedSession) {
                          _continueUnfinishedSession();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AnxietyInputScreen()),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}