import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_body_with_navigation.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';

class DiaryPromptScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DiaryPromptScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _DiaryPromptScreenState createState() => _DiaryPromptScreenState();
}

class _DiaryPromptScreenState extends State<DiaryPromptScreen> {
  DiaryEntry? _diaryEntry;
  String? _currentUserId;
  bool _isLoading = true;
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDiaryEntry();
  }

  Future<void> _loadDiaryEntry() async {
    _currentUserId = await SecureStorageService().getUserId();
    if (_currentUserId != null) {
      _diaryEntry = await DatabaseService.instance.diaryRepository.getDiaryByDateAndUserId(
        widget.selectedDate,
        _currentUserId!,
      );
      if (_diaryEntry != null) {
        _contentController.text = _diaryEntry!.content;
      }
    }
    setState(() {
      _isLoading = false;
    });
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
        leftButtonText: '닫기',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _diaryEntry == null
              ? _buildPromptContent()
              : _buildDiaryContent(),
    );
  }

  Widget _buildPromptContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '아직 일기를 작성하지 않았어요!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            '오늘의 감정과 이야기를\n일기로 남겨보세요',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Text(
            '✏️',
            style: TextStyle(fontSize: 64),
          ),
          SizedBox(height: 32),
          Text(
            '일기 쓰기 버튼을 눌러\n새로운 일기를 시작해보세요!',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryContent() {
    return GestureDetector(
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
            DiaryBodyWithNavigation(
              emotion: _diaryEntry!.emotion,
              onLeftSwipe: () {
                // TODO: Navigate to previous day
              },
              onRightSwipe: () {
                // TODO: Navigate to next day
              },
            ),
            const SizedBox(height: 40.0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DiaryContentField(
                  controller: _contentController,
                  isReadOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 42.0),
          ],
        ),
      ),
    );
  }
}