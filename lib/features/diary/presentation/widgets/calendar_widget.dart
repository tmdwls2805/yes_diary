import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomCalendar extends StatefulWidget {
  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime? _selectedDay; // 사용자가 선택한 날짜 (초기값: 없음)

  final DateTime _firstMonth = DateTime.utc(2020, 1, 1); // Starting month for the PageView
  final int _initialPageIndex = 100000; // A large number to center the initial month
  
  late DateTime _focusedDay; // Initialize in initState based on page controller
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPageIndex);
    _focusedDay = DateTime(_firstMonth.year, _firstMonth.month + _initialPageIndex, _firstMonth.day);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate cell size to make them square
    final double screenWidth = MediaQuery.of(context).size.width;
    // Subtract horizontal padding (16.0 * 2) and spacing between cells (4.0 * 6)
    // Then divide by 7 for 7 days a week
    final double squareCellSize = (screenWidth - (16.0 * 2) - (4.0 * 6)) / 7;
    final double dayNumberTextHeight = 20.0; // Approximate height for the day number text
    final double cellVerticalMargin = 2.0; // Margin applied to each side of the day square container
    final double totalCellContentHeight = squareCellSize + dayNumberTextHeight + (cellVerticalMargin * 2); // Square height + text height + margins around square

    // Height of the entire GridView item, including the content and internal grid spacing
    // The gridDelegate's mainAxisSpacing will add additional space between rows
    final double gridItemHeight = totalCellContentHeight; // This is the height each grid item *wants* to be

    return Column(
      children: [
        // Custom Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add horizontal padding
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center( // Center the month and icons row
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMMM', 'en_US').format(_focusedDay).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black), // 드롭다운 아이콘
                    const SizedBox(width: 8.0),
                    // TODO: Implement year/month selection dropdown here
                    const Icon(Icons.circle, color: Colors.purple, size: 10), // 작은 동그라미 아이콘
                  ],
                ),
              ),
            ],
          ),
        ),
        // Days of Week Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final days = ['일', '월', '화', '수', '목', '금', '토'];
              return Expanded(
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: index == 0 || index == 6 ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Calendar Grid - Now a PageView for horizontal scrolling
        SizedBox(
          height: (gridItemHeight + 4.0) * 6 - 4.0, // (item height + mainAxisSpacing) * rows - last spacing
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _focusedDay = DateTime(_firstMonth.year, _firstMonth.month + index, _firstMonth.day);
              });
            },
            itemBuilder: (context, pageIndex) {
              final currentMonth = DateTime(_firstMonth.year, _firstMonth.month + pageIndex, _firstMonth.day);
              final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
              final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
              final firstDayOfWeek = firstDayOfMonth.weekday; // Monday is 1, Sunday is 7

              // Adjust for Sunday being the start of the week (if needed)
              // In Dart, weekday 1 is Monday, 7 is Sunday. We want Sunday to be 0 for array indexing.
              final int daysToPrepend = (firstDayOfWeek == 7) ? 0 : firstDayOfWeek;

              // The total number of cells to display in the 6x7 grid is 42.
              // We will render SizedBox.shrink() for cells that don't correspond to a day in the current month.

              return GridView.builder(
                key: ValueKey(currentMonth.month + currentMonth.year * 12), // Unique key for each month's grid
                physics: NeverScrollableScrollPhysics(), // Disable internal scrolling of GridView
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  childAspectRatio: squareCellSize / gridItemHeight, // Width of square / Total height of item
                ),
                itemBuilder: (context, index) {
                  final dayIndex = index - daysToPrepend;
                  final day = DateTime(currentMonth.year, currentMonth.month, dayIndex + 1);

                  // Only render if the day is within the actual range of days to show for this month's view
                  if (index < daysToPrepend || index >= daysToPrepend + daysInMonth) {
                    return SizedBox.shrink(); // Render empty for days outside the current month's displayed range
                  }

                  final bool isToday = day.year == DateTime.now().year &&
                      day.month == DateTime.now().month &&
                      day.day == DateTime.now().day;

                  final bool isSelected = _selectedDay != null &&
                      day.year == _selectedDay!.year &&
                      day.month == _selectedDay!.month &&
                      day.day == _selectedDay!.day;

                  final bool isWeekend = day.weekday == DateTime.sunday || day.weekday == DateTime.saturday;
                  final bool isCurrentMonthDay = day.month == currentMonth.month;

                  BoxDecoration decoration = BoxDecoration(
                    color: const Color(0xFFFDE9E9), // Light pink background
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(4.0),
                  );

                  TextStyle textStyle = TextStyle(color: Colors.black); // Default black text

                  // Apply styling for special days first
                  if (isToday) {
                    decoration = decoration.copyWith(
                      color: Colors.red.withOpacity(0.6),
                    );
                    textStyle = TextStyle(color: Colors.white); // White text for today
                  } else if (isSelected) {
                    decoration = decoration.copyWith(
                      color: Colors.red,
                    );
                    textStyle = TextStyle(color: Colors.white); // White text for selected
                  } else if (isWeekend) {
                    textStyle = TextStyle(color: Colors.red); // Red text for weekends
                  }

                  return GestureDetector(
                    onTap: () {
                      // Only allow selection of days in the current month
                      if (isCurrentMonthDay) {
                        setState(() {
                          _selectedDay = day;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          height: squareCellSize, // Use calculated square size
                          width: squareCellSize, // Ensure container is square
                          margin: EdgeInsets.all(cellVerticalMargin), // Apply consistent margin
                          decoration: decoration,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Removed the camera icon placeholder
                            ],
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: textStyle,
                        ),
                      ],
                    ),
                  );
                },
                itemCount: 42, // Always display 6 weeks (6 * 7 = 42 days)
              );
            },
            itemCount: 200000, // A large number for infinite scrolling effect
          ),
        ),
      ],
    );
  }
}
