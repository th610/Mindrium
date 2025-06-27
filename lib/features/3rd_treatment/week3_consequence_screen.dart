import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_practice_screen.dart';

class Week3ConsequenceScreen extends StatelessWidget {
  const Week3ConsequenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '3주차 - Self Talk'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/consequence.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              color: Colors.black.withValues(alpha: 0.45),
              child: const Text(
                '가슴이 철렁하면서 겁이 확 나버렸고, 결국 자전거에서 내려버렸어요.\n\'혹시 또 다치면 어쩌지? 사람들이 보면 창피할 텐데…\' 이런 생각들만 머릿속을 맴돌았어요.\n그래서 그날은 자전거를 타지 않고 그냥 산책만 하고 돌아왔어요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.left,
                softWrap: true,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NavigationButtons(
                onBack: () => Navigator.pop(context),
                onNext: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const Week3PracticeScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
