import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/widgets/internal_action_button.dart';

class Week3Screen extends StatefulWidget {
  const Week3Screen({super.key});

  @override
  State<Week3Screen> createState() => _Week3ScreenState();
}

class _Week3ScreenState extends State<Week3Screen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(title: '건강한 습관 만들기'),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            ImageBanner(
              //imageSource: 'assets/image/mindrium.png',
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
                      '맞춤형 생활 습관을 계획하고 실천합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  const Text('원하는 생활 습관을 선택합니다.', style: TextStyle(color: Colors.black, fontSize: AppSizes.fontSize)),
                  const SizedBox(height: AppSizes.space),
                  const Text('단계에 따라 구체적인 계획을 세우고 캘린더에 추가하여 지속적으로 확인하며 꾸준히 실천합니다.', style: TextStyle(color: Colors.black, fontSize: AppSizes.fontSize)),
                  const SizedBox(height: AppSizes.space),
                  const SizedBox(height: AppSizes.space),
                  Center(
                    child: InternalActionButton(
                      onPressed: () => Navigator.pushNamed(context, '/habit1'),
                      text: '시작하기'
                    )
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