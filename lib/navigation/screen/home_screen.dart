import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/activitiy_card.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/navigation/navigation.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/user_provider.dart';

import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/widgets/task_tile.dart';

import 'treatment_screen.dart';
import 'mindrium_screen.dart';
import 'report_screen.dart';
import 'myinfo_screen.dart';

import 'package:gad_app_team/test/test_data_collection.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  int daysSinceJoin = 0;
  final String date = DateFormat('yyyy년 MM월 dd일').format(DateTime.now());
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
      userProvider.loadUserData(dayCounter: dayCounter);
    });
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: _buildBody(),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homePage();
      case 1:
        return const TreatmentScreen();
      case 2:
        return const MindriumScreen();
      case 3:
        return const ReportScreen();
      case 4:
        return const MyInfoScreen();
      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    final userId = context.watch<UserProvider>().userId; //데이터 수집
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal:AppSizes.padding),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.space),
          _dataCollection(context, userId),    //데이터 수집
          const SizedBox(height: AppSizes.space),//데이터 수집
          _buildReportSummary(),
          const SizedBox(height: AppSizes.space),
          _buildTodayTasks(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userService = context.watch<UserProvider>();
    final dayCounter = context.watch<UserDayCounter>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${userService.userName}님, \n좋은 하루 되세요!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),    
              Text(
                '${dayCounter.daysSinceJoin}일째 되는 날',
                style: const TextStyle(fontSize: AppSizes.fontSize, color: AppColors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.pushNamed(context, '/contents'),
        ),
      ],
    );
  }

  Widget _buildTodayTasks() {
    final tasks = ['일일 과제1', '일일 과제2', '일일 과제3', '일일 과제4', '일일 과제5'];

    return CardContainer(
      title: '오늘의 할일',
      child: Column(
        children: List.generate(tasks.length, (index) => TaskTile(title: tasks[index], route: '/home',)),
      ),
    );
  }

  

  Widget _buildReportSummary() {
    final anxietyScores = [5.0, 3.0, 4.0, 2.0, 1.0, 3.0, 5.0];

    return CardContainer(
      title: '주간 불안감 변화',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.grey300,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      anxietyScores.length,
                      (index) => FlSpot(index.toDouble(), anxietyScores[index]),
                    ),
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.indigo,
                        strokeColor: AppColors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.withAlpha((255 * 0.2).toInt()),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space),
          const Text('이번 주 평균 불안감: 5.1점', style: TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }

//데이터 수집
  Widget _dataCollection(BuildContext context, String userId) {
    return ActivityCard(
      title: '감정-행동 기록',
      icon: Icons.description,
      enabled: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmotionLogForm(userId: userId),
          ),
        );
      },
    );
  }
}