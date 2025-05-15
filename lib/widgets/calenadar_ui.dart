import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/activitiy_card.dart';
import 'package:gad_app_team/data/calendar_manager.dart';

class AppCalendar extends StatefulWidget {
  final Function(DateTime selectedDate) onDateSelected;
  final Map<DateTime, List<AppCalendarEntry>> events;

  const AppCalendar({
    super.key,
    required this.onDateSelected,
    required this.events,
  });

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<AppCalendarEntry> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return widget.events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return ListView(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            color: Colors.white,
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected(selectedDay);
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.indigo, width: 1),
                ),
              ),
              selectedDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: Colors.black),
              weekendTextStyle: TextStyle(fontSize: AppSizes.fontSize, color: Colors.red),
              defaultTextStyle: TextStyle(fontSize: AppSizes.fontSize),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, size: 28),
              rightChevronIcon: Icon(Icons.chevron_right, size: 28),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
              weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '이벤트',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (selectedEvents.isNotEmpty)
          ...selectedEvents.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActivityCard(
                icon: Icons.calendar_month,
                title: entry.title,
                enabled: true,
                boxShadow: [],
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(entry.title),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (entry.smartDetails?.entries.map<Widget>((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('${e.key}: ${e.value}'),
                          );
                        }).toList() ?? [Text(entry.description)]),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('닫기'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<CalendarManager>().removeEntry(entry);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('항목이 삭제되었습니다.')),
                            );
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
              )
            );
          })
        else
          Text(
            '등록된 이벤트가 없습니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }
}