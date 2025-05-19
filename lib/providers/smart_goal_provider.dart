import 'package:flutter/material.dart';
import '../models/smart_goal_event.dart';

class SmartGoalProvider with ChangeNotifier {
  final List<SmartGoalEvent> _events = [];

  List<SmartGoalEvent> get events => List.unmodifiable(_events);

  void addEvent(SmartGoalEvent event) {
    _events.add(event);
    notifyListeners();
  }
}
