import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/weekly_entry_model.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

// 주간 일기 읽기 모드
class WeeklyDiaryReadOnly extends StatefulWidget {
  final WeeklyEntryModel entry;

  const WeeklyDiaryReadOnly({super.key, required this.entry});

  @override
  State<WeeklyDiaryReadOnly> createState() => _WeeklyDiaryReadOnlyState();
}

class _WeeklyDiaryReadOnlyState extends State<WeeklyDiaryReadOnly> {
  late final TextEditingController _weeklyController;
  late final TextEditingController _thoughtController;
  late final ScrollController _weeklyScrollController;
  late final ScrollController _thoughtScrollController;

  @override
  void initState() {
    super.initState();
    _weeklyController = TextEditingController(text: widget.entry.weeklyNote);
    _thoughtController = TextEditingController(text: widget.entry.thoughtNote);
    _weeklyScrollController = ScrollController();
    _thoughtScrollController = ScrollController();
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _thoughtController.dispose();
    _weeklyScrollController.dispose();
    _thoughtScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: '이번주 주간 일기',
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
              const Text(
                '주간 일기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.fontSize, color: AppColors.black),
              ),
              const SizedBox(height: AppSizes.space),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 160),
                padding: const EdgeInsets.all(AppSizes.padding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  color: AppColors.white,
                ),
                child: Scrollbar(
                  controller: _weeklyScrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: SingleChildScrollView(
                    controller: _weeklyScrollController,
                    child: TextField(
                      controller: _weeklyController,
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
              const SizedBox(height: AppSizes.space),

              const Text(
                '감정과 불안 점수',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.fontSize, color: AppColors.black),
              ),
              const SizedBox(height: AppSizes.space),
              Row(
                children: [
                  const SizedBox(width: AppSizes.space),
                  Text(
                    widget.entry.anxietyScore.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: AppSizes.fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space),
                  Expanded(
                    child: Slider(
                      value: widget.entry.anxietyScore,
                      min: 0.0,
                      max: 5.0,
                      divisions: 5,
                      label: widget.entry.anxietyScore.toInt().toString(),
                      inactiveColor: Colors.grey.shade400,
                      onChanged: (_) {}, // 읽기 전용
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space),

              const Text(
                '전반적인 회고',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.fontSize, color: AppColors.black),
              ),
              const SizedBox(height: AppSizes.space),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 160),
                padding: const EdgeInsets.all(AppSizes.padding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  color: AppColors.white,
                ),
                child: Scrollbar(
                  controller: _thoughtScrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: SingleChildScrollView(
                    controller: _thoughtScrollController,
                    child: TextField(
                      controller: _thoughtController,
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