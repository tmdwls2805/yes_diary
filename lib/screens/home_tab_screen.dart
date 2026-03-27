import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimeState {
  workTime,      // 근무 시간
  nightWorkTime, // 야근 시간
  wakeUpTime,    // 기상 시간
  bedTime,       // 취침 시간
}

class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  // 임시: 현재 시간대 설정 (테스트용)
  TimeState currentTimeState = TimeState.nightWorkTime;

  TimeState _getCurrentTimeState() {
    // TODO: 실제 시간에 따라 TimeState 반환
    // final now = DateTime.now();
    // final hour = now.hour;

    return currentTimeState;
  }

  String _getImageForTimeState(TimeState state) {
    switch (state) {
      case TimeState.workTime:
        return 'assets/home/work_time.png';
      case TimeState.nightWorkTime:
        return 'assets/home/night_work_time.png';
      case TimeState.wakeUpTime:
        return 'assets/home/wake_up_time.png'; // 나중에 추가
      case TimeState.bedTime:
        return 'assets/home/bed_time.png'; // 나중에 추가
    }
  }

  String _getDepartmentNameForTimeState(TimeState state) {
    switch (state) {
      case TimeState.workTime:
        return '연구사설공중분해팀';
      case TimeState.nightWorkTime:
        return '야근중인팀';
      case TimeState.wakeUpTime:
        return '기상팀';
      case TimeState.bedTime:
        return '취침팀';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeState = _getCurrentTimeState();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 부서 태그 - 시간대에 따라 변경
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDepartmentTag(_getDepartmentNameForTimeState(timeState)),
                  ),

                  const SizedBox(height: 70),

                  // 이미지 - 시간대에 따라 변경 (고정 높이로 통일)
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * (278 / 393), // 큰 이미지 비율 기준
                    child: Image.asset(
                      _getImageForTimeState(timeState),
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: SizedBox(
                width: 358,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E6E6E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '버튼',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentTag(String text) {
    return IntrinsicWidth(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF7F7F7F),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFA5A5A5),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
