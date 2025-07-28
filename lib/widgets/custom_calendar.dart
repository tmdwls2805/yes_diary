import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/calendar/calendar_header.dart';
import '../widgets/calendar/month_dropdown_overlay.dart';
import '../widgets/calendar/weekdays_header.dart';
import '../widgets/calendar/calendar_grid.dart';
import '../core/di/injection_container.dart';

class CustomCalendar extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const CustomCalendar({Key? key, this.initialDate}) : super(key: key);

  @override
  ConsumerState<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends ConsumerState<CustomCalendar> {
  late final DateTime _firstMonth;
  late PageController _pageController;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final DateTime effectiveDate = widget.initialDate ?? now;

    _firstMonth = DateTime.utc(effectiveDate.year, effectiveDate.month, 1);
    
    // Set initial calendar state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarViewModel = ref.read(calendarViewModelProvider.notifier);
      calendarViewModel.setFocusedDay(DateTime(effectiveDate.year, effectiveDate.month, 1));
      calendarViewModel.setSelectedDay(now);
      
      // Load initial diaries
      _loadDiariesForMonth(DateTime(effectiveDate.year, effectiveDate.month, 1));
    });
    
    int initialPage = now.month - _firstMonth.month + (now.year - _firstMonth.year) * 12;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    final calendarState = ref.read(calendarViewModelProvider);
    if (calendarState.isDropdownActive) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = MonthDropdownOverlay.createOverlay(
      context: context,
      ref: ref,
      layerLink: _layerLink,
      firstMonth: _firstMonth,
      pageController: _pageController,
      onRemoveOverlay: _removeOverlay,
      onLoadDiariesForMonth: _loadDiariesForMonth,
    );
    Overlay.of(context).insert(_overlayEntry!);
    ref.read(calendarViewModelProvider.notifier).openDropdown();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    ref.read(calendarViewModelProvider.notifier).closeDropdown();
  }

  Future<void> _loadDiariesForMonth(DateTime month) async {
    final userState = ref.read(userViewModelProvider);
    if (userState.user?.userId == null) {
      print('CustomCalendar: User ID is null, cannot load diaries.');
      return;
    }

    final DateTime startOfRange = DateTime(month.year, month.month - 1, 1);
    final DateTime endOfRange = DateTime(month.year, month.month + 2, 0, 23, 59, 59);

    await ref.read(diaryViewModelProvider.notifier).loadDiariesForRange(
      startOfRange, 
      endOfRange, 
      userState.user!.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarViewModelProvider);
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double crossAxisSpacing = 4.0;
    final double mainAxisSpacing = 2.0;

    final double squareCellSize =
        (screenWidth - (16.0 * 2) - (crossAxisSpacing * 6)) / 7;
    final double textSizedBoxHeight = 24.0;
    final double gridItemHeight = squareCellSize + textSizedBoxHeight + 4.0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        final DateTime now = DateTime.now();
        final DateTime currentMonth = DateTime(now.year, now.month, 1);
        final DateTime focusedMonth = DateTime(calendarState.focusedDay.year, calendarState.focusedDay.month, 1);

        if (focusedMonth.year != currentMonth.year || focusedMonth.month != currentMonth.month) {
          final int targetPageIndex = (now.year - _firstMonth.year) * 12 + (now.month - _firstMonth.month);
          _pageController.jumpToPage(targetPageIndex);
          ref.read(calendarViewModelProvider.notifier).setFocusedDay(currentMonth);
        } else {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            print('No more routes to pop. Consider exiting app or showing a message.');
          }
        }
      },
      child: Column(
        children: [
          CalendarHeader(
            layerLink: _layerLink,
            onToggleDropdown: _toggleDropdown,
          ),
          const WeekdaysHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                final newFocusedDay = DateTime(
                    _firstMonth.year, _firstMonth.month + index, _firstMonth.day);
                ref.read(calendarViewModelProvider.notifier).setFocusedDay(newFocusedDay);
                _loadDiariesForMonth(newFocusedDay);
              },
              itemBuilder: (context, pageIndex) {
                final currentMonth = DateTime(
                    _firstMonth.year, _firstMonth.month + pageIndex, _firstMonth.day);

                return CalendarGrid(
                  currentMonth: currentMonth,
                  firstMonth: _firstMonth,
                  squareCellSize: squareCellSize,
                  textSizedBoxHeight: textSizedBoxHeight,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  gridItemHeight: gridItemHeight,
                  initialDate: widget.initialDate,
                  onLoadDiariesForMonth: _loadDiariesForMonth,
                );
              },
              itemCount: 200000,
            ),
          ),
        ],
      ),
    );
  }
}