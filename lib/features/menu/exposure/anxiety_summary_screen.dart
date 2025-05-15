/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/anxiety_state_provider.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import '../../../data/anxiety_cause.dart';

class AnxietySummaryScreen extends StatelessWidget {
  final List<AnxietyCause> anxietyCauses;
  final String photoPath;

  const AnxietySummaryScreen({
    super.key,
    required this.anxietyCauses,
    required this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(title: '불안 노출 요약'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.file(
                                File(photoPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSizes.padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '불안 원인',
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.space),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: anxietyCauses.length,
                                  separatorBuilder:
                                      (context, index) =>
                                          const SizedBox(height: AppSizes.space),
                                  itemBuilder: (context, index) {
                                    final cause = anxietyCauses[index];
                                    return Container(
                                      padding: const EdgeInsets.all(AppSizes.padding),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cause.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: AppSizes.fontSize,
                                            ),
                                          ),
                                          if (cause.description.isNotEmpty) ...[
                                            const SizedBox(height: AppSizes.space),
                                            Text(
                                              cause.description,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: AppSizes.fontSize,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: AppSizes.space),
                                          Container(
                                            padding: const EdgeInsets.all(AppSizes.padding),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3E6FF),
                                              borderRadius:
                                                  BorderRadius.circular(AppSizes.borderRadius),
                                            ),
                                            child: Text(
                                              '불안 정도: ${cause.anxietyLevel.toInt()}',
                                              style: const TextStyle(
                                                color: Color(0xFF4B5FD6),
                                                fontSize: AppSizes.fontSize,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3E6FF),
                        foregroundColor: const Color(0xFF4B5FD6),
                        elevation: 0,
                        padding: const EdgeInsets.all(AppSizes.padding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                      ),
                      child: const Text(
                        '이전으로',
                        style: TextStyle(
                          fontSize: AppSizes.fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 데이터 저장 및 홈 화면으로 이동
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B5FD6),
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.all(AppSizes.padding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: AppSizes.fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
*/