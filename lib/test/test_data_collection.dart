import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmotionLogForm extends StatefulWidget {
  final String userId;

  const EmotionLogForm({super.key, required this.userId});

  @override
  State<EmotionLogForm> createState() => _EmotionLogFormState();
}

class _EmotionLogFormState extends State<EmotionLogForm> {
  final _formKey = GlobalKey<FormState>();

  final _actionController = TextEditingController();
  final _beforeEmotionController = TextEditingController();
  final _afterEmotionController = TextEditingController();

  String? _selectedBeforeEmotion;
  String? _selectedAfterEmotion;
  String? _selectedAction;

  double _beforeSud = 5;
  double _afterSud = 5;
  double _pleasure = 5;
  double _mastery = 5;

  final List<String> emotionOptions = [
    '격분','화남','놀람','두려움','긴장','불안','분노',
    '흥미로움','신남','행복','기쁨','만족스러움','즐거움',
    '편안','차분','평온','평범','슬픔','우울','지루함',
    '기타(직접 입력)'
  ];

  final List<String> actionOptions = [
    '음료 마시기','공부','발표', '청소', '심호흡', '산책', '운동', '명상', '게임', '친구와 연락',
    '운전', '책 읽기', '음악 듣기', '요가', '일기 쓰기', '스트레칭', '요리','쇼핑','티비 보기','잠자기'
    '기타(직접 입력)'
  ];

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

      final log = EmotionBehaviorLog(
        time: formattedTime,
        beforeEmotion: _beforeEmotionController.text,
        beforeSud: _beforeSud,
        action: _actionController.text,
        afterEmotion: _afterEmotionController.text,
        afterSud: _afterSud,
        pleasure: _pleasure,
        mastery: _mastery,
      );

      await FirebaseFirestore.instance
          .collection('test')
          .doc(widget.userId)
          .collection('user_data_collection')
          .add(log.toJson());

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("감사합니다!", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("기록이 성공적으로 저장되었습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("확인", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        ),
      );

      _formKey.currentState!.reset();
      _actionController.clear();
      _beforeEmotionController.clear();
      _afterEmotionController.clear();
      setState(() {
        _selectedBeforeEmotion = null;
        _selectedAfterEmotion = null;
        _selectedAction = null;
        _beforeSud = _afterSud = _pleasure = _mastery = 5;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    return Scaffold(
      appBar: AppBar(title: const Text("감정-행동 기록")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
            elevation: 2,
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "참여 안내문",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  SizedBox(height: 8),
                  Text("안녕하세요!\n본 연구에 관심을 가지고 참여해주셔서 진심으로 감사드립니다.\n본 연구는 일상 속 감정 변화와 행동 간의 관계를 분석하여, 개인에게 도움이 되는 맞춤형 정신건강 관리 시스템을 개발하는 것을 목표로 합니다."),
                  SizedBox(height: 8),
                  Text(
                    "특히, 여러분의 감정 상태와 일상 속 행동 기록을 통해 감정 전이의 흐름을 파악하고, 회복에 도움이 되는 행동 경로를 찾고자 합니다.",
                    style: TextStyle(fontWeight: FontWeight.bold),),
                  SizedBox(height: 8),
                  Text("모든 데이터는 연구 목적 외에는 절대 사용되지 않습니다."),
                ],
              ),
            ),
          ),
            Card(
            elevation: 2,
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "기록 입력 가이드",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  SizedBox(height: 8),
                  Text("하루 1번 이상 (최소 한시간 간격), 간단한 양식에 따라 다음 정보를 입력해 주세요. \n감정과 수행할 행동은 한 가지만 입력해 주세요"),
                  SizedBox(height: 8),
                  Text(
                    "1. 지금 느끼는 감정과 현재 SUD점수를 기록합니다.",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text("예: 긴장됨, SUD 7점 (0~10점 중, 10에 가까울수록 불안이 큼)"),
                  Text(
                    "2. 현재 감정 상태로 수행한 활동을 입력합니다.",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text('예: 산책하기, 음악 듣기, 청소하기 등'),
                  Text(
                    "3. 활동 이후, 감정이 어떻게 변했는지와 SUD 점수를 기록합니다.",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text("예: 안정됨, SUD 3점"),
                  Text("(감정이 바뀌지 않았다면, 그대로 적어주세요.)"),
                  Text(
                    "4. 활동을 하며 얼마나 즐거웠는지(Pleasure), 얼마나 잘 해냈다고 느꼈는지(Mastery)를 점수로 입력해주세요.",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text("예: Pleasure 6점 / Mastery 5점 (0~10점 중)"),
                ],
              ),
            ),
          ),
            Card(
              elevation: 2,
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("기록 지표 설명",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo)),
                    SizedBox(height: 8),
                    Text("• SUD: 현재 느끼는 불안/스트레스 정도 (0~10)", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("• Pleasure: 활동에서 느낀 즐거움 정도 (0~10)", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("• Mastery: 활동 수행에 대한 성취감 (0~10)", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
              Text("현재 감정 상태", style: labelStyle),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedBeforeEmotion,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text("감정을 선택하세요"),
                items: emotionOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBeforeEmotion = value;
                    if (value != '기타(직접 입력)') {
                      _beforeEmotionController.text = value!;
                    } else {
                      _beforeEmotionController.clear();
                    }
                  });
                },
              ),
              if (_selectedBeforeEmotion == '기타(직접 입력)')
                const SizedBox(height: 8),
              if (_selectedBeforeEmotion == '기타(직접 입력)')
                TextFormField(
                  controller: _beforeEmotionController,
                  decoration: const InputDecoration(hintText: "감정을 직접 입력하세요", border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? "감정을 입력해주세요" : null,
                ),
              const SizedBox(height: 16),
              Text("현재 SUD: ${_beforeSud.toStringAsFixed(1)}", style: labelStyle),
              Slider(
                value: _beforeSud,
                min: 0,
                max: 10,
                divisions: 20,
                label: _beforeSud.toStringAsFixed(1),
                activeColor: Colors.indigo,
                onChanged: (value) => setState(() => _beforeSud = value),
              ),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 16),
              Text("수행한 활동", style: labelStyle),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedAction,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text("행동을 선택하세요"),
                items: actionOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value;
                    if (value != '기타(직접 입력)') {
                      _actionController.text = value!;
                    } else {
                      _actionController.clear();
                    }
                  });
                },
              ),
              if (_selectedAction == '기타(직접 입력)')
                const SizedBox(height: 8),
              if (_selectedAction == '기타(직접 입력)')
                TextFormField(
                  controller: _actionController,
                  decoration: const InputDecoration(hintText: "행동을 직접 입력하세요", border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? "행동을 입력해주세요" : null,
                ),
              const SizedBox(height: 16),
              Text("수행 후 감정 상태", style: labelStyle),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedAfterEmotion,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text("감정을 선택하세요"),
                items: emotionOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAfterEmotion = value;
                    if (value != '기타(직접 입력)') {
                      _afterEmotionController.text = value!;
                    } else {
                      _afterEmotionController.clear();
                    }
                  });
                },
              ),
              if (_selectedAfterEmotion == '기타(직접 입력)')
                const SizedBox(height: 8),
              if (_selectedAfterEmotion == '기타(직접 입력)')
                TextFormField(
                  controller: _afterEmotionController,
                  decoration: const InputDecoration(hintText: "감정을 직접 입력하세요", border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? "감정을 입력해주세요" : null,
                ),
              const SizedBox(height: 16),
              Text("수행 후 SUD: ${_afterSud.toStringAsFixed(1)}", style: labelStyle),
              Slider(
                value: _afterSud,
                min: 0,
                max: 10,
                divisions: 20,
                label: _afterSud.toStringAsFixed(1),
                activeColor: Colors.indigo,
                onChanged: (value) => setState(() => _afterSud = value),
              ),
              const SizedBox(height: 16),
              Text("Pleasure(즐거움): ${_pleasure.toStringAsFixed(1)}", style: labelStyle),
              Slider(
                value: _pleasure,
                min: 0,
                max: 10,
                divisions: 20,
                label: _pleasure.toStringAsFixed(1),
                activeColor: Colors.indigo,
                onChanged: (value) => setState(() => _pleasure = value),
              ),
              const SizedBox(height: 16),
              Text("Mastery(성취감): ${_mastery.toStringAsFixed(1)}", style: labelStyle),
              Slider(
                value: _mastery,
                min: 0,
                max: 10,
                divisions: 20,
                label: _mastery.toStringAsFixed(1),
                activeColor: Colors.indigo,
                onChanged: (value) => setState(() => _mastery = value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("기록 저장", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class EmotionBehaviorLog {
  final String time;
  final String beforeEmotion;
  final double beforeSud;
  final String action;
  final String afterEmotion;
  final double afterSud;
  final double pleasure;
  final double mastery;

  EmotionBehaviorLog({
    required this.time,
    required this.beforeEmotion,
    required this.beforeSud,
    required this.action,
    required this.afterEmotion,
    required this.afterSud,
    required this.pleasure,
    required this.mastery,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'beforeEmotion': beforeEmotion,
    'beforeSud': beforeSud,
    'action': action,
    'afterEmotion': afterEmotion,
    'afterSud': afterSud,
    'pleasure': pleasure,
    'mastery': mastery,
  };

  factory EmotionBehaviorLog.fromJson(Map<String, dynamic> json) => EmotionBehaviorLog(
    time: json['time'] ?? '',
    beforeEmotion: json['beforeEmotion'] ?? '',
    beforeSud: (json['beforeSud'] ?? 0).toDouble(),
    action: json['action'] ?? '',
    afterEmotion: json['afterEmotion'] ?? '',
    afterSud: (json['afterSud'] ?? 0).toDouble(),
    pleasure: (json['pleasure'] ?? 0).toDouble(),
    mastery: (json['mastery'] ?? 0).toDouble(),
  );
}