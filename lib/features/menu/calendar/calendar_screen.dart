import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/calenadar_ui.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/data/calendar_manager.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted){
        context.read<CalendarManager>().loadEventsFromFirestore();
      }
    });     
  }

  void _onDateSelected(DateTime selectedDate) {
    debugPrint('선택한 날짜: $selectedDate');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarManager>(
      builder: (context, calendarManager, child) {
        return Scaffold(
          appBar: CustomAppBar(title: '나의 습관 캘린더'),
          backgroundColor: AppColors.grey100,
          body: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: AppCalendar(
              onDateSelected: _onDateSelected,
              events: calendarManager.entries,
            ),
          ),
        );
      },
    );
  }
}