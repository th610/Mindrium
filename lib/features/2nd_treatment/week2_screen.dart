import 'package:flutter/material.dart';


import '../../../common/constants.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/image_banner.dart';
import '../../../widgets/navigation_button.dart';

class Week2Screen extends StatefulWidget {
  const Week2Screen({super.key});

  @override
  State<Week2Screen> createState() => _Week2ScreenState();
}

class _Week2ScreenState extends State<Week2Screen> {
  
  @override
  Widget build(BuildContext context) {
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
        child: NavigationButtons(
          onBack: null, 
          //onNext: 
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const ImageBanner(imageSource: ''),
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
                  //onTap: _showAddDialog,
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
            
          ],
        ),
      ),
    );
  }
}