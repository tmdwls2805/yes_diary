import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'calendar_day_cell.dart';
import '../../core/di/injection_container.dart';
import '../../presentation/views/diary_write_view.dart';
import '../../presentation/views/diary_view_view.dart';
import '../../presentation/viewmodels/user_viewmodel.dart';
import '../../presentation/viewmodels/calendar_viewmodel.dart';

class CalendarGrid extends ConsumerWidget {
  final DateTime currentMonth;
  final DateTime firstMonth;
  final double squareCellSize;
  final double textSizedBoxHeight;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double gridItemHeight;
  final DateTime? initialDate;
  final Function(DateTime) onLoadDiariesForMonth;

  const CalendarGrid({
    Key? key,
    required this.currentMonth,
    required this.firstMonth,
    required this.squareCellSize,
    required this.textSizedBoxHeight,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.gridItemHeight,
    this.initialDate,
    required this.onLoadDiariesForMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarViewModelProvider);
    final userState = ref.watch(userViewModelProvider);

    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
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
          final prevMonthLastDay = DateTime(currentMonth.year, currentMonth.month, 0);
          day = DateTime(prevMonthLastDay.year, prevMonthLastDay.month,
              prevMonthLastDay.day - (daysToPrepend - 1 - index));
          isCurrentMonthDay = false;
          isPreviousMonthDay = true;
        } else {
          day = DateTime(currentMonth.year, currentMonth.month, index - daysToPrepend + 1);
          isCurrentMonthDay = true;
        }

        final DateTime now = DateTime.now();
        final bool isToday = day.year == now.year && 
            day.month == now.month && 
            day.day == now.day;

        final bool isSelected = calendarState.selectedDay != null &&
            day.year == calendarState.selectedDay!.year &&
            day.month == calendarState.selectedDay!.month &&
            day.day == calendarState.selectedDay!.day;

        final bool isWeekend =
            day.weekday == DateTime.sunday || day.weekday == DateTime.saturday;
        
        final String? emotion = ref.watch(emotionForDateProvider(day));

        return CalendarDayCell(
          day: day,
          isToday: isToday,
          isSelected: isSelected,
          isWeekend: isWeekend,
          isCurrentMonthDay: isCurrentMonthDay,
          isPreviousMonthDay: isPreviousMonthDay,
          squareCellSize: squareCellSize,
          textSizedBoxHeight: textSizedBoxHeight,
          onTap: () => _handleDayTap(context, ref, day, userState, calendarState),
          emotion: emotion,
        );
      },
      itemCount: fixedTotalCells,
    );
  }

  Future<void> _handleDayTap(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    UserState userState,
    CalendarState calendarState,
  ) async {
    ref.read(calendarViewModelProvider.notifier).setSelectedDay(day);

    final DateTime today = DateTime.now();
    final DateTime normalizedToday = DateTime(today.year, today.month, today.day);
    final DateTime normalizedSelectedDay = DateTime(day.year, day.month, day.day);

    // Check if selected date is before first clickable month
    final DateTime firstClickableMonthStart = DateTime(firstMonth.year, firstMonth.month, 1);
    if (normalizedSelectedDay.isBefore(firstClickableMonthStart)) {
      Fluttertoast.showToast(
        msg: "가입일 이전의 날짜는 선택할 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // Check if selected date is in the future
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
      return;
    }

    if (userState.user?.userId != null) {
      final diaryViewModel = ref.read(diaryViewModelProvider.notifier);
      final existingDiary = diaryViewModel.getDiaryForDate(day);
      
      if (existingDiary != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryViewView(selectedDate: day, createdAt: initialDate),
          ),
        ).then((_) => onLoadDiariesForMonth(calendarState.focusedDay));
      } else {
        if (normalizedSelectedDay.isAtSameMomentAs(normalizedToday)) {
          // Today's date with no diary - go to write screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryWriteView(selectedDate: day),
            ),
          ).then((_) => onLoadDiariesForMonth(calendarState.focusedDay));
        } else {
          // Past date with no diary - go to integrated screen (prompt display)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryViewView(selectedDate: day, createdAt: initialDate),
            ),
          ).then((_) => onLoadDiariesForMonth(calendarState.focusedDay));
        }
      }
    } else {
      // No userId - go to write screen by default
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryWriteView(selectedDate: day),
        ),
      ).then((_) => onLoadDiariesForMonth(calendarState.focusedDay));
    }
  }
}