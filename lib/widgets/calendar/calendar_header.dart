import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../core/di/injection_container.dart';

class CalendarHeader extends ConsumerWidget {
  final LayerLink layerLink;
  final VoidCallback onToggleDropdown;

  const CalendarHeader({
    Key? key,
    required this.layerLink,
    required this.onToggleDropdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarViewModelProvider);

    return Padding(
      padding: const EdgeInsets.only(
          top: 44.0, bottom: 12.0, left: 16.0, right: 16.0),
      child: CompositedTransformTarget(
        link: layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year display with dropdown
            GestureDetector(
              onTap: onToggleDropdown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '${calendarState.focusedDay.year}',
                    style: const TextStyle(
                      fontSize: 36.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SvgPicture.asset(
                    calendarState.isDropdownActive
                        ? 'assets/icon/calendar_dropdown_active.svg'
                        : 'assets/icon/calendar_dropdown_inactive.svg',
                    width: 16,
                    height: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0.0),
            // Month display
            GestureDetector(
              onTap: onToggleDropdown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM', 'en_US')
                        .format(calendarState.focusedDay)
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
    );
  }
}