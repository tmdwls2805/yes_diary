import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart'; // Make sure this path is correct
import 'package:yes_diary/core/services/storage/secure_storage_service.dart'; // Make sure this path is correct
import 'package:yes_diary/widgets/diary_header.dart'; // Make sure this path is correct
import 'package:yes_diary/widgets/diary_body_with_navigation.dart'; // Make sure this path is correct
import 'package:yes_diary/widgets/diary_content_field.dart'; // Make sure this path is correct
import 'package:yes_diary/screens/diary_write_screen.dart'; // Make sure this path is correct
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiaryViewScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime? createdAt;

  const DiaryViewScreen({Key? key, required this.selectedDate, this.createdAt}) : super(key: key);

  @override
  _DiaryViewScreenState createState() => _DiaryViewScreenState();
}

class _DiaryViewScreenState extends State<DiaryViewScreen> {
  DiaryEntry? _diaryEntry;
  String? _currentUserId;
  bool _isLoading = true;
  final TextEditingController _contentController = TextEditingController();
  DateTime? _joinDate;
  late DateTime _currentDate;
  bool _isDropdownVisible = false; // State to manage dropdown visibility

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
          // Fallback if parsing fails
          _joinDate = DateTime.now().subtract(const Duration(days: 30));
        }
      } else {
        print('DEBUG: createdAtString is null or empty, using default join date (30 days ago)');
        // Fallback if string is null or empty
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
    // Check against the first day of the month the user joined
    final joinMonthFirstDay = DateTime(_joinDate!.year, _joinDate!.month, 1);
    final canNavigate = !previousDay.isBefore(joinMonthFirstDay);
    print('DEBUG: Current date: $_currentDate, Previous day: $previousDay, Join month first day: $joinMonthFirstDay, Can navigate: $canNavigate');
    return canNavigate;
  }

  bool _canNavigateToNext() {
    final nextDay = _currentDate.add(const Duration(days: 1));
    final today = DateTime.now();
    // Cannot navigate past today
    return !nextDay.isAfter(DateTime(today.year, today.month, today.day));
  }

  void _handleSwipeLeft() {
    if (_canNavigateToNext()) {
      final nextDay = _currentDate.add(const Duration(days: 1));
      _navigateToDate(nextDay);
    }
  }

  void _handleSwipeRight() {
    if (_canNavigateToPrevious()) {
      final previousDay = _currentDate.subtract(const Duration(days: 1));
      _navigateToDate(previousDay);
    }
  }

  // Toggles the visibility of the dropdown menu
  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: _currentDate,
        leftButtonText: '닫기',
        rightButtonWidget: _diaryEntry != null
            ? GestureDetector(
                onTap: _toggleDropdown,
                child: SvgPicture.asset(
                  _isDropdownVisible
                      ? 'assets/icon/edit_active.svg'
                      : 'assets/icon/edit_inactive.svg',
                  width: 24,
                  height: 24,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _diaryEntry == null
                  ? GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        if (_isDropdownVisible) {
                          _toggleDropdown();
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        const double sensitivity = 300.0;
                        if (details.velocity.pixelsPerSecond.dx > sensitivity) {
                          _handleSwipeRight();
                        } else if (details.velocity.pixelsPerSecond.dx < -sensitivity) {
                          _handleSwipeLeft();
                        }
                      },
                      child: Container(
                        color: const Color(0xFF1A1A1A),
                        width: double.infinity,
                        height: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DiaryBodyWithNavigation(
                              hardcodedImagePath: 'assets/emotion/gray_body.svg',
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
                            GestureDetector(
                              onHorizontalDragEnd: (details) {
                                const double sensitivity = 300.0;
                                if (details.velocity.pixelsPerSecond.dx > sensitivity) {
                                  _handleSwipeRight();
                                } else if (details.velocity.pixelsPerSecond.dx < -sensitivity) {
                                  _handleSwipeLeft();
                                }
                              },
                              child: Center(
                                child: SizedBox(
                                  width: 264,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_isDropdownVisible) {
                                        _toggleDropdown();
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DiaryWriteScreen(selectedDate: _currentDate),
                                        ),
                                      ).then((_) {
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
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        if (_isDropdownVisible) {
                          _toggleDropdown();
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        const double sensitivity = 300.0;
                        if (details.velocity.pixelsPerSecond.dx > sensitivity) {
                          _handleSwipeRight();
                        } else if (details.velocity.pixelsPerSecond.dx < -sensitivity) {
                          _handleSwipeLeft();
                        }
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
                                child: GestureDetector(
                                  onHorizontalDragEnd: (details) {
                                    const double sensitivity = 300.0;
                                    if (details.velocity.pixelsPerSecond.dx > sensitivity) {
                                      _handleSwipeRight();
                                    } else if (details.velocity.pixelsPerSecond.dx < -sensitivity) {
                                      _handleSwipeLeft();
                                    }
                                  },
                                  child: DiaryContentField(
                                    controller: _contentController,
                                    isReadOnly: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 42.0),
                          ],
                        ),
                      ),
                    ),

          // Dropdown Menu
          if (_isDropdownVisible)
            Positioned(
              right: 16.0,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
                child: SizedBox(
                  width: 120.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          _toggleDropdown();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiaryWriteScreen(
                                selectedDate: _currentDate,
                                existingEntry: _diaryEntry,
                              ),
                            ),
                          ).then((_) {
                            _loadDiaryEntry();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icon/write_diary.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 8.0),
                              const Text(
                                '수정하기',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 100.0,
                          child: const Divider(
                            height: 1,
                            color: Color(0xFFD6D6D6),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _toggleDropdown();
                          // TODO: Implement delete functionality
                          print('일기 삭제하기 버튼이 눌렸습니다.');
                          // Example: DatabaseService.instance.diaryRepository.deleteDiary(_diaryEntry!.id!);
                          // Then, you might want to navigate back or refresh the view to show no entry for the date.
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icon/trash.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(Colors.redAccent, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 8.0),
                              const Text(
                                '삭제하기',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}