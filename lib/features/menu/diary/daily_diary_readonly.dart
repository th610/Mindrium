import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/emotion_selector.dart';

class DailyDiaryReadOnly extends StatelessWidget {
  final DiaryEntryModel entry;

  const DailyDiaryReadOnly({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: entry.note);
    final ScrollController textScrollController = ScrollController();

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '${int.tryParse(entry.id)}일차 일기',
        confirmOnBack: false,
        confirmOnHome: false,
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 배너 (읽기 전용)
              ImageBanner(
                imageSource: entry.photo?.path ?? 'assets/image/daily_diary.png',
                fit: BoxFit.cover,
              ),
              const SizedBox(height: AppSizes.space),

              // 감정 읽기
              EmotionSelector(
                mode: EmotionSelectorMode.popup,
                selectedEmotions: entry.emotion,
                readOnly: true,
                onChanged: (_) {},
              ),
              const SizedBox(height: AppSizes.space),

              // 텍스트 읽기 전용
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 360),
                padding: const EdgeInsets.all(AppSizes.padding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  color: AppColors.white,
                ),
                child: Scrollbar(
                  controller: textScrollController, // ✅ 별도 컨트롤러 연결
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: SingleChildScrollView(
                    controller: textScrollController, // ✅ 같은 컨트롤러로 연결
                    child: TextField(
                      controller: controller,
                      readOnly: true,
                      maxLines: null,
                      expands: false,
                      decoration: const InputDecoration.collapsed(
                        hintText: '작성된 메모가 없습니다.',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}