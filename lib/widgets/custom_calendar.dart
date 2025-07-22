import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/screens/diary_write_screen.dart';
import 'package:yes_diary/screens/diary_prompt_screen.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/screens/diary_view_screen.dart';
import 'package:yes_diary/models/diary_entry.dart'; // DiaryEntry import 추가
import 'package:fluttertoast/fluttertoast.dart';
import 'package:yes_diary/core/constants/app_image.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final String? userId;

  const CustomCalendar({Key? key, this.initialDate, this.userId}) : super(key: key);

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime? _selectedDay;
  late final DateTime _firstMonth;

  late DateTime _focusedDay;
  late PageController _pageController;

  bool _isDropdownActive = false;

  Map<DateTime, String> _diariesEmotionMap = {}; // 날짜별 감정 저장 맵

  // 감정 이름과 SVG 경로 매핑 (AppImages에서 가져옴)
  final Map<String, String> _emotionSvgPaths = AppImages.emotionFaceSvgPaths;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();

    final DateTime effectiveDate = widget.initialDate ?? now;

    _firstMonth = DateTime.utc(effectiveDate.year, effectiveDate.month, 1);
    
    _focusedDay = DateTime(effectiveDate.year, effectiveDate.month, 1);
    
    int initialPage = DateTime.now().month - _firstMonth.month + (DateTime.now().year - _firstMonth.year) * 12;
    _pageController = PageController(initialPage: initialPage);

    _selectedDay = now;

    _loadDiariesForMonth(_focusedDay); // 초기 월의 일기 로드
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 해당 월의 일기 데이터를 로드하는 함수
  Future<void> _loadDiariesForMonth(DateTime month) async {
    if (widget.userId == null) {
      print('CustomCalendar: User ID is null, cannot load diaries.');
      return;
    }

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      final List<DiaryEntry> diaries = await DatabaseService.instance.diaryRepository.getDiariesByDateRangeAndUserId(
        startOfMonth,
        endOfMonth,
        widget.userId!,
      );
      setState(() {
        _diariesEmotionMap.clear(); // 이전 데이터 클리어
        for (var entry in diaries) {
          // 날짜만 포함하도록 정규화 (시간 무시)
          _diariesEmotionMap[DateTime(entry.date.year, entry.date.month, entry.date.day)] = entry.emotion;
        }
        print('CustomCalendar: Loaded diaries for ${DateFormat('yyyy-MM').format(month)}. Map size: ${_diariesEmotionMap.length}');
        _diariesEmotionMap.forEach((date, emotion) {
          print('  Date: ${DateFormat('yyyy-MM-dd').format(date)}, Emotion: $emotion');
        });
      });
    } catch (e) {
      print('Failed to load diaries for month: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double crossAxisSpacing = 4.0;
    final double mainAxisSpacing = 2.0;

    final double squareCellSize =
        (screenWidth - (16.0 * 2) - (crossAxisSpacing * 6)) / 7;

    final double textSizedBoxHeight = 24.0;
    final double gridItemHeight = squareCellSize + textSizedBoxHeight + 4.0;

    final double calendarGridHeight =
        (gridItemHeight + mainAxisSpacing) * 6 - mainAxisSpacing;

    return PopScope(
      canPop: false, // 기본 뒤로가기 동작 방지
      onPopInvoked: (didPop) {
        // didPop이 true이면 시스템 뒤로가기 동작이 이미 발생했으므로 추가 처리 불필요
        if (didPop) return;

        final DateTime now = DateTime.now();
        final DateTime currentMonth = DateTime(now.year, now.month, 1);
        final DateTime focusedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);

        if (focusedMonth.year != currentMonth.year || focusedMonth.month != currentMonth.month) {
          // 현재 달이 아닌 경우, 현재 달로 이동
          final int targetPageIndex = (now.year - _firstMonth.year) * 12 + (now.month - _firstMonth.month);
          _pageController.jumpToPage(targetPageIndex);
          setState(() {
            _focusedDay = currentMonth;
          });
        } else {
          // 현재 달인 경우, 앱 종료 방지를 위해 Navigator.pop 호출
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            // 이 경우가 발생하면 앱이 종료될 수 있음 (예: 스택의 마지막 라우트)
            // 필요에 따라 여기에 앱 종료 로직 추가 또는 사용자에게 알림
            print('No more routes to pop. Consider exiting app or showing a message.');
          }
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 44.0, bottom: 12.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDropdownActive = !_isDropdownActive; 
                    });
                    print('Year tapped! Dropdown state: $_isDropdownActive');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy', 'en_US')
                            .format(_focusedDay),
                        style: const TextStyle(
                          fontSize: 36.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      SvgPicture.asset(
                        _isDropdownActive
                            ? 'assets/icon/calendar_dropdown_active.svg'
                            : 'assets/icon/calendar_dropdown_inactive.svg',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 0.0),
                GestureDetector(
                  onTap: () {
                    print('Month tapped!');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM', 'en_US')
                            .format(_focusedDay)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final days = ['일', '월', '화', '수', '목', '금', '토'];
                return Expanded(
                  child: Center(
                    child: Text(
                      days[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: calendarGridHeight,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _focusedDay = DateTime(
                      _firstMonth.year, _firstMonth.month + index, _firstMonth.day);
                });
                _loadDiariesForMonth(_focusedDay); // 월 변경 시 일기 로드
              },
              itemBuilder: (context, pageIndex) {
                final currentMonth = DateTime(
                    _firstMonth.year, _firstMonth.month + pageIndex, _firstMonth.day);
                final firstDayOfMonth =
                    DateTime(currentMonth.year, currentMonth.month, 1);
                final daysInMonth =
                    DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
                final int firstDayOfWeek = firstDayOfMonth.weekday;

                final int daysToPrepend = (firstDayOfWeek == 7) ? 0 : firstDayOfWeek;

                final int fixedTotalCells = 42;

                return GridView.builder(
                  key: ValueKey(currentMonth.month + currentMonth.year * 12),
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: mainAxisSpacing,
                    crossAxisSpacing: crossAxisSpacing,
                    childAspectRatio: squareCellSize / gridItemHeight,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= daysToPrepend + daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    if (index >= fixedTotalCells) return const SizedBox.shrink();

                    DateTime day;
                    bool isCurrentMonthDay;
                    bool isPreviousMonthDay = false;

                    if (index < daysToPrepend) {
                      final prevMonthLastDay =
                          DateTime(currentMonth.year, currentMonth.month, 0);
                      day = DateTime(prevMonthLastDay.year, prevMonthLastDay.month,
                          prevMonthLastDay.day - (daysToPrepend - 1 - index));
                      isCurrentMonthDay = false;
                      isPreviousMonthDay = true;
                    } else {
                      day = DateTime(
                          currentMonth.year, currentMonth.month, index - daysToPrepend + 1);
                      isCurrentMonthDay = true;
                    }

                    final bool isToday = day.year == DateTime.now().year &&
                        day.month == DateTime.now().month &&
                        day.day == DateTime.now().day;

                    final bool isSelected = _selectedDay != null &&
                        day.year == _selectedDay!.year &&
                        day.month == _selectedDay!.month &&
                        day.day == _selectedDay!.day;

                    final bool isWeekend =
                        day.weekday == DateTime.sunday || day.weekday == DateTime.saturday;
                    
                    // 현재 날짜를 정규화하여 맵에서 찾기
                    final DateTime normalizedDay = DateTime(day.year, day.month, day.day);
                    final String? emotion = _diariesEmotionMap[normalizedDay];

                    return _buildDayCell(
                      day: day,
                      isToday: isToday,
                      isSelected: isSelected,
                      isWeekend: isWeekend,
                      isCurrentMonthDay: isCurrentMonthDay,
                      isPreviousMonthDay: isPreviousMonthDay,
                      squareCellSize: squareCellSize,
                      textSizedBoxHeight: textSizedBoxHeight,
                      onTap: isCurrentMonthDay
                          ? () async { // 비동기 함수로 변경
                              setState(() {
                                _selectedDay = day;
                              });

                              final DateTime today = DateTime.now();
                              final DateTime normalizedToday = DateTime(today.year, today.month, today.day);
                              final DateTime normalizedSelectedDay = DateTime(day.year, day.month, day.day);

                              if (normalizedSelectedDay.isAfter(normalizedToday)) {
                                Fluttertoast.showToast(
                                  msg: "아직 일기를 작성할 수 없습니다.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.black,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                                print('미래 날짜 선택됨: ${day.toIso8601String()}');
                                return; // 미래 날짜는 일기 작성/조회로 이동하지 않음
                              }

                              if (widget.userId != null) {
                                final hasDiary = await DatabaseService.instance.diaryRepository.hasDiaryOnDateAndUserId(day, widget.userId!);
                                
                                if (hasDiary) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DiaryViewScreen(selectedDate: day, createdAt: widget.initialDate),
                                    ),
                                  ).then((_) => _loadDiariesForMonth(_focusedDay)); // 돌아왔을 때 데이터 새로고침
                                  print('일기 있음: ${day.toIso8601String()}');
                                } else {
                                  // 일기가 없는 경우 오늘 날짜인지 확인
                                  if (normalizedSelectedDay.isAtSameMomentAs(normalizedToday)) {
                                    // 오늘 날짜이면서 일기가 없으면 작성 화면으로
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DiaryWriteScreen(selectedDate: day),
                                      ),
                                    ).then((_) => _loadDiariesForMonth(_focusedDay));
                                    print('오늘 날짜 일기 없음 - 작성 화면으로: ${day.toIso8601String()}');
                                  } else {
                                    // 오늘이 아닌 날짜이면서 일기가 없으면 유도 화면으로
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DiaryPromptScreen(selectedDate: day, createdAt: widget.initialDate),
                                      ),
                                    ).then((_) => _loadDiariesForMonth(_focusedDay));
                                    print('과거 날짜 일기 없음 - 유도 화면으로: ${day.toIso8601String()}');
                                  }
                                }
                              } else {
                                  // userId가 없는 경우 기본적으로 작성 화면으로
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DiaryWriteScreen(selectedDate: day),
                                    ),
                                  ).then((_) => _loadDiariesForMonth(_focusedDay)); // 돌아왔을 때 데이터 새로고침
                                  print('userId 없음. 일기 작성 화면으로 이동.');
                              }
                            }
                          : null,
                      emotion: emotion, // 감정 정보 전달
                    );
                  },
                  itemCount: fixedTotalCells,
                );
              },
              itemCount: 200000,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required bool isToday,
    required bool isSelected,
    required bool isWeekend,
    required bool isCurrentMonthDay,
    required bool isPreviousMonthDay,
    required double squareCellSize,
    required double textSizedBoxHeight,
    required VoidCallback? onTap,
    String? emotion,
  }) {
    Color backgroundColor;
    Color textColor;
    Widget? emotionSvgWidget; 
    Widget? todayIconWidget; // 오늘 날짜 이모티콘 위젯

    // 1. 배경색 및 글자색 결정
    if (isCurrentMonthDay) {
      if (isToday) {
        backgroundColor = const Color(0xFFFF4646);
        textColor = const Color(0xFFFF4646);
      } else {
        backgroundColor = const Color(0xFF4C3030);
        textColor = const Color(0xFFC5C5C5);
      }
    } else if (isPreviousMonthDay) {
      backgroundColor = const Color(0xFF363636);
      textColor = const Color(0xFF363636);
    } else {
      backgroundColor = Colors.transparent;
      textColor = Colors.transparent;
    }

    // 2. 감정 SVG 위젯 설정
    if (emotion != null && isCurrentMonthDay) {
      final svgPath = _emotionSvgPaths[emotion];
      if (svgPath != null) {
        emotionSvgWidget = SvgPicture.asset(
          svgPath,
          width: squareCellSize,
          height: squareCellSize,
          fit: BoxFit.contain,
        );
        // 감정 SVG가 있으면 배경색을 투명으로, 글자색을 흰색으로
        backgroundColor = Colors.transparent;
      }
    }

    // 3. 오늘 날짜 작성 이모티콘 위젯 설정
    // 일기 감정 이모티콘이 없는 경우에만 표시
    if (isToday && isCurrentMonthDay && emotion == null) {
      todayIconWidget = SvgPicture.asset(
        'assets/icon/write_diary.svg',
        width: squareCellSize * 0.8, 
        height: squareCellSize * 0.8,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }

    BoxDecoration decoration = BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(4.0),
    );

    TextStyle textStyle = TextStyle(color: textColor, fontSize: 14.0);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Column(
          children: [
            Container(
              height: squareCellSize,
              width: squareCellSize,
              decoration: decoration,
              child: Stack( 
                alignment: Alignment.center,
                children: [
                  // 감정 SVG (있다면) 및 오늘 아이콘 (있다면) 표시
                  if (emotionSvgWidget != null) emotionSvgWidget!,
                  if (todayIconWidget != null) todayIconWidget!,
                ],
              ),
            ),
            SizedBox(
              height: textSizedBoxHeight,
              child: Text(
                '${day.day}',
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
