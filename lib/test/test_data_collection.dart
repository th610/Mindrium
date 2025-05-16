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

  double _beforeSud = 5;
  double _afterSud = 5;
  double _pleasure = 5;
  double _mastery = 5;

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
          content: const Text(
            "기록이 성공적으로 저장되었습니다.\n\n여러분의 소중한 기록은 감정 흐름을 이해하고 더 나은 정신건강 기술을 개발하는 데 큰 도움이 됩니다.",
          ),
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
        _beforeSud = _afterSud = _pleasure = _mastery = 5;
      });
    }
  }

  @override
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
                  Text("하루 1번 이상 (최소 한시간 간격), 간단한 양식에 따라 다음 정보를 입력해 주세요"),
                  SizedBox(height: 8),
                  Text(
                    "1. 지금 느끼는 감정과 현재 SUD점수를 기록합니다.",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text("예: 긴장됨, SUD 7점 (0~10점 중, 10에 가까울수록 불안이 큼)"),
                  Text(
                    "2. 현재 감정 상태로 수행할 활동을 입력합니다.",
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
                  Text("예: Pleasure 6wja / Mastery 5점 (0~10점 중)"),
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
                    Text("• SUD: 현재 느끼는 불안/스트레스 정도 (0~10)"),
                    Text("• Pleasure: 활동에서 느낀 즐거움 정도 (0~10)"),
                    Text("• Mastery: 활동 수행에 대한 숙달감 (0~10)"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text("현재 감정 상태", style: labelStyle),
            const SizedBox(height: 4),
            TextFormField(
              controller: _beforeEmotionController,
              decoration: const InputDecoration(
                hintText: "예: 불안함, 초조함 등",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? "입력해주세요" : null,
            ),
            const SizedBox(height: 16),
            Text("현재 SUD: ${_beforeSud.toStringAsFixed(1)}", style: labelStyle),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.indigo,
                thumbColor: Colors.indigo,
              ),
              child: Slider(
                value: _beforeSud,
                min: 0,
                max: 10,
                divisions: 20,
                label: _beforeSud.toStringAsFixed(1),
                onChanged: (value) => setState(() => _beforeSud = value),
              ),
            ),
            
            const Divider(thickness: 1, color: Colors.grey),
            
            const SizedBox(height: 16),
            Text("수행할 행동", style: labelStyle),
            const SizedBox(height: 4),
            TextFormField(
              controller: _actionController,
              decoration: const InputDecoration(
                hintText: "예: 발표, 운동, 산책 등",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? "입력해주세요" : null,
            ),

            const SizedBox(height: 16),
            Text("수행 후 감정 상태", style: labelStyle),
            const SizedBox(height: 4),
            TextFormField(
              controller: _afterEmotionController,
              decoration: const InputDecoration(
                hintText: "예: 편안함, 안정됨, 불안함 등",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? "입력해주세요" : null,
            ),
            const SizedBox(height: 16),
            Text("수행 후 SUD: ${_afterSud.toStringAsFixed(1)}", style: labelStyle),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.indigo,
                thumbColor: Colors.indigo,
              ),
              child: Slider(
                value: _afterSud,
                min: 0,
                max: 10,
                divisions: 20,
                label: _afterSud.toStringAsFixed(1),
                onChanged: (value) => setState(() => _afterSud = value),
              ),
            ),

            const SizedBox(height: 16),
            Text("Pleasure: ${_pleasure.toStringAsFixed(1)}", style: labelStyle),
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
            Text("Mastery: ${_mastery.toStringAsFixed(1)}", style: labelStyle),
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
              child: ElevatedButton.icon(
                label:  Text("기록 저장", style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
      ),
      )
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

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'beforeEmotion': beforeEmotion,
      'beforeSud': beforeSud,
      'action': action,
      'afterEmotion': afterEmotion,
      'afterSud': afterSud,
      'pleasure': pleasure,
      'mastery': mastery,
    };
  }

  factory EmotionBehaviorLog.fromJson(Map<String, dynamic> json) {
    return EmotionBehaviorLog(
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
}