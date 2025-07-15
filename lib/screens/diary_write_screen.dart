// lib/screens/diary_write_screen.dart
import 'package:flutter/material.dart';

class DiaryWriteScreen extends StatelessWidget {
  final DateTime selectedDate;

  const DiaryWriteScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write Diary for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
        backgroundColor: const Color(0xFF363636), // Match calendar background
      ),
      backgroundColor: const Color(0xFF363636),
      body: const Center(
        child: Text(
          'This is your diary writing screen!',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}