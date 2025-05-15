import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../common/constants.dart';
import '../../../data/anxiety_cause.dart';
import '../../../data/emotion.dart';
import '../../../data/exposure_provider.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/image_banner.dart';
import '../../../widgets/navigation_button.dart';
import 'emotion_selection_screen.dart';

class AnxietyPhotoScreen extends StatefulWidget {
  const AnxietyPhotoScreen({super.key});

  @override
  State<AnxietyPhotoScreen> createState() => _AnxietyPhotoScreenState();
}

class _AnxietyPhotoScreenState extends State<AnxietyPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  AnxietyCause? _selectedAnxietyCause;

  @override
  void initState() {
    super.initState();
    final causes = context.read<ExposureProvider>().rawAnxietyCauses;
    if (causes.isNotEmpty) {
      _selectedAnxietyCause = causes.first;
    }
  }

  Future<bool> _checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> _openCamera() async {
    if (_selectedAnxietyCause == null) return;

    try {
      final hasPermission = await _checkAndRequestCameraPermission();
      if (!hasPermission) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('카메라 권한 필요'),
            content: const Text('사진을 촬영하기 위해서는 카메라 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          ),
        );
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        context.read<ExposureProvider>().updatePhotoForCause(_selectedAnxietyCause!.id, photo.path);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _handleNextStep() async {
    if (_selectedAnxietyCause == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('먼저 사진을 촬영해주세요.')));
      return;
    }

    final selectedEmotions = await Navigator.push<List<Emotion>>(
      context,
      MaterialPageRoute(
        builder: (_) => const EmotionSelectionScreen(),
      ),
    );

    if (selectedEmotions == null || !mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final provider = context.read<ExposureProvider>();
      final exposureRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('exposures').doc();

      await exposureRef.set({
        'anxietyCauses': provider.rawAnxietyCauses.map((cause) => {
          'id': cause.id,
          'title': cause.title,
          'description': cause.description,
          'anxietyLevel': cause.anxietyLevel,
          'photoPath': provider.getPhotoForCause(cause.id),
        }).toList(),
        'emotions': selectedEmotions.map((e) => {
          'id': e.id,
          'name': e.name,
          'emoji': e.emoji,
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      provider.updateSelectedEmotions(selectedEmotions.map((e) => '${e.emoji} ${e.name}').toList());
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExposureProvider>();
    final causes = provider.rawAnxietyCauses;
    final selectedId = _selectedAnxietyCause?.id;
    final selectedPhotoPath = selectedId != null ? provider.getPhotoForCause(selectedId) : null;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '불안 원인 사진',
        confirmOnBack: true,
        confirmOnHome: true,
        onBack: () => Navigator.of(context).popUntil((route) => route.settings.name == '/exposure'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(
          onBack: () => Navigator.pop(context),
          onNext: _handleNextStep,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            const ImageBanner(imageSource: 'assets/image/photo.png'),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      if (causes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            color: AppColors.white,
                            border: Border.all(color: AppColors.black12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AnxietyCause>(
                              value: _selectedAnxietyCause,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                              items: causes.map((cause) => DropdownMenuItem(
                                value: cause,
                                child: Text(
                                  cause.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedAnxietyCause = newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      const Text(' 을(를) 사진으로 찍어볼까요?', style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('또는 관련된 사진을 찍어보세요', style: TextStyle(color: Colors.grey))
                  ),
                  const SizedBox(height: AppSizes.space),
                  Material(
                    color: AppColors.indigo50,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    child: InkWell(
                      onTap: _openCamera,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.padding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_rounded, color: AppColors.indigo),
                            SizedBox(width: AppSizes.space),
                            Text(
                              '카메라로 촬영하기',
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
                  const SizedBox(height: AppSizes.space),
                  if (selectedPhotoPath != null && File(selectedPhotoPath).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      child: Image.file(
                        File(selectedPhotoPath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        '촬영된 사진이 없습니다.',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
