// lib/screens/diary_write_screen.dart
import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_emotion_selector.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';

class DiaryWriteScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;

  const DiaryWriteScreen({Key? key, required this.selectedDate, this.existingEntry}) : super(key: key);

  @override
  _DiaryWriteScreenState createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedEmotion;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadExistingData();
  }

  Future<void> _loadUserId() async {
    _currentUserId = await SecureStorageService().getUserId();
    setState(() {});
  }

  void _loadExistingData() {
    if (widget.existingEntry != null) {
      _contentController.text = widget.existingEntry!.content;
      _selectedEmotion = widget.existingEntry!.emotion;
      setState(() {});
    }
  }

  Future<void> _saveDiary() async {
    if (_currentUserId == null) {
      print('User ID is null. Cannot save diary.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID를 불러올 수 없습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    if (_selectedEmotion == null) {
      print('Emotion is not selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정을 선택해주세요!')),
      );
      return;
    }

    if (widget.existingEntry != null) {
      // Update existing diary entry
      final updatedEntry = DiaryEntry(
        date: widget.selectedDate,
        content: _contentController.text,
        emotion: _selectedEmotion!,
        userId: _currentUserId!,
      );
      await DatabaseService.instance.diaryRepository.updateDiary(updatedEntry);
    } else {
      // Create new diary entry
      final newEntry = DiaryEntry(
        date: widget.selectedDate,
        content: _contentController.text,
        emotion: _selectedEmotion!,
        userId: _currentUserId!,
      );
      await DatabaseService.instance.diaryRepository.insertDiary(newEntry);
    }

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: widget.selectedDate,
        leftButtonText: '취소',
        rightButtonText: '저장',
        onRightPressed: _saveDiary,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          color: const Color(0xFF1A1A1A),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              DiaryEmotionSelector(
                selectedEmotion: _selectedEmotion,
                onEmotionSelected: (emotion) {
                  setState(() {
                    _selectedEmotion = emotion;
                  });
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DiaryContentField(
                    controller: _contentController,
                    isReadOnly: false,
                  ),
                ),
              ),
              const SizedBox(height: 42.0),
            ],
          ),
        ),
      ),
    );
  }
}