import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';

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
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일기 조회 - ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}'),
        backgroundColor: const Color(0xFF363636),
        actions: [
          // TODO: 필요시 일기 수정 버튼 추가
          // IconButton(
          //   icon: const Icon(Icons.edit, color: Colors.white),
          //   onPressed: () {
          //     // 수정 화면으로 이동 로직
          //   },
          // ),
        ],
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _diaryEntry == null
              ? const Center(
                  child: Text(
                    '해당 날짜에 일기가 없습니다.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '감정: ${_diaryEntry!.emotion}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _diaryEntry!.content,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 