import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_body_with_navigation.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';

class DiaryViewScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DiaryViewScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _DiaryViewScreenState createState() => _DiaryViewScreenState();
}

class _DiaryViewScreenState extends State<DiaryViewScreen> {
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
        rightButtonText: _diaryEntry != null ? '수정' : null,
        rightButtonColor: const Color(0xFFFF4646),
        rightButtonFontWeight: FontWeight.bold,
        onRightPressed: _diaryEntry != null ? () {
          // TODO: 수정 화면으로 이동
        } : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _diaryEntry == null
              ? const Center(
                  child: Text(
                    '해당 날짜에 일기가 없습니다.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : GestureDetector(
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
                          imageWidth: 92,
                          imageHeight: 142,
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
                ),
    );
  }
}