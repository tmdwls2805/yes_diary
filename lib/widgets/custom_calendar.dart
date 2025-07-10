import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomCalendar extends StatefulWidget {
  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime? _selectedDay;
  final DateTime _firstMonth = DateTime.utc(2020, 1, 1); // 캘린더 시작 월 (변경하지 않음)

  late DateTime _focusedDay;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now(); // 현재 날짜와 시간
    
    // 💡 _firstMonth (2020년 1월)부터 현재 월까지의 월 차이를 정확히 계산
    final int monthsDifference = (now.year - _firstMonth.year) * 12 + (now.month - _firstMonth.month);
    
    // 💡 PageController의 초기 페이지를 계산된 월 차이로 설정하여 현재 달이 보이도록 함
    _pageController = PageController(initialPage: monthsDifference);
    
    // 💡 캘린더의 포커스된 달을 현재 달의 1일로 설정
    _focusedDay = DateTime(now.year, now.month, 1); 
    
    // 선택된 날짜는 오늘 날짜로 유지
    _selectedDay = now; 
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // 💡 crossAxisSpacing과 mainAxisSpacing을 8.0으로 늘림
    final double crossAxisSpacing = 8.0;
    final double mainAxisSpacing = 8.0; 

    // 💡 squareCellSize 계산식 업데이트 (crossAxisSpacing 변경 반영)
    // (화면 너비 - 좌우 패딩 16*2 - 셀 간 간격 (8.0*6) ) / 7일
    final double squareCellSize = (screenWidth - (16.0 * 2) - (crossAxisSpacing * 6)) / 7;
    
    final double textSizedBoxHeight = 18.0;
    final double gridItemHeight = squareCellSize + textSizedBoxHeight + 4.0;

    // 💡 calendarGridHeight 계산식 업데이트 (mainAxisSpacing 변경 반영)
    final double calendarGridHeight = (gridItemHeight + mainAxisSpacing) * 6 - mainAxisSpacing;

    return Column(
      children: [
        // Custom Header (Month and Year)
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 24.0, left: 16.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM', 'en_US').format(_focusedDay).toUpperCase(),
                style: const TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
              const SizedBox(width: 8.0),
            ],
          ),
        ),
        // Days of Week Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Calendar Grid - PageView for horizontal scrolling
        SizedBox(
          height: calendarGridHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                // _firstMonth를 기준으로 페이지 인덱스에 해당하는 날짜로 _focusedDay 업데이트
                _focusedDay = DateTime(_firstMonth.year, _firstMonth.month + index, _firstMonth.day);
              });
            },
            itemBuilder: (context, pageIndex) {
              // _firstMonth를 기준으로 현재 페이지에 해당하는 월 계산
              final currentMonth = DateTime(_firstMonth.year, _firstMonth.month + pageIndex, _firstMonth.day);
              final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
              final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
              final int firstDayOfWeek = firstDayOfMonth.weekday; // Monday is 1, Sunday is 7

              // GridView에 표시될 첫 날짜의 요일을 일요일(0) 기준으로 맞추기 위한 공백 계산
              final int daysToPrepend = (firstDayOfWeek == 7) ? 0 : firstDayOfWeek;

              // 캘린더 그리드는 항상 6주(42일) 기준으로 그림
              final int fixedTotalCells = 42; 

              return GridView.builder(
                key: ValueKey(currentMonth.month + currentMonth.year * 12),
                physics: const NeverScrollableScrollPhysics(), // GridView 내부 스크롤 비활성화
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // GridView의 좌우 패딩
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 주 7일
                  mainAxisSpacing: mainAxisSpacing, // 💡 세로 셀 간격 적용
                  crossAxisSpacing: crossAxisSpacing, // 💡 가로 셀 간격 적용
                  childAspectRatio: squareCellSize / gridItemHeight, // 셀의 가로세로 비율
                ),
                itemBuilder: (context, index) {
                  // 고정된 42개 셀을 넘어가면 빈 위젯 반환
                  if (index >= fixedTotalCells) return const SizedBox.shrink();

                  DateTime day;
                  bool isCurrentMonthDay;
                  bool isPreviousMonthDay = false;
                  bool isNextMonthDay = false;     

                  // GridView 인덱스를 실제 날짜에 매핑
                  if (index < daysToPrepend) {
                    // 이전 달의 날짜 계산
                    final prevMonthLastDay = DateTime(currentMonth.year, currentMonth.month, 0);
                    day = DateTime(prevMonthLastDay.year, prevMonthLastDay.month, prevMonthLastDay.day - (daysToPrepend - 1 - index));
                    isCurrentMonthDay = false;
                    isPreviousMonthDay = true;
                  } else if (index >= daysToPrepend + daysInMonth) {
                    // 다음 달의 날짜 계산
                    final nextMonthFirstDay = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                    day = DateTime(nextMonthFirstDay.year, nextMonthFirstDay.month, (index - (daysToPrepend + daysInMonth)) + 1);
                    isCurrentMonthDay = false;
                    isNextMonthDay = true;
                  } else {
                    // 현재 달의 날짜 계산
                    day = DateTime(currentMonth.year, currentMonth.month, index - daysToPrepend + 1);
                    isCurrentMonthDay = true;
                  }

                  // 오늘 날짜인지, 선택된 날짜인지, 주말인지 판단
                  final bool isToday = day.year == DateTime.now().year &&
                      day.month == DateTime.now().month &&
                      day.day == DateTime.now().day;

                  final bool isSelected = _selectedDay != null &&
                      day.year == _selectedDay!.year &&
                      day.month == _selectedDay!.month &&
                      day.day == _selectedDay!.day;

                  final bool isWeekend = day.weekday == DateTime.sunday || day.weekday == DateTime.saturday;

                  // _buildDayCell 위젯을 사용하여 각 날짜 셀 렌더링
                  return _buildDayCell(
                    day: day,
                    isToday: isToday,
                    isSelected: isSelected,
                    isWeekend: isWeekend,
                    isCurrentMonthDay: isCurrentMonthDay,
                    isPreviousMonthDay: isPreviousMonthDay,
                    isNextMonthDay: isNextMonthDay,
                    squareCellSize: squareCellSize,
                    textSizedBoxHeight: textSizedBoxHeight,
                    onTap: () {
                      if (isCurrentMonthDay) { // 현재 달의 날짜만 선택 가능하도록
                        setState(() {
                          _selectedDay = day;
                        });
                      }
                      // 이전/다음 달 날짜는 탭해도 아무 동작 없음 (이전 요청에 따라)
                    },
                  );
                },
                itemCount: fixedTotalCells, // 고정된 셀 개수 (42)
              );
            },
            itemCount: 200000, // 무한 스크롤 효과를 위한 PageView 아이템 수
          ),
        ),
      ],
    );
  }

  // 각 날짜 셀을 빌드하는 헬퍼 위젯
  Widget _buildDayCell({
    required DateTime day,
    required bool isToday,
    required bool isSelected,
    required bool isWeekend,
    required bool isCurrentMonthDay,
    required bool isPreviousMonthDay,
    required bool isNextMonthDay,
    required double squareCellSize,
    required double textSizedBoxHeight,
    required VoidCallback onTap,
  }) {
    Color backgroundColor;
    Color textColor;

    if (isCurrentMonthDay) {
      // 현재 달의 날짜: 빨강 네모 (FF4646), 회색 숫자 (C5C5C5)
      backgroundColor = const Color(0xFFFF4646);
      textColor = const Color(0xFFC5C5C5);
    } else if (isPreviousMonthDay) {
      // 전달 날짜: 회색 네모 (363636), 회색 숫자 (363636)
      backgroundColor = const Color(0xFF363636);
      textColor = const Color(0xFF363636);
    } else if (isNextMonthDay) {
      // 다음 달 날짜: 검정색 배경, 검정색 숫자 (안보이게)
      backgroundColor = Colors.black;
      textColor = Colors.black;
    } else {
      // 예상치 못한 경우 (백업)
      backgroundColor = Colors.black;
      textColor = Colors.black;
    }

    BoxDecoration decoration = BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(4.0),
    );

    TextStyle textStyle = TextStyle(color: textColor);

    // "오늘" 날짜와 "선택된" 날짜에 대한 특별한 스타일은 현재 요청에서 통일되었으므로 적용하지 않음
    
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 오늘 날짜 중 4일에 일기 아이콘 표시 (예시)
                  if (isCurrentMonthDay && day.day == 4 && day.month == DateTime.now().month && day.year == DateTime.now().year)
                    const Icon(Icons.edit, color: Colors.white, size: 20),
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
