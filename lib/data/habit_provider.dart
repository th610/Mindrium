import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitProvider extends ChangeNotifier {
  final List<String> _selectedHabits = [];
  final Map<String, IconData> _habitIcons = {};

  List<String> get selectedHabits => _selectedHabits;

  bool isSelected(String habit) => _selectedHabits.contains(habit);

  IconData getIconForHabit(String habit) {
    return _habitIcons[habit] ?? Icons.check_circle_outline;
  }

  void addHabitWithIcon(String habit, IconData icon) {
    if (_selectedHabits.contains(habit)) {
      _selectedHabits.remove(habit);
      _habitIcons.remove(habit);
    } else {
      _selectedHabits.add(habit);
      _habitIcons[habit] = icon;
    }
    notifyListeners();
  }

  Future<void> saveHabitPlan(String habitName, Map<String, String> fields) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habit_plans')
        .doc(habitName);

    await docRef.set({
      ...fields,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final habits = List<String>.from(doc.data()?['selectedHabits'] ?? []);
    final iconDataMap = Map<String, dynamic>.from(doc.data()?['habitIcons'] ?? {});

    _selectedHabits.clear();
    _habitIcons.clear();

    _selectedHabits.addAll(habits);
    iconDataMap.forEach((key, value) {
      _habitIcons[key] = IconData(
        value['codePoint'],
        fontFamily: value['fontFamily'],
      );
    });

    notifyListeners();
  }

  void clearSelectedHabits() {
    selectedHabits.clear();
    notifyListeners();
  }
}