import 'package:flutter/material.dart';
import 'package:yes_diary/core/constants/app_image.dart';
import 'package:yes_diary/widgets/confirm_dialog.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/services/ad_service.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';
import 'package:yes_diary/screens/diary_write_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiaryViewScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime? createdAt;

  const DiaryViewScreen({Key? key, required this.selectedDate, this.createdAt})
      : super(key: key);

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
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _joinDate = widget.createdAt;
    _loadDiaryEntry();
  }

  Future<void> _loadDiaryEntry() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    _currentUserId = await SecureStorageService().getUserId();

    if (_joinDate == null) {
      final createdAtString = await SecureStorageService().getCreatedAt();
      if (createdAtString != null && createdAtString.isNotEmpty) {
        try {
          _joinDate = DateTime.parse(createdAtString);
        } catch (e) {
          _joinDate = DateTime.now().subtract(const Duration(days: 30));
        }
      } else {
        _joinDate = DateTime.now().subtract(const Duration(days: 30));
      }
    }

    if (_currentUserId != null) {
      _diaryEntry = await DatabaseService.instance.diaryRepository
          .getDiaryByDateAndUserId(
        _currentDate,
        _currentUserId!,
      );
      if (_diaryEntry != null) {
        _contentController.text = _diaryEntry!.content;
      } else {
        _contentController.clear();
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
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

  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  Future<bool> _isLocalUser() async {
    final localUserId = await SecureStorageService().getLocalUserId();
    return localUserId != null && _currentUserId == localUserId;
  }

  Future<void> _showLocalUserDiaryAdIfNeeded() async {
    if (!await _isLocalUser()) return;
    await AdService.showDiarySavedInterstitialIfAvailable();
  }

  Future<void> _handleEditDiary() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          selectedDate: _currentDate,
          existingEntry: _diaryEntry,
          showAdOnSave: false,
        ),
      ),
    );
    await _loadDiaryEntry();
    if (result == true && mounted) {
      await showSaveConfirmDialog(context);
      if (!mounted) return;
      await _showLocalUserDiaryAdIfNeeded();
    }
  }

  Future<void> _handleDeleteDiary() async {
    if (_diaryEntry == null || _currentUserId == null) return;

    final bool? confirmed = await showDeleteConfirmDialog(context);
    if (confirmed != true || !mounted) return;

    final shouldShowAd = await _isLocalUser();
    await DatabaseService.instance.diaryRepository
        .deleteDiaryByDateAndUserId(_currentDate, _currentUserId!);

    await _loadDiaryEntry();

    if (shouldShowAd) {
      await AdService.showDiarySavedInterstitialIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: _currentDate,
        leftButtonText: '닫기',
        rightButtonText: _diaryEntry != null ? '수정' : null,
        onRightPressed: _diaryEntry != null ? _handleEditDiary : null,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
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
                        } else if (details.velocity.pixelsPerSecond.dx <
                            -sensitivity) {
                          _handleSwipeLeft();
                        }
                      },
                      child: Container(
                        color: const Color(0xFF1A1A1A),
                        width: double.infinity,
                        height: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 94.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: _canNavigateToPrevious()
                                        ? IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              final previousDay = _currentDate
                                                  .subtract(const Duration(
                                                      days: 1));
                                              _navigateToDate(previousDay);
                                            },
                                            icon: Transform.rotate(
                                              angle: 3.14159,
                                              child: SvgPicture.asset(
                                                'assets/button/swipe.svg',
                                                width: 42,
                                                height: 42,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  Image.asset(
                                    'assets/emotion/trash.png',
                                    height: 94,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: _canNavigateToNext()
                                        ? IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              final nextDay = _currentDate
                                                  .add(const Duration(days: 1));
                                              _navigateToDate(nextDay);
                                            },
                                            icon: SvgPicture.asset(
                                              'assets/button/swipe.svg',
                                              width: 42,
                                              height: 42,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0),
                              child: Text(
                                '${DateFormat('M월 d일').format(_currentDate)}은 일기를 작성하지 않았어요.\n이날의 일기를 작성하시겠습니까?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 28.0),
                            Center(
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
                                        builder: (context) => DiaryWriteScreen(
                                          selectedDate: _currentDate,
                                          showAdOnSave: false,
                                        ),
                                      ),
                                    ).then((result) async {
                                      // [수정] 반환 값을 받도록 변경
                                      // 글쓰기 화면에서 돌아오면 항상 데이터를 새로고침
                                      await _loadDiaryEntry();
                                      // 저장 성공 시: 팝업 → 확인 → 광고
                                      if (result == true && mounted) {
                                        await showSaveConfirmDialog(context);
                                        if (!mounted) return;
                                        await _showLocalUserDiaryAdIfNeeded();
                                      }
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
                        } else if (details.velocity.pixelsPerSecond.dx <
                            -sensitivity) {
                          _handleSwipeLeft();
                        }
                      },
                      child: Container(
                        color: const Color(0xFF1A1A1A),
                        width: double.infinity,
                        height: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 28.0),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SizedBox(
                                height: 216,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: _canNavigateToPrevious()
                                        ? IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              final previousDay = _currentDate
                                                  .subtract(const Duration(
                                                      days: 1));
                                              _navigateToDate(previousDay);
                                            },
                                            icon: Transform.rotate(
                                              angle: 3.14159,
                                              child: SvgPicture.asset(
                                                'assets/button/swipe.svg',
                                                width: 42,
                                                height: 42,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Image.asset(
                                        AppImages.emotionCardImagePaths[
                                                _diaryEntry!.emotionName] ??
                                            AppImages
                                                .emotionCardImagePaths['red']!,
                                        height: 216,
                                        fit: BoxFit.contain,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16,
                                          left: 16,
                                          right: 16,
                                        ),
                                        child: Text(
                                          (_diaryEntry!.cardMessage != null &&
                                                  _diaryEntry!
                                                      .cardMessage!.isNotEmpty)
                                              ? _diaryEntry!.cardMessage!
                                              : (AppImages.emotionCardTexts[
                                                      _diaryEntry!
                                                          .emotionName] ??
                                                  ''),
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Pretendard',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: _canNavigateToNext()
                                        ? IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              final nextDay = _currentDate
                                                  .add(const Duration(days: 1));
                                              _navigateToDate(nextDay);
                                            },
                                            icon: SvgPicture.asset(
                                              'assets/button/swipe.svg',
                                              width: 42,
                                              height: 42,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              ),
                            ),
                            const SizedBox(height: 28.0),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: DiaryContentField(
                                  controller: _contentController,
                                  isReadOnly: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _handleDeleteDiary,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4646),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '감정 해소 완료',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 56.0),
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
                                showAdOnSave: false,
                              ),
                            ),
                          ).then((result) async {
                            // [수정] 반환 값을 받도록 변경
                            // 수정 화면에서 돌아오면 항상 데이터를 새로고침
                            await _loadDiaryEntry();
                            // 저장 성공 시: 팝업 → 확인 → 광고
                            if (result == true && mounted) {
                              await showSaveConfirmDialog(context);
                              if (!mounted) return;
                              await _showLocalUserDiaryAdIfNeeded();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icon/write_diary.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                    Colors.black87, BlendMode.srcIn),
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
                        child: SizedBox(
                          width: 100.0,
                          child: const Divider(
                            height: 1,
                            color: Color(0xFFD6D6D6),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          _toggleDropdown();

                          if (_diaryEntry != null && _currentUserId != null) {
                            final bool? confirmed =
                                await showDeleteConfirmDialog(context);

                            if (confirmed == true && mounted) {
                              final shouldShowAd = await _isLocalUser();
                              await DatabaseService.instance.diaryRepository
                                  .deleteDiaryByDateAndUserId(
                                      _currentDate, _currentUserId!);

                              await _loadDiaryEntry();

                              if (shouldShowAd) {
                                await AdService
                                    .showDiarySavedInterstitialIfAvailable();
                              }
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icon/trash.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                    Colors.redAccent, BlendMode.srcIn),
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
