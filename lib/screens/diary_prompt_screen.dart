import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_body_with_navigation.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';
import 'package:yes_diary/screens/diary_write_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiaryPromptScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime? createdAt;

  const DiaryPromptScreen({Key? key, required this.selectedDate, this.createdAt}) : super(key: key);

  @override
  _DiaryPromptScreenState createState() => _DiaryPromptScreenState();
}

class _DiaryPromptScreenState extends State<DiaryPromptScreen> {
  DiaryEntry? _diaryEntry;
  String? _currentUserId;
  bool _isLoading = true;
  final TextEditingController _contentController = TextEditingController();
  DateTime? _joinDate;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _joinDate = widget.createdAt;
    _loadDiaryEntry();
  }

  Future<void> _loadDiaryEntry() async {
    _currentUserId = await SecureStorageService().getUserId();
    
    // createdAt이 parameter로 전달되지 않은 경우에만 storage에서 로드
    if (_joinDate == null) {
      final createdAtString = await SecureStorageService().getCreatedAt();
      print('DEBUG: createdAtString from storage: $createdAtString');
      
      if (createdAtString != null && createdAtString.isNotEmpty) {
        try {
          _joinDate = DateTime.parse(createdAtString);
          print('DEBUG: Parsed join date from storage: $_joinDate');
        } catch (e) {
          print('DEBUG: Error parsing createdAtString: $e, using fallback');
          _joinDate = DateTime.now().subtract(const Duration(days: 30));
        }
      } else {
        print('DEBUG: createdAtString is null or empty, using default join date (30 days ago)');
        _joinDate = DateTime.now().subtract(const Duration(days: 30));
      }
    } else {
      print('DEBUG: Using createdAt from parameter: $_joinDate');
    }
    
    if (_currentUserId != null) {
      _diaryEntry = await DatabaseService.instance.diaryRepository.getDiaryByDateAndUserId(
        _currentDate,
        _currentUserId!,
      );
      if (_diaryEntry != null) {
        _contentController.text = _diaryEntry!.content;
      } else {
        _contentController.clear();
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

  Future<void> _navigateToDate(DateTime newDate) async {
    setState(() {
      _isLoading = true;
      _currentDate = newDate;
    });
    await _loadDiaryEntry();
  }

  bool _canNavigateToPrevious() {
    if (_joinDate == null) {
      print('DEBUG: _joinDate is null, cannot navigate to previous');
      return false;
    }
    final previousDay = _currentDate.subtract(const Duration(days: 1));
    final joinDateNormalized = DateTime(_joinDate!.year, _joinDate!.month, _joinDate!.day);
    final canNavigate = !previousDay.isBefore(joinDateNormalized);
    print('DEBUG: Current date: $_currentDate, Previous day: $previousDay, Join date: $joinDateNormalized, Can navigate: $canNavigate');
    return canNavigate;
  }

  bool _canNavigateToNext() {
    final nextDay = _currentDate.add(const Duration(days: 1));
    final today = DateTime.now();
    return !nextDay.isAfter(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: _currentDate,
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
              ? GestureDetector(
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
                          hardcodedImagePath: 'assets/emotion/green_body.svg', // 하드코딩된 green_body.svg
                          customText: '${DateFormat('M월 d일').format(_currentDate)}은 일기를 작성하지 않았어요.\n이날의 일기를 작성하시겠습니까?',
                          onLeftSwipe: _canNavigateToPrevious() ? () {
                            final previousDay = _currentDate.subtract(const Duration(days: 1));
                            _navigateToDate(previousDay);
                          } : null,
                          onRightSwipe: _canNavigateToNext() ? () {
                            final nextDay = _currentDate.add(const Duration(days: 1));
                            _navigateToDate(nextDay);
                          } : null,
                          imageWidth: 92,
                          imageHeight: 142,
                        ),
                        const SizedBox(height: 28.0),
                        Center(
                          child: SizedBox(
                            width: 264,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiaryWriteScreen(selectedDate: _currentDate),
                                  ),
                                ).then((_) {
                                  // 일기 작성 후 돌아왔을 때 데이터 새로고침
                                  _loadDiaryEntry();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4646),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '일기 작성하기',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SvgPicture.asset(
                                    'assets/icon/write_diary.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 42.0),
                      ],
                    ),
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
                          onLeftSwipe: _canNavigateToPrevious() ? () {
                            final previousDay = _currentDate.subtract(const Duration(days: 1));
                            _navigateToDate(previousDay);
                          } : null,
                          onRightSwipe: _canNavigateToNext() ? () {
                            final nextDay = _currentDate.add(const Duration(days: 1));
                            _navigateToDate(nextDay);
                          } : null,
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