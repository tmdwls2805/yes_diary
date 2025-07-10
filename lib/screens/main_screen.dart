import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  // 캘린더 관련 상태 (현재 사용하지 않지만 유지)
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 💡 버튼 기능 관련 상태 변수 추가
  int _pressCount = 0; // 버튼이 눌린 횟수
  final int _maxPressCount = 100; // 최대 눌러야 하는 횟수

  // 💡 버튼 색상을 계산하는 헬퍼 함수
  Color _getButtonFillColor() {
    // 0부터 100까지의 pressCount를 0.0부터 1.0 사이의 비율로 변환
    double fillRatio = _pressCount / _maxPressCount;
    // E22200 색상 (불투명도 1.0)
    const Color targetColor = Color(0xFFE22200);
    // 검정색 (초기 색상)
    const Color initialColor = Color(0xFF262626); // 버튼의 기본 배경색과 동일하게 설정

    // fillRatio에 따라 initialColor에서 targetColor로 보간
    // Color.lerp는 두 색상 사이를 보간해주는 유용한 함수입니다.
    return Color.lerp(initialColor, targetColor, fillRatio)!;
  }

  // 💡 버튼이 눌렸을 때 호출되는 함수
  void _onButtonPressed() {
    setState(() {
      if (_pressCount < _maxPressCount) {
        _pressCount++;
      }
      // 선택적으로, 100번 눌렀을 때 특정 동작을 추가할 수 있습니다.
      if (_pressCount == _maxPressCount) {
        print('버튼이 100번 눌렸습니다!');
        // 예: 다이얼로그 표시, 다른 화면으로 이동 등
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 배경색을 검정색으로 유지
      body: Column(
        children: [
          CustomCalendar(), // Custom Calendar Widget

          const Spacer(), // 캘린더와 하단 버튼 사이의 남은 공간을 모두 차지

          // "퇴사하고 싶을 때 누르는 버튼" 컨테이너
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            // 💡 GestureDetector로 감싸서 탭 이벤트를 감지
            child: GestureDetector(
              onTap: _onButtonPressed, // 버튼 탭 시 _onButtonPressed 함수 호출
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  // 💡 배경색을 _getButtonFillColor 함수를 통해 동적으로 설정
                  color: _getButtonFillColor(),
                  borderRadius: BorderRadius.circular(10.0), // 둥근 모서리
                ),
                child: Row( // Row를 const로 선언할 수 없음 (_pressCount 표시)
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 정렬
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.red), // 불꽃 아이콘
                        SizedBox(width: 8.0),
                        Text(
                          // 💡 현재 눌린 횟수를 표시하는 텍스트 추가
                          '퇴사하고 싶을 때 누르는 버튼 (${_pressCount}/${_maxPressCount})',
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ],
                    ),
                    Text(
                      '😠', // 이모지
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black, // 하단 메뉴바 배경색을 검정색으로 변경
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note, color: Colors.red),
                const Text(
                  '일기',
                  style: TextStyle(color: Colors.red, fontSize: 12.0),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_satisfied_alt, color: Color(0xFF808080)),
                const Text(
                  '마이',
                  style: TextStyle(color: Color(0xFF808080), fontSize: 12.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}