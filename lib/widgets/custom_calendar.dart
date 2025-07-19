import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/screens/diary_write_screen.dart';
import 'package:yes_diary/services/database_service.dart'; // DatabaseService import
import 'package:yes_diary/screens/diary_view_screen.dart'; // DiaryViewScreen import

class CustomCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final String? userId; // userId 필드 추가

  const CustomCalendar({Key? key, this.initialDate, this.userId}) : super(key: key);

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime? _selectedDay;
  late final DateTime _firstMonth;

  late DateTime _focusedDay;
  late PageController _pageController;

  // 💡 드롭다운 아이콘 상태를 위한 변수 추가
  bool _isDropdownActive = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();

    // initialDate가 제공되면 해당 날짜로, 아니면 현재 날짜로 설정
    final DateTime effectiveDate = widget.initialDate ?? now;

    // PageView의 시작점을 effectiveDate의 월로 설정
    _firstMonth = DateTime.utc(effectiveDate.year, effectiveDate.month, 1);
    
    // _focusedDay도 effectiveDate의 월로 설정
    _focusedDay = DateTime(effectiveDate.year, effectiveDate.month, 1);
    
    // 현재 월이 첫 페이지가 되도록 초기 페이지 계산
    int initialPage = DateTime.now().month - _firstMonth.month + (DateTime.now().year - _firstMonth.year) * 12;
    _pageController = PageController(initialPage: initialPage);

    _selectedDay = now; // 항상 오늘 날짜가 선택된 상태로 시작
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double crossAxisSpacing = 4.0;
    // 💡 세로 셀 간격을 2.0으로 조정하여 요일 헤더와 캘린더 그리드를 더 가깝게 붙입니다.
    final double mainAxisSpacing = 2.0;

    final double squareCellSize =
        (screenWidth - (16.0 * 2) - (crossAxisSpacing * 6)) / 7;

    // 💡 날짜 바로 밑 간격을 늘리기 위해 textSizedBoxHeight를 24.0으로 조정합니다.
    final double textSizedBoxHeight = 24.0;
    final double gridItemHeight = squareCellSize + textSizedBoxHeight + 4.0;

    final double calendarGridHeight =
        (gridItemHeight + mainAxisSpacing) * 6 - mainAxisSpacing;

    return Column(
      children: [
        // Custom Header (Year and Month)
        Padding(
          // 💡 상단 패딩을 44.0으로 조정하여 년도 부분을 상단에서 44px 떨어뜨립니다.
          // 💡 하단 패딩을 12.0으로 조정하여 캘린더 그리드에 더 가깝게 붙입니다.
          padding: const EdgeInsets.only(
              top: 44.0, bottom: 12.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  // 년도 옆 드롭다운 아이콘을 누를 때마다 즉시 상태 변경
                  setState(() {
                    _isDropdownActive = !_isDropdownActive; // 아이콘 상태 토글
                  });
                  // TODO: Implement year picker functionality here if needed
                  print('Year tapped! Dropdown state: $_isDropdownActive');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy', 'en_US')
                          .format(_focusedDay), // Display Year
                      style: const TextStyle(
                        fontSize: 36.0, // Year font size set to 36.0px
                        color: Colors.white,
                      ),
                    ),
                    // 💡 년도 텍스트와 드롭다운 아이콘 사이에 8.0px 간격 추가
                    const SizedBox(width: 8.0),
                    // 💡 드롭다운 아이콘을 SVG로 교체하고 상태에 따라 변경
                    SvgPicture.asset(
                      _isDropdownActive
                          ? 'assets/icon/calendar_dropdown_active.svg'
                          : 'assets/icon/calendar_dropdown_inactive.svg',
                      width: 16, // 💡 아이콘 크기 16.0px로 조정
                      height: 16, // 💡 아이콘 크기 16.0px로 조정
                    ),
                  ],
                ),
              ),
              // 💡 년도와 달 사이의 간격을 0.0으로 조정하여 더 가깝게 붙입니다.
              const SizedBox(height: 0.0),
              GestureDetector(
                onTap: () {
                  // TODO: Implement month picker functionality here if needed
                  print('Month tapped!');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM', 'en_US')
                          .format(_focusedDay)
                          .toUpperCase(), // Display Month
                      style: const TextStyle(
                        fontSize: 16.0, // Month font size set to 16.0px
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Removed the Icon here as requested
                  ],
                ),
              ),
            ],
          ),
        ),
        // Days of Week Header
        Container(
          // 요일 헤더의 세로 패딩은 0.0으로 유지하여 캘린더 그리드에 최대한 가깝게 붙입니다.
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
                      fontSize: 14.0, // 요일 글자 크기를 14.0px로 유지
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Calendar Grid - PageView for horizontal scrolling
        SizedBox(
          height: calendarGridHeight, // 6주가 보이도록 계산된 고정 높이
          child: PageView.builder(
            controller: _pageController,
            // 스크롤 물리학을 BouncingScrollPhysics로 설정하여 부드러운 스크롤 효과
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _focusedDay = DateTime(
                    _firstMonth.year, _firstMonth.month + index, _firstMonth.day);
              });
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
                physics: const NeverScrollableScrollPhysics(), // GridView 자체 스크롤 방지
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: squareCellSize / gridItemHeight,
                ),
                itemBuilder: (context, index) {
                  // 다음 달 날짜는 아예 렌더링하지 않습니다.
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

                            // userId가 유효한 경우에만 일기 존재 여부 확인
                            if (widget.userId != null) {
                              final hasDiary = await DatabaseService.instance.diaryRepository.hasDiaryOnDateAndUserId(day, widget.userId!);
                              
                              if (hasDiary) {
                                // 일기 조회 화면으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiaryViewScreen(selectedDate: day),
                                  ),
                                );
                                print('일기 있음: ${day.toIso8601String()}');
                              } else {
                                // 새 일기 작성 화면으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiaryWriteScreen(selectedDate: day),
                                  ),
                                );
                                print('일기 없음: ${day.toIso8601String()}');
                              }
                            } else {
                                // userId가 없으면 기본 동작 (일기 작성 화면으로 이동)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DiaryWriteScreen(selectedDate: day),
                                  ),
                                );
                                print('userId 없음. 일기 작성 화면으로 이동.');
                            }
                          }
                        : null,
                  );
                },
                itemCount: fixedTotalCells,
              );
            },
            itemCount: 200000,
          ),
        ),

        // 캘린더 그리드와 버튼 사이에 Spacer를 추가하여 버튼을 하단으로 밀어냅니다.
        const Spacer(),
      ],
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
    required VoidCallback? onTap, // onTap은 null일 수 있음
  }) {
    Color backgroundColor;
    Color textColor;

    if (isCurrentMonthDay) {
      if (isToday) {
        // 오늘 날짜: 빨간색 배경, 빨간색 글자 (FF4646)
        backgroundColor = const Color(0xFFFF4646);
        textColor = const Color(0xFFFF4646);
      } else {
        // 💡 현재 달의 다른 날짜: 빨강 네모 (4C3030), 글자색 C5C5C5
        backgroundColor = const Color(0xFF4C3030);
        textColor = const Color(0xFFC5C5C5);
      }
    } else if (isPreviousMonthDay) {
      // 이전 달 날짜: 배경색과 글자색을 363636으로 설정하여 숨깁니다.
      backgroundColor = const Color(0xFF363636);
      textColor = const Color(0xFF363636);
    } else {
      // 이 경우는 발생하지 않아야 하지만, 혹시 모를 상황을 대비
      backgroundColor = Colors.transparent;
      textColor = Colors.transparent;
    }

    BoxDecoration decoration = BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(4.0),
    );

    // 날짜 글자 크기를 14.0px로 유지
    TextStyle textStyle = TextStyle(color: textColor, fontSize: 14.0);

    return GestureDetector(
      onTap: onTap, // 전달받은 onTap을 그대로 사용
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Column(
          children: [
            Container(
              height: squareCellSize,
              width: squareCellSize,
              decoration: decoration,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday && isCurrentMonthDay)
                    SvgPicture.asset(
                      'assets/icon/write_diary.svg',
                      width: 36,
                      height: 36,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
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
