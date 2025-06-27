import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/widgets/internal_action_button.dart';

// 걱정일기 화면
class DiaryEntryScreen extends StatelessWidget {
  const DiaryEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(title: '걱정 일기'),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            ImageBanner(
              imageSource: 'assets/image/mindrium.png',
            ),
            const SizedBox(height: AppSizes.space),
            CardContainer(
              title: '가이드',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      '감정을 기록하며 자신을 되돌아보고 불안을 다스립니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  const Text('하루동안 느낀 감정 선택하고 기록하세요. ', style: TextStyle(color: Colors.black, fontSize: AppSizes.fontSize)),
                  const SizedBox(height: AppSizes.space),
                  const Text('일일 일기를 바탕으로 한 주를 스스로 평가하고 되돌아봅니다.', style: TextStyle(color: Colors.black, fontSize: AppSizes.fontSize)),
                  const SizedBox(height: AppSizes.space),
                  const Text('※ 주간 일기는 주 1회 진행합니다.', style: TextStyle(color: Colors.black, fontSize: AppSizes.fontSize)),
                  const SizedBox(height: AppSizes.space),
                  const SizedBox(height: AppSizes.space),
                  Center(
                    child: InternalActionButton(
                      onPressed: () => Navigator.pushNamed(context, '/diary'),
                      text: '시작하기')
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/diary_record');
              },
              icon: const Icon(Icons.storage, color: Colors.indigo),
              label: const Text(
                '일기 목록 보기',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}