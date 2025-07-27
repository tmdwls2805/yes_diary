import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final bool isDropdownActive;

  CalendarState({
    required this.focusedDay,
    this.selectedDay,
    this.isDropdownActive = false,
  });

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    bool? isDropdownActive,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      isDropdownActive: isDropdownActive ?? this.isDropdownActive,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(CalendarState(
    focusedDay: DateTime.now(),
    selectedDay: DateTime.now(),
  ));

  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  void setSelectedDay(DateTime day) {
    state = state.copyWith(selectedDay: day);
  }

  void toggleDropdown() {
    state = state.copyWith(isDropdownActive: !state.isDropdownActive);
  }

  void closeDropdown() {
    state = state.copyWith(isDropdownActive: false);
  }

  void openDropdown() {
    state = state.copyWith(isDropdownActive: true);
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});