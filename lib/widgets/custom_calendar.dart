import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/screens/diary_write_screen.dart';
import 'package:yes_diary/screens/diary_view_screen.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:yes_diary/core/constants/app_image.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'package:yes_diary/providers/diary_provider.dart';
import 'package:yes_diary/providers/calendar_provider.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator

class CustomCalendar extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const CustomCalendar({Key? key, this.initialDate}) : super(key: key);

  @override
  ConsumerState<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends ConsumerState<CustomCalendar> {
  DateTime? _lastExitTime; // Added for double-tap to exit
  late final DateTime _firstMonth;
  late PageController _pageController;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // 감정 이름과 SVG 경로 매핑 (AppImages에서 가져옴)
  final Map<String, String> _emotionSvgPaths = AppImages.emotionFaceSvgPaths;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final DateTime effectiveDate = widget.initialDate ?? now;

    _firstMonth = DateTime.utc(effectiveDate.year, effectiveDate.month, 1);
    
    // Set initial calendar state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarNotifier = ref.read(calendarProvider.notifier);
      calendarNotifier.setFocusedDay(DateTime(effectiveDate.year, effectiveDate.month, 1));
      calendarNotifier.setSelectedDay(now);
      
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

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    ref.read(calendarProvider.notifier).openDropdown();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    ref.read(calendarProvider.notifier).closeDropdown();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    final List<DateTime> monthsList = [];
    // 실제 현재 날짜와 시간을 사용
    final DateTime nowInDropdown = DateTime.now(); 

    DateTime currentMonthInLoop = _firstMonth;
    
    // 드롭다운 목록의 마지막 월: 실제 nowInDropdown을 기준으로 6개월 뒤
    final DateTime sixMonthsLater = DateTime(nowInDropdown.year, nowInDropdown.month + 6, 1);
    
    while (currentMonthInLoop.isBefore(sixMonthsLater) ||
           (currentMonthInLoop.year == sixMonthsLater.year && currentMonthInLoop.month == sixMonthsLater.month)) {
      monthsList.add(DateTime(currentMonthInLoop.year, currentMonthInLoop.month));
      currentMonthInLoop = DateTime(currentMonthInLoop.year, currentMonthInLoop.month + 1);
    }

    final currentFocusedDay = ref.read(calendarProvider).focusedDay;
    int focusedIndex = monthsList.indexWhere((month) => 
        month.year == currentFocusedDay.year && month.month == currentFocusedDay.month);
    
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: focusedIndex > 2 ? (focusedIndex - 2) * 50.0 : 0.0,
    );

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 160,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: Material(
                elevation: 4.0,
                color: const Color(0xFF494949),
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3F3F3F)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      itemCount: monthsList.length,
                      itemBuilder: (context, index) {
                        final month = monthsList[index];
                        final isCurrentMonth = month.year == currentFocusedDay.year && 
                                             month.month == currentFocusedDay.month;
                        
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                ref.read(calendarProvider.notifier).setFocusedDay(month);
                                final int targetPageIndex = 
                                    (month.year - _firstMonth.year) * 12 + 
                                    (month.month - _firstMonth.month);
                                _pageController.jumpToPage(targetPageIndex);
                                _removeOverlay();
                                _loadDiariesForMonth(month);
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${month.year}. ${month.month.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isCurrentMonth ? Colors.red : Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            if (index < monthsList.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 9.0),
                                child: Divider(
                                  color: const Color(0xFF757575),
                                  height: 1.0,
                                  thickness: 1.0,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 해당 월과 인접 월의 일기 데이터를 로드하는 함수
  Future<void> _loadDiariesForMonth(DateTime month) async {
    final userData = ref.read(userProvider);
    if (userData.userId == null) {
      print('CustomCalendar: User ID is null, cannot load diaries.');
      return;
    }

    // 캘린더 그리드에 표시될 수 있는 이전 달의 시작일과 다음 달의 마지막 날짜까지 포함하여 조회 범위를 확장
    final DateTime startOfRange = DateTime(month.year, month.month - 1, 1);
    final DateTime endOfRange = DateTime(month.year, month.month + 2, 0, 23, 59, 59);

    await ref.read(diaryProvider.notifier).loadDiariesForRange(startOfRange, endOfRange, userData.userId!);
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    final userData = ref.watch(userProvider);
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double crossAxisSpacing = 4.0;
    final double mainAxisSpacing = 2.0;

    final double squareCellSize =
        (screenWidth - (16.0 * 2) - (crossAxisSpacing * 6)) / 7;

    final double textSizedBoxHeight = 24.0;
    final double gridItemHeight = squareCellSize + textSizedBoxHeight + 4.0;

    return PopScope(
      canPop: false, // 기본 뒤로가기 동작 방지
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        // 실제 현재 날짜와 시간을 사용
        final DateTime now = DateTime.now(); 

        final DateTime currentMonth = DateTime(now.year, now.month, 1);
        final DateTime focusedMonth = DateTime(calendarState.focusedDay.year, calendarState.focusedDay.month, 1);

        if (focusedMonth.year != currentMonth.year || focusedMonth.month != currentMonth.month) {
          final int targetPageIndex = (now.year - _firstMonth.year) * 12 + (now.month - _firstMonth.month);
          _pageController.jumpToPage(targetPageIndex);
          ref.read(calendarProvider.notifier).setFocusedDay(currentMonth);
        } else {
          // User is on the current month, implement double-tap to exit
          if (_lastExitTime == null || DateTime.now().difference(_lastExitTime!) > const Duration(seconds: 2)) {
            _lastExitTime = DateTime.now();
            Fluttertoast.showToast(
              msg: "한번 더 뒤로가기 시 앱이 종료됩니다.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            // Exit the app
            SystemNavigator.pop(); 
          }
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 44.0, bottom: 12.0, left: 16.0, right: 16.0),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36.0),
                  GestureDetector(
                    onTap: () {
                      if (calendarState.isDropdownActive) {
                        _removeOverlay();
                      } else {
                        _showDropdown();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${calendarState.focusedDay.year}.${calendarState.focusedDay.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 36.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        SvgPicture.asset(
                          calendarState.isDropdownActive
                              ? 'assets/icon/calendar_dropdown_active.svg'
                              : 'assets/icon/calendar_dropdown_inactive.svg',
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          Expanded( // 남은 세로 공간을 모두 차지하도록 변경
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                final newFocusedDay = DateTime(
                    _firstMonth.year, _firstMonth.month + index, _firstMonth.day);
                ref.read(calendarProvider.notifier).setFocusedDay(newFocusedDay);
                _loadDiariesForMonth(newFocusedDay); // 월 변경 시 일기 로드
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

                    // 실제 현재 날짜와 시간을 사용
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
                    
                    // Get emotion from Riverpod provider
                    final String? emotion = ref.watch(emotionForDateProvider(day));

                    return _buildDayCell(
                      day: day,
                      isToday: isToday,
                      isSelected: isSelected,
                      isWeekend: isWeekend,
                      isCurrentMonthDay: isCurrentMonthDay,
                      isPreviousMonthDay: isPreviousMonthDay,
                      squareCellSize: squareCellSize,
                      textSizedBoxHeight: textSizedBoxHeight,
                      onTap: () async {
                          ref.read(calendarProvider.notifier).setSelectedDay(day);

                          // 실제 현재 날짜와 시간을 사용
                          final DateTime today = DateTime.now(); 
                          final DateTime normalizedToday = DateTime(today.year, today.month, today.day);
                          final DateTime normalizedSelectedDay = DateTime(day.year, day.month, day.day);

                          // 새 조건: 선택된 날짜가 _firstMonth (가입한 날짜의 달)의 시작일보다 이전인지 확인
                          final DateTime firstClickableMonthStart = DateTime(_firstMonth.year, _firstMonth.month, 1);
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
                              print('가입일 이전 날짜 선택됨: ${day.toIso8601String()}');
                              return; // 클릭 처리 중단
                          }

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

                          if (userData.userId != null) {
                            final hasDiary = await ref.read(diaryProvider.notifier).hasDiaryOnDate(day, userData.userId!);
                            
                            if (hasDiary) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DiaryViewScreen(selectedDate: day, createdAt: widget.initialDate),
                                ),
                              ).then((_) => _loadDiariesForMonth(calendarState.focusedDay)); // 돌아왔을 때 데이터 새로고침
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
                                ).then((_) => _loadDiariesForMonth(calendarState.focusedDay));
                                print('오늘 날짜 일기 없음 - 작성 화면으로: ${day.toIso8601String()}');
                              } else {
                                // 오늘이 아닌 날짜이면서 일기가 없으면 통합된 화면으로 (프롬프트 표시)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiaryViewScreen(selectedDate: day, createdAt: widget.initialDate),
                                  ),
                                ).then((_) => _loadDiariesForMonth(calendarState.focusedDay));
                                print('과거 날짜 일기 없음 - 통합 화면으로: ${day.toIso8601String()}');
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
                              ).then((_) => _loadDiariesForMonth(calendarState.focusedDay)); // 돌아왔을 때 데이터 새로고침
                              print('userId 없음. 일기 작성 화면으로 이동.');
                          }
                        },
                      emotion: emotion, // 감정 정보 전달
                    );
                  },
                  itemCount: fixedTotalCells,
                );
              },
              itemCount: 200000,
            ),
          ),
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

    // 실제 현재 날짜와 시간을 사용
    final DateTime now = DateTime.now();

    // 1. 배경색 및 글자색 결정
    // isCurrentMonthDay는 해당 셀이 현재 "보고 있는 달"에 속하는지 여부
    if (isCurrentMonthDay) {
      if (day.year == now.year && day.month == now.month && day.day == now.day) {
        backgroundColor = const Color(0xFFFF4646);
        textColor = const Color(0xFFFF3B3B); // 오늘 날짜는 항상 FF3B3B
      } else {
        backgroundColor = const Color(0xFF4C3030);
        textColor = const Color(0xFFC5C5C5);
      }
    } else { // 이전 달 또는 다음 달의 날짜
      backgroundColor = const Color(0xFF363636); // 이전/다음 달 날짜의 배경색
      textColor = const Color(0xFF363636); // 이전/다음 달 날짜의 글자색
    }

    // 2. 감정 SVG 위젯 설정
    // emotion이 null이 아니면 감정 아이콘을 표시
    if (emotion != null) {
      String? svgPath;
      if (isCurrentMonthDay) {
        // 현재 달에 속하는 날짜는 컬러 감정 아이콘 사용
        svgPath = _emotionSvgPaths[emotion];
      } else {
        // 이전 달 또는 다음 달에 속하는 날짜는 회색 감정 아이콘 사용
        svgPath = AppImages.emotiongrayFaceSvgPaths[emotion]; // gray SVG 맵 사용
      }
      
      if (svgPath != null) {
        emotionSvgWidget = SvgPicture.asset(
          svgPath,
          width: squareCellSize,
          height: squareCellSize,
          fit: BoxFit.contain,
        );
        // 감정 SVG가 있으면 배경색을 투명으로 설정하여 아이콘이 보이도록 함
        backgroundColor = Colors.transparent; 
        // 현재 달의 날짜인 경우에만 글자색을 흰색으로 변경
        if (isCurrentMonthDay) {
          // 오늘 날짜인 경우 FF3B3B 유지
          if (day.year == now.year && day.month == now.month && day.day == now.day) {
            textColor = const Color(0xFFFF3B3B);
          } else {
            textColor = const Color(0xFFC5C5C5); 
          }
        }
        // 이전 달 또는 다음 달의 날짜인 경우 textColor는 초기 설정값(0xFF363636)을 유지
      }
    }

    // 3. 오늘 날짜 작성 이모티콘 위젯 설정
    // 오늘 날짜이면서 감정 이모티콘이 없는 경우에만 표시
    if (day.year == now.year && day.month == now.month && day.day == now.day && emotion == null) {
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