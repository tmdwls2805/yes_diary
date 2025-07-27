import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/diary_entity.dart';
import '../../widgets/diary_header.dart';
import '../../widgets/diary_body_with_navigation.dart';
import '../../widgets/diary_content_field.dart';
import '../../core/di/injection_container.dart';
import 'diary_write_view.dart';

class DiaryViewView extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final DateTime? createdAt;

  const DiaryViewView({Key? key, required this.selectedDate, this.createdAt}) : super(key: key);

  @override
  ConsumerState<DiaryViewView> createState() => _DiaryViewViewState();
}

class _DiaryViewViewState extends ConsumerState<DiaryViewView> {
  final TextEditingController _contentController = TextEditingController();
  late DateTime _currentDate;
  DateTime? _joinDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _joinDate = widget.createdAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiaryEntry();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryEntry() async {
    final userState = ref.read(userViewModelProvider);
    if (userState.user?.userId == null) return;

    // Set join date if not provided
    if (_joinDate == null) {
      _joinDate = userState.user?.createdAt ?? DateTime.now().subtract(const Duration(days: 30));
    }

    final diaryViewModel = ref.read(diaryViewModelProvider.notifier);
    await diaryViewModel.loadDiaryForDate(_currentDate, userState.user!.userId);
    
    final diaryState = ref.read(diaryViewModelProvider);
    final diary = diaryViewModel.getDiaryForDate(_currentDate);
    
    if (diary != null) {
      _contentController.text = diary.content;
    } else {
      _contentController.clear();
    }
  }

  Future<void> _navigateToDate(DateTime newDate) async {
    setState(() {
      _currentDate = newDate;
    });
    await _loadDiaryEntry();
  }

  bool _canNavigateToPrevious() {
    if (_joinDate == null) return false;
    final previousDay = _currentDate.subtract(const Duration(days: 1));
    final joinMonthFirstDay = DateTime(_joinDate!.year, _joinDate!.month, 1);
    return !previousDay.isBefore(joinMonthFirstDay);
  }

  bool _canNavigateToNext() {
    final nextDay = _currentDate.add(const Duration(days: 1));
    final today = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(diaryViewModelProvider);
    final userState = ref.watch(userViewModelProvider);
    
    if (userState.user?.userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final diaryViewModel = ref.read(diaryViewModelProvider.notifier);
    final currentDiary = diaryViewModel.getDiaryForDate(_currentDate);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: _currentDate,
        leftButtonText: '닫기',
        rightButtonText: currentDiary != null ? '수정' : null,
        rightButtonColor: const Color(0xFFFF4646),
        rightButtonFontWeight: FontWeight.bold,
        onRightPressed: currentDiary != null ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryWriteView(
                selectedDate: _currentDate,
                existingDiary: currentDiary,
              ),
            ),
          ).then((_) {
            _loadDiaryEntry();
          });
        } : null,
      ),
      body: diaryState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : currentDiary == null
              ? _buildNoDiaryView()
              : _buildDiaryView(currentDiary),
    );
  }

  Widget _buildNoDiaryView() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryWriteView(selectedDate: _currentDate),
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
    );
  }

  Widget _buildDiaryView(DiaryEntity diary) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
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
              emotion: diary.emotion,
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
    );
  }
}