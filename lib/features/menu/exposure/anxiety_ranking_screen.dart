import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/card_container.dart';
import 'package:provider/provider.dart';
import '../../../data/exposure_provider.dart';
import '../../../data/emotion.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

class AnxietyRankingScreen extends StatelessWidget {
  final String photoPath;
  final List<String> selectedEmotions;

  const AnxietyRankingScreen({
    super.key,
    required this.photoPath,
    required this.selectedEmotions,
  });

  void _reorder(BuildContext context, int oldIndex, int newIndex) {
    final provider = context.read<ExposureProvider>();
    provider.reorderAnxietyCauses(oldIndex, newIndex);
  }

  void _saveAndProceed(BuildContext context) {
    final provider = context.read<ExposureProvider>();
    provider.updatePhotoPath(photoPath);
    provider.updateSelectedEmotions(selectedEmotions);

    Navigator.pop(context);
  }
  
  void _showAddAnxietyDialog(BuildContext context, List<Emotion> allEmotions, List<String> initiallySelected) {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  double anxietyLevel = 3;
  final Set<String> selectedFeelings = initiallySelected.toSet();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final exposureProvider = context.read<ExposureProvider>();

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 핸들
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 제목 및 닫기 버튼
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('새로운 불안 추가하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // 본문
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 불안 원인
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '불안 원인',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 설명
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '설명 (선택사항)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 감정 선택
                    const Text('관련 감정 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Wrap(
                      spacing: 8,
                      runSpacing: -4,
                      children: allEmotions.map((emotion) {
                        final label = '${emotion.emoji} ${emotion.name}';
                        final isSelected = selectedFeelings.contains(label);
                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              selectedFeelings.add(label);
                            } else {
                              selectedFeelings.remove(label);
                            }
                            (context as Element).markNeedsBuild(); // 강제 리빌드
                          },
                          selectedColor: AppColors.indigo100,
                          backgroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            side: BorderSide(color: isSelected ? AppColors.indigo100 : AppColors.black12),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.indigo : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // 불안 정도 슬라이더
                    const Text('불안 정도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    StatefulBuilder(
                      builder: (context, setDialogState) {
                        return Slider(
                          value: anxietyLevel,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: anxietyLevel.round().toString(),
                          onChanged: (value) {
                            setDialogState(() {
                              anxietyLevel = value;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 버튼
                    NavigationButtons(
                      leftLabel: '취소',
                      rightLabel: '추가',
                      onBack: () => Navigator.pop(context),
                      onNext: () async {
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        if (title.isEmpty) return;

                        await exposureProvider.addAnxietyCause(
                          title: title,
                          description: description,
                          anxietyLevel: anxietyLevel,
                          selectedEmotions: selectedFeelings.toList(),
                        );

                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExposureProvider>();
    final causes = provider.rawAnxietyCauses;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '불안을 순서대로 정리',
        confirmOnBack: true,
        confirmOnHome: true,
        onBack: () => Navigator.pop(context),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: PrimaryActionButton(
          text: '완료',
          onPressed: () => _saveAndProceed(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            Image.asset('assets/image/ranking_illustration.png'),
            const SizedBox(height: 32),
            const Center(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '가장 '),
                  TextSpan(
                    text: '불안',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black,
                      decorationThickness: 1,
                    ),
                  ),
                  TextSpan(text: '한 것부터 정리해볼까요?'),
                ]),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
              Material(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    final provider = context.read<ExposureProvider>();
                    _showAddAnxietyDialog(
                      context,
                      provider.allEmotions,       
                      selectedEmotions,            
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle, color: Colors.indigo),
                        SizedBox(width: 12),
                        Text(
                          '불안 추가하기',
                          style: TextStyle(
                            color: Colors.indigo,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            _buildAnxietyLevelGuide(),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: causes.length,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) => _reorder(context, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final cause = causes[index];
                final color = _anxietyColor(cause.anxietyLevel);

                return ReorderableDragStartListener(
                  key: ValueKey(cause.id),
                  index: index,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    padding: const EdgeInsets.all(AppSizes.padding),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      border: Border.all(color: AppColors.black12),
                    ),
                    child: Row(
                      children: [
                        Text('${index + 1}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSize,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(width: AppSizes.space),
                        Container(width: 1, height: 48, color: AppColors.black12),
                        const SizedBox(width: AppSizes.space),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cause.title,
                                  style: const TextStyle(fontSize: AppSizes.fontSize)),
                              if (cause.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    cause.description,
                                    style: const TextStyle(color: AppColors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha((0.5*255).toInt()),
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Row(
                            children: [
                              Text(cause.fishEmoji ?? '🐠', style: const TextStyle(fontSize: AppSizes.fontSize)),
                              const SizedBox(width: AppSizes.space),
                              Text('${cause.anxietyLevel.toInt()}단계', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.space),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnxietyLevelGuide() {
    const levels = [1, 2, 3, 4, 5];
    final colors = [
      Colors.blue[100]!,
      Colors.green[200]!,
      Colors.yellow[600]!,
      Colors.orange[400]!,
      Colors.red[400]!,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(0,16,0,16),
      child: CardContainer(
        title: '불안 정도 상태',
        boxShadow: [],
        child: Row(
          children: [
            ...List.generate(levels.length, (index) {
              return Expanded(
                child: Container(
                margin: const EdgeInsets.fromLTRB(8,0,8,0),
                padding: const EdgeInsets.fromLTRB(0,4,0,4),
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${levels[index]}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, 
                ),
              ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _anxietyColor(double level) {
    final colors = [
      Colors.blue[100]!,
      Colors.green[200]!,
      Colors.yellow[600]!,
      Colors.orange[400]!,
      Colors.red[400]!,
    ];
    return colors[(level - 1).clamp(0, 4).toInt()];
  }
}