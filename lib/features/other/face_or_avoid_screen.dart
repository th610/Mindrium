import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/data/user_pretest.dart';

class FaceOrAvoidScreen extends StatefulWidget {
  final List<String> worries;
  final String? otherWorry;
  final String? sleepHours;
  final String? sleepQuality;
  final VoidCallback? onComplete;
  const FaceOrAvoidScreen({
    super.key,
    required this.worries,
    this.otherWorry,
    this.sleepHours,
    this.sleepQuality,
    this.onComplete,
  });

  @override
  State<FaceOrAvoidScreen> createState() => _FaceOrAvoidScreenState();
}

class _FaceOrAvoidScreenState extends State<FaceOrAvoidScreen> {
  int step = 0; // 0: 직면, 1: 회피, 2: 메시지

  final List<_GridItem> faceSymptoms = [
    _GridItem(icon: Icons.sentiment_satisfied, label: '긴장'),
    _GridItem(icon: Icons.nightlight, label: '불면'),
    _GridItem(icon: Icons.favorite, label: '두근거림'),
    _GridItem(icon: Icons.sick, label: '메스꺼움'),
    _GridItem(icon: Icons.mood_bad, label: '우울'),
    _GridItem(icon: Icons.visibility, label: '집중곤란'),
    _GridItem(icon: Icons.spa, label: '식은땀'),
    _GridItem(icon: Icons.waves, label: '호흡곤란'),
    _GridItem(icon: Icons.headset, label: '이명'),
    _GridItem(icon: Icons.healing, label: '근육긴장'),
    _GridItem(icon: Icons.bolt, label: '피로'),
    _GridItem(icon: Icons.cake, label: '식욕저하'),
    _GridItem(icon: Icons.coffee, label: '불안'),
    _GridItem(icon: Icons.emoji_emotions, label: '초조'),
    _GridItem(icon: Icons.thermostat, label: '열감'),
    _GridItem(icon: Icons.bug_report, label: '두통'),
    _GridItem(icon: Icons.bubble_chart, label: '현기증'),
    _GridItem(icon: Icons.bed, label: '수면장애'),
    _GridItem(icon: Icons.sports_kabaddi, label: '불안발작'),
    _GridItem(icon: Icons.speaker, label: '소리예민'),
    _GridItem(icon: Icons.lightbulb, label: '생각과다'),
    _GridItem(icon: Icons.sports_handball, label: '손떨림'),
    _GridItem(icon: Icons.sports_mma, label: '가슴통증'),
    _GridItem(icon: Icons.sports_tennis, label: '근육통'),
    _GridItem(icon: Icons.sports_volleyball, label: '불면증'),
    _GridItem(icon: Icons.sports_basketball, label: '불쾌감'),
    _GridItem(icon: Icons.sports_baseball, label: '불신'),
    _GridItem(icon: Icons.sports_cricket, label: '불확실감'),
    _GridItem(icon: Icons.sports_football, label: '불만'),
    _GridItem(icon: Icons.sports_golf, label: '불평'),
    _GridItem(icon: Icons.add, label: '추가', isAdd: true),
  ];
  final List<_GridItem> avoidSymptoms = [
    _GridItem(icon: Icons.sentiment_dissatisfied, label: '회피'),
    _GridItem(icon: Icons.bed, label: '잠'),
    _GridItem(icon: Icons.block, label: '무기력'),
    _GridItem(icon: Icons.sick, label: '메스꺼움'),
    _GridItem(icon: Icons.mood_bad, label: '우울'),
    _GridItem(icon: Icons.visibility, label: '집중곤란'),
    _GridItem(icon: Icons.spa, label: '식은땀'),
    _GridItem(icon: Icons.waves, label: '호흡곤란'),
    _GridItem(icon: Icons.headset, label: '이명'),
    _GridItem(icon: Icons.healing, label: '근육긴장'),
    _GridItem(icon: Icons.bolt, label: '피로'),
    _GridItem(icon: Icons.cake, label: '식욕저하'),
    _GridItem(icon: Icons.coffee, label: '불안'),
    _GridItem(icon: Icons.emoji_emotions, label: '초조'),
    _GridItem(icon: Icons.thermostat, label: '열감'),
    _GridItem(icon: Icons.bug_report, label: '두통'),
    _GridItem(icon: Icons.bubble_chart, label: '현기증'),
    _GridItem(icon: Icons.bed, label: '수면장애'),
    _GridItem(icon: Icons.sports_kabaddi, label: '불안발작'),
    _GridItem(icon: Icons.speaker, label: '소리예민'),
    _GridItem(icon: Icons.lightbulb, label: '생각과다'),
    _GridItem(icon: Icons.sports_handball, label: '손떨림'),
    _GridItem(icon: Icons.sports_mma, label: '가슴통증'),
    _GridItem(icon: Icons.sports_tennis, label: '근육통'),
    _GridItem(icon: Icons.sports_volleyball, label: '불면증'),
    _GridItem(icon: Icons.sports_basketball, label: '불쾌감'),
    _GridItem(icon: Icons.sports_baseball, label: '불신'),
    _GridItem(icon: Icons.sports_cricket, label: '불확실감'),
    _GridItem(icon: Icons.sports_football, label: '불만'),
    _GridItem(icon: Icons.sports_golf, label: '불평'),
    _GridItem(icon: Icons.add, label: '추가', isAdd: true),
  ];

  final Set<int> selectedFace = {};
  final Set<int> selectedAvoid = {};

  final TextEditingController _addController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              if (step == 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.indigo50, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        '불안을 직면할 때',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.indigo,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '어떤 증상이나 생각 또는 행동을 보이나요?',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildGrid(
                    faceSymptoms,
                    selectedFace,
                    (i) => setState(
                      () =>
                          selectedFace.contains(i)
                              ? selectedFace.remove(i)
                              : selectedFace.add(i),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: NavigationButtons(
                    onNext: () {
                      setState(() => step = 1);
                    },
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ] else if (step == 1) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.indigo50, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        '불안을 회피할 때',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.indigo,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '어떤 증상이나 생각 또는 행동을 보이나요?',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildGrid(
                    avoidSymptoms,
                    selectedAvoid,
                    (i) => setState(
                      () =>
                          selectedAvoid.contains(i)
                              ? selectedAvoid.remove(i)
                              : selectedAvoid.add(i),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: NavigationButtons(
                    onNext: () {
                      setState(() => step = 2);
                    },
                    onBack: () => setState(() => step = 0),
                  ),
                ),
              ] else if (step == 2) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '그 상황에서 언제 처음으로 불편함을 느꼈나요?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '불안할 때의 상황에 대해 생각해 보아요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 6, 6, 6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final faceSelected =
                            selectedFace
                                .map((i) => faceSymptoms[i].label)
                                .toList();
                        final avoidSelected =
                            selectedAvoid
                                .map((i) => avoidSymptoms[i].label)
                                .toList();
                        await UserDatabase.saveSurveyResult(
                          worries: widget.worries,
                          otherWorry: widget.otherWorry,
                          sleepHours: widget.sleepHours,
                          sleepQuality: widget.sleepQuality,
                          faceSelected: faceSelected,
                          avoidSelected: avoidSelected,
                        );
                        if (!mounted) return;
                        widget.onComplete?.call();
                        Navigator.pushNamed(context, 'noti_select');
                      },
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<_GridItem> items,
    Set<int> selected,
    void Function(int) onTap,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final isSelected = selected.contains(i);
        if (item.isAdd) {
          return GestureDetector(
            onTap: () => _showAddDialog(items),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.indigo, width: 2),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 28, color: AppColors.indigo),
                  SizedBox(height: 4),
                  Text(
                    '추가',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.indigo50 : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.indigo : AppColors.grey,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isSelected ? AppColors.indigo : AppColors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.indigo : AppColors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(List<_GridItem> items) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '또 다른 증상이 있다면 추가해주세요',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.indigo,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addController,
                decoration: const InputDecoration(
                  hintText: '증상/생각/행동 입력',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final value = _addController.text.trim();
                    if (value.isNotEmpty) {
                      setState(() {
                        items.insert(
                          items.length - 1,
                          _GridItem(icon: Icons.circle, label: value),
                        );
                      });
                    }
                    Navigator.pop(context);
                    _addController.clear();
                  },
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridItem {
  final IconData icon;
  final String label;
  final bool isAdd;
  const _GridItem({
    required this.icon,
    required this.label,
    this.isAdd = false,
  });
}
