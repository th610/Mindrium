import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'week3_classification_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Week3ClassificationScreen extends StatefulWidget {
  const Week3ClassificationScreen({super.key});

  @override
  Week3ClassificationScreenState createState() =>
      Week3ClassificationScreenState();
}

class Week3ClassificationScreenState extends State<Week3ClassificationScreen> {
  // 퀴즈 문장 데이터 (문장, 정답)
  final List<Map<String, dynamic>> quizSentences = [
    // 불안한 생각
    {'text': '나는 안전하지 않아', 'type': 'anxious'},
    {'text': '무언가 나쁜 일이 일어날 것이다', 'type': 'anxious'},
    {'text': '나쁜 일이 일어나지 않도록 미리 막아야 한다', 'type': 'anxious'},
    {'text': '사람들이 나를 비웃고 조롱할 것이다', 'type': 'anxious'},
    {'text': '나는 실수를 할 것이고, 그 실수는 돌이킬 수 없을 만큼 심각할 것이다', 'type': 'anxious'},
    {'text': '나는 두려움을 절대 감당할 수 없다', 'type': 'anxious'},
    {'text': '나는 자전거를 타다가 넘어지는 것에 대해서 지나치게 걱정한다', 'type': 'anxious'},
    {'text': '시험, 과제, 도전을 맞닥뜨리면 실패할 것 같다', 'type': 'anxious'},
    {'text': '내 몸이나 건강에 심각한 문제가 있다고 생각된다', 'type': 'anxious'},
    {'text': '내가 무언가를 완벽히 처리하지 못하면 큰일이 날 것이다', 'type': 'anxious'},
    {'text': '나는 항상 위험을 경계하고 대비해야만 한다', 'type': 'anxious'},
    // 건강한 생각
    {'text': '대부분의 경우, 실제로는 나쁜 일이 일어나지 않는다', 'type': 'healthy'},
    {'text': '설령 나쁜 일이 일어난다고 해도 나는 잘 대처할 수 있다', 'type': 'healthy'},
    {'text': '나는 생각보다 용기 있고, 대처 능력이 있다', 'type': 'healthy'},
    {'text': '두렵다고 해서 중요한 일을 포기하지 않아도 된다', 'type': 'healthy'},
    {'text': '누구나 실수할 수 있다. 실수는 인간의 당연한 모습이다', 'type': 'healthy'},
    {
      'text': '나는 완벽하지 않아도 괜찮다 (사람들은 완벽한 사람보다는 따뜻하고 친절한 사람을 더 좋아한다)',
      'type': 'healthy',
    },
    {'text': '문제 상황은 보통 내가 잘 해결할 수 있다', 'type': 'healthy'},
    {'text': '때로 불안을 느끼는 것은 정상이며 자연스러운 현상이다', 'type': 'healthy'},
    {'text': '나는 자전거를 타다가 넘어질 것 같다는 생각이 들어도, 용기내서 탈 수 있다', 'type': 'healthy'},
  ];

  late List<Map<String, dynamic>> shuffledSentences;
  int currentIndex = 0;
  String? feedback;
  Color? feedbackColor;
  bool answered = false;
  int correctCount = 0;
  List<Map<String, dynamic>> quizResults = [];

  @override
  void initState() {
    super.initState();
    shuffledSentences = List<Map<String, dynamic>>.from(quizSentences);
    shuffledSentences.shuffle();
  }

  void _nextSentence() {
    setState(() {
      if (currentIndex < shuffledSentences.length - 1) {
        currentIndex++;
        feedback = null;
        feedbackColor = null;
        answered = false;
      } else {
        // 마지막 문장 이후 결과 화면으로 이동
        saveQuizResult(correctCount, quizResults);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    Week3ClassificationResultScreen(
                      correctCount: correctCount,
                      quizResults: quizResults,
                    ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    });
  }

  void _checkAnswer(String selected) {
    if (answered) return;
    final correct = shuffledSentences[currentIndex]['type'] == selected;
    setState(() {
      answered = true;
      if (correct) {
        correctCount++;
        feedback = selected == 'healthy' ? '정답! 건강한 생각이에요.' : '정답! 불안한 생각이에요.';
        feedbackColor = const Color(0xFF4CAF50); // 초록
      } else {
        feedback =
            selected == 'healthy'
                ? '아쉬워요! 이건 불안한 생각이에요.'
                : '아쉬워요! 이건 건강한 생각이에요.';
        feedbackColor = const Color(0xFFFF5252); // 빨강
      }
      // 결과 저장
      quizResults.add({
        'text': shuffledSentences[currentIndex]['text'],
        'correctType': shuffledSentences[currentIndex]['type'],
        'userChoice': selected,
        'isCorrect': correct,
      });
    });
  }

  Future<void> saveQuizResult(
    int correctCount,
    List<Map<String, dynamic>> quizResults,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // 전체 맞은 개수 저장
    await prefs.setInt('week3_classification_correct_count', correctCount);
    // 오답 문항만 추출
    final wrongList =
        quizResults
            .where((item) => item['isCorrect'] == false)
            .map(
              (item) => {
                'text': item['text'],
                'userChoice': item['userChoice'],
                'correctType': item['correctType'],
              },
            )
            .toList();
    await prefs.setString(
      'week3_classification_wrong_list',
      wrongList.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '3주차 - Self Talk'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 카드
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Question icon above title
                        Image.asset(
                          'assets/image/question_icon.png',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '불안한 생각과 건강한 생각을\n구분해 볼까요?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // 퀴즈 문장
                        Text(
                          shuffledSentences[currentIndex]['text'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        Text(
                          '${currentIndex + 1}/${shuffledSentences.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 하단 카드
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "건강한 생각인지 불안한 생각인지 선택한 후 '다음'버튼을 누르세요.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // 피드백 영역 (고정 높이)
                      SizedBox(
                        height: 56,
                        child:
                            feedback != null
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '💡',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        feedback!,
                                        style: TextStyle(
                                          color: feedbackColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                )
                                : Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3FE),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: const [
                                      Text(
                                        '💡',
                                        style: TextStyle(fontSize: 22),
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '여기에서 정답을 확인할 수 있어요!',
                                          style: TextStyle(
                                            color: Color(0xFF8888AA),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _checkAnswer('healthy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2962F6),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 140),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '건강한 생각',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _checkAnswer('anxious'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                226,
                                86,
                                86,
                              ),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 140),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '불안한 생각',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // new spacing
            // Removed Spacer to let cards expand directly above navigation buttons.
            NavigationButtons(
              onBack: () => Navigator.pop(context),
              onNext: () {
                if (answered) {
                  _nextSentence();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
