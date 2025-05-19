import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/emotion_selector.dart';
import 'package:gad_app_team/utils/permission_utils.dart';

import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/data/diary_entry_provider.dart';

class DailyDiaryScreen extends StatefulWidget {
  final DiaryEntryModel? entry; // null이면 새 작성, 있으면 수정 모드

  const DailyDiaryScreen({
    super.key,
    this.entry,
  });

  @override
  State<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends State<DailyDiaryScreen> {
  String? _photoPath; // 선택된 사진 경로
  List<String> _selectedEmotions = []; // 선택된 감정 목록
  final TextEditingController _noteController = TextEditingController(); // 텍스트 입력

  @override
  void initState() {
    super.initState();

    // 수정 모드: entry가 있으면 상태 초기화
    final entry = widget.entry;
    if (entry != null) {
      _noteController.text = entry.note;
      _selectedEmotions = entry.emotion;
      _photoPath = entry.photo?.path;
    }
  }

  // 저장 버튼 눌렀을 때 처리
  Future<void> _submitEntry() async {
    final note = _noteController.text.trim();
    final hasEmotion = _selectedEmotions.isNotEmpty;

    if (note.isEmpty || !hasEmotion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    final notifier = context.read<DiaryEntryNotifier>();
    await notifier.save(
      emotions: _selectedEmotions,
      note: note,
      localPhotoFile: _photoPath != null ? File(_photoPath!) : null,
    );

    // 저장 이후 Firestore에서 다시 불러와서 확인
    await notifier.loadTodayEntry();
    if (!mounted) return;

    final savedEntry = notifier.entry;
    if (savedEntry != null && savedEntry.note == note) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('저장 완료'),
          content: const Text('걱정 일기가 저장되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).popUntil((route) => route.settings.name == '/contents'),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 저장을 다시 시도해주세요.')),
      );
    }
  }

  // 감정 선택 결과 반영
  void _updateEmotions(List<String> emotions) {
    setState(() => _selectedEmotions = emotions);
  }

  Future<void> _showImageSourceSelector() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('사진을 어디서 불러올까요?', style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.space),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.indigo),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.indigo),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _handlePickImage(source);
    }
  }

  Future<void> _handlePickImage(ImageSource source) async {
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionUtils.checkAndRequestCamera();
    } else if (source == ImageSource.gallery) {
      hasPermission = await PermissionUtils.checkAndRequestGallery();
    }

    if (!hasPermission) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('권한 필요'),
          content: const Text('권한이 없으면 사진을 불러올 수 없습니다.\n설정에서 권한을 허용해주세요.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            }, child: const Text('설정으로 이동')),
          ],
        ),
      );
      return;
    }

    final picked = await PermissionUtils.pickImage(source);
    if (picked != null && mounted) {
      setState(() {
        _photoPath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController textFieldScrollController = ScrollController();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '걱정 일기',
        confirmOnBack: true,
        confirmOnHome: true,
        onBack: () => Navigator.of(context).popUntil((route) => route.settings.name == '/contents'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: PrimaryActionButton(
          onPressed: _submitEntry,
          text: '저장하기',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Card(
            color: AppColors.grey100,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 배너 : 사진 출력 + 삭제 기능
                GestureDetector(
                  onTap: () async {
                    if (_photoPath != null) {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AlertDialog(
                          title: const Text('사진 삭제'),
                          content: const Text('현재 첨부된 사진을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                          ],
                        ),
                      );
                      if (shouldDelete == true) {
                        setState(() => _photoPath = null);
                      }
                    } else {
                      await _showImageSourceSelector();
                    }
                  },
                  child: _photoPath == null
                      ? ImageBanner(
                          //TODO:imageSource: 'assets/image/daily_diary.png',
                          height: MediaQuery.of(context).size.width * 9 / 16,
                          fit: BoxFit.cover,
                        )
                      : ImageBanner(
                          //TODO:imageSource: _photoPath!,
                          height: MediaQuery.of(context).size.width * 9 / 16,
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '이미지를 탭하여 불안의 대상과 관련된 사진도 첨부해 보세요.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                const SizedBox(height: AppSizes.space),
                // 감정 선택기
                EmotionSelector(
                  mode: EmotionSelectorMode.popup,
                  selectedEmotions: _selectedEmotions,
                  onChanged: (updatedList) {
                    _updateEmotions(updatedList);
                  },
                ),
                const SizedBox(height: AppSizes.space),
                // 텍스트 입력
                SizedBox(
                  width: double.infinity,
                  height: 360,
                  child: Scrollbar(
                    controller: textFieldScrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(6),
                    interactive: true,
                    child: SingleChildScrollView(
                      controller: textFieldScrollController,
                      child: TextField(
                        controller: _noteController,
                        readOnly: false,
                        maxLines: null,
                        expands: false,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: '오늘 하루 동안 느낀 걱정과 불안에 대해 작성해 보세요.',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.black12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}