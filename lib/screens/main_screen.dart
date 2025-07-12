import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  // 💡 하단 내비게이션 바 현재 선택된 인덱스
  int _selectedIndex = 0; // 0: 일기, 1: 마이

  @override
  Widget build(BuildContext context) {
    // 💡 MediaQuery를 사용하여 하단 시스템 내비게이션 바의 높이를 가져옴
    final double bottomSystemPadding = MediaQuery.of(context).padding.bottom;
    
    // 💡 원하는 BottomNavigationBar의 최소 높이 설정 (예: 80.0)
    // 이 값은 아이콘+텍스트 높이 + 위아래 여백을 고려하여 조절하세요.
    final double desiredNavBarHeight = 80.0; 

    return Scaffold(
      backgroundColor: Colors.black, // 배경색을 검정색으로 유지
      body: _buildBody(), // 현재 선택된 탭에 따라 body를 빌드하는 함수
      bottomNavigationBar: Container(
        color: Colors.black, // 컨테이너 배경색
        // 💡 컨테이너의 전체 높이 = 원하는 내비게이션 바 높이 + 시스템 패딩
        height: desiredNavBarHeight + bottomSystemPadding, 
        padding: EdgeInsets.only(bottom: bottomSystemPadding), // 시스템 내비게이션 바 높이만큼 하단 패딩 추가
        alignment: Alignment.topCenter, // BottomNavigationBar를 컨테이너 상단에 정렬
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _selectedIndex == 0
                  ? SvgPicture.asset('assets/icon/menu_diary_active.svg', width: 36, height: 36)
                  : SvgPicture.asset('assets/icon/menu_diary_inactive.svg', width: 36, height: 36),
              label: '일기',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 1
                  ? SvgPicture.asset('assets/icon/menu_my_active.svg', width: 36, height: 36)
                  : SvgPicture.asset('assets/icon/menu_my_inactive.svg', width: 36, height: 36),
              label: '마이',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.red,
          unselectedItemColor: const Color(0xFF808080),
          onTap: _onItemTapped,
          backgroundColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 12.0),
          unselectedLabelStyle: const TextStyle(fontSize: 12.0),
          // BottomNavigationBar의 기본 높이(약 56.0)를 따르지만,
          // 감싸는 Container의 높이를 통해 전체 영역을 늘립니다.
        ),
      ),
    );
  }

  // 💡 현재 선택된 탭에 따라 body 부분을 빌드하는 함수
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Column(
          children: [
            CustomCalendar(), // Custom Calendar Widget

            const Spacer(), // 캘린더와 하단 버튼 사이의 남은 공간을 모두 차지

            // "퇴사하고 싶을 때 누르는 버튼" 컨테이너
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: GestureDetector(
                onTap: _onButtonPressed, // 버튼 탭 시 _onButtonPressed 함수 호출
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: _getButtonFillColor(), // 배경색을 _getButtonFillColor 함수를 통해 동적으로 설정
                    borderRadius: BorderRadius.circular(10.0), // 둥근 모서리
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 정렬
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.red), // 불꽃 아이콘
                          SizedBox(width: 8.0),
                          Text(
                            // 현재 눌린 횟수를 표시하는 텍스트 추가
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
        );
      case 1:
        return const Center(
          child: Text(
            'my',
            style: TextStyle(fontSize: 48, color: Colors.white),
          ),
        );
      default:
        return Container(); // 기본적으로 빈 컨테이너 반환
    }
  }

  // 💡 하단 내비게이션 바 탭 변경 시 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 💡 버튼 색상을 계산하는 헬퍼 함수 (기존 코드 유지)
  Color _getButtonFillColor() {
    double fillRatio = _pressCount / _maxPressCount;
    const Color targetColor = Color(0xFFE22200);
    const Color initialColor = Color(0xFF262626);
    return Color.lerp(initialColor, targetColor, fillRatio)!;
  }

  // 💡 버튼이 눌렸을 때 호출되는 함수 (기존 코드 유지)
  void _onButtonPressed() {
    setState(() {
      if (_pressCount < _maxPressCount) {
        _pressCount++;
      }
      if (_pressCount == _maxPressCount) {
        print('버튼이 100번 눌렸습니다!');
      }
    });
  }
}