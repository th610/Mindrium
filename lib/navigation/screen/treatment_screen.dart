import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/activitiy_card.dart';
import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/data/daycounter.dart';

import 'package:gad_app_team/features/1st_treatment/week1_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/week2_screen.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_screen.dart';

/// Mindrium 치료 프로그램 메인 화면
class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  /// 진행 상황 카드 위젯
  Widget _buildProgressCard(BuildContext context) {
    final userDayCounter = context.watch<UserDayCounter>();

    if (!userDayCounter.isUserLoaded) return const SizedBox();

    final days = userDayCounter.daysSinceJoin;
    final week = userDayCounter.getWeekNumberFromJoin(DateTime.now());
    final progress = (week / 8).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
      child: CardContainer(
        title: '진행 상황',
        crossAxisAlignment: CrossAxisAlignment.start,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$days일째 ($week주차 진행 중)',
              style: const TextStyle(fontSize: AppSizes.fontSize),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.indigo),
            ),
            Text(
              '${week - 1} / 8 주차 완료',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDayCounter = context.watch<UserDayCounter>();
    final week = userDayCounter.getWeekNumberFromJoin(DateTime.now());

    // 주차별 콘텐츠 정보
    final List<Map<String, String>> weekContents = [
      {'title': '1주차', 'subtitle': '공통 활동 교육'},
      {'title': '2주차', 'subtitle': 'ABC 모델 / SMART 목표'},
      {'title': '3주차', 'subtitle': '건강한 생활 습관'},
      {'title': '4주차', 'subtitle': '걱정에 대한 믿음 탐구'},
      {'title': '5주차', 'subtitle': '걱정에 대한 믿음 수정'},
      {'title': '6주차', 'subtitle': '인지 재구성 (1)'},
      {'title': '7주차', 'subtitle': '인지 재구성 (2) - 문제해결'},
      {'title': '8주차', 'subtitle': '재발 방지 교육'},
    ];

    // 주차별 연결된 화면 (추후 주차별로 추가 가능)
    final List<Widget> weekScreens = const [
      Week1Screen(),
      Week2Screen(),
      Week3Screen(),
      // ...
    ];

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: ListView(
        children: [
          // 제목 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mindrium 치료 프로그램',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '주차 별 프로그램을 진행해 주세요',
                  style: TextStyle(fontSize: AppSizes.fontSize, color: Colors.grey),
                ),
                SizedBox(height: AppSizes.space),
              ],
            ),
          ),

          // 진행 상황 카드
          _buildProgressCard(context),
          const SizedBox(height: AppSizes.space),

          // 주차별 카드 리스트
          ...List.generate(weekContents.length, (index) {
            final isEnabled = index < week;
            return Column(
              children: [
                ActivityCard(
                  icon: Icons.lightbulb_outline,
                  title: weekContents[index]['title']!,
                  subtitle: weekContents[index]['subtitle']!,
                  enabled: isEnabled,
                  titleFontWeight: FontWeight.bold,
                  onTap: isEnabled && index < weekScreens.length
                      ? () => Navigator.pushNamed(context, '/week${index + 1}')
                      : null,
                ),
                const SizedBox(height: AppSizes.space),
              ],
            );
          }),
        ],
      ),
    );
  }
}