import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/injection_container.dart';

class MonthDropdownOverlay {
  static OverlayEntry createOverlay({
    required BuildContext context,
    required WidgetRef ref,
    required LayerLink layerLink,
    required DateTime firstMonth,
    required PageController pageController,
    required VoidCallback onRemoveOverlay,
    required Function(DateTime) onLoadDiariesForMonth,
  }) {
    final List<DateTime> monthsList = [];
    final DateTime nowInDropdown = DateTime.now();

    DateTime currentMonthInLoop = firstMonth;
    final DateTime sixMonthsLater = DateTime(nowInDropdown.year, nowInDropdown.month + 6, 1);
    
    while (currentMonthInLoop.isBefore(sixMonthsLater) ||
           (currentMonthInLoop.year == sixMonthsLater.year && currentMonthInLoop.month == sixMonthsLater.month)) {
      monthsList.add(DateTime(currentMonthInLoop.year, currentMonthInLoop.month));
      currentMonthInLoop = DateTime(currentMonthInLoop.year, currentMonthInLoop.month + 1);
    }

    final currentFocusedDay = ref.read(calendarViewModelProvider).focusedDay;
    int focusedIndex = monthsList.indexWhere((month) => 
        month.year == currentFocusedDay.year && month.month == currentFocusedDay.month);
    
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: focusedIndex > 2 ? (focusedIndex - 2) * 50.0 : 0.0,
    );

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to catch outside clicks
          Positioned.fill(
            child: GestureDetector(
              onTap: onRemoveOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown menu
          Positioned(
            width: 160,
            child: CompositedTransformFollower(
              link: layerLink,
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
                                ref.read(calendarViewModelProvider.notifier).setFocusedDay(month);
                                final int targetPageIndex = 
                                    (month.year - firstMonth.year) * 12 + 
                                    (month.month - firstMonth.month);
                                pageController.jumpToPage(targetPageIndex);
                                onRemoveOverlay();
                                onLoadDiariesForMonth(month);
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
}