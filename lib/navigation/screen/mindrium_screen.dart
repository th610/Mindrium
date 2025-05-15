import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gad_app_team/data/anxiety_cause.dart';
import 'package:gad_app_team/features/menu/exposure/anxiety_ocean_screen.dart';

class MindriumScreen extends StatefulWidget {
  const MindriumScreen({super.key});

  @override
  State<MindriumScreen> createState() => _MindriumScreenState();
}

class _MindriumScreenState extends State<MindriumScreen> {
  bool _isLoading = true;
  List<AnxietyCause> _anxietyCauses = [];
  List<String> _selectedEmotions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final causesQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('anxiety_causes')
            .orderBy('order')
            .get();

        final causes = causesQuery.docs.map((doc) {
          final data = doc.data();
          return AnxietyCause(
            id: data['id'],
            title: data['title'],
            description: data['description'] ?? '',
            anxietyLevel: (data['anxietyLevel'] as num).toDouble(),
            fishEmoji: data['fishEmoji'] ?? '🐟',
            selectedEmotions: List<String>.from(data['selectedEmotions'] ?? []),
          );
        }).toList();

        setState(() {
          _anxietyCauses = causes;
          _selectedEmotions = List<String>.from(userDoc.data()?['selectedEmotions'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('데이터 로딩 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B5FD6)),
          ),
        ),
      );
    }

    return AnxietyOceanScreen(
      anxietyCauses: _anxietyCauses,
      selectedEmotions: _selectedEmotions,
      entrySource: 'mindrium',
      showCompleteButton: false,
      showAppBar: false,
      readOnly: true,
    );
  }
}