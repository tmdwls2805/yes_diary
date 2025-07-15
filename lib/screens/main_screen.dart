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

  // 💡 하단 내비게이션 바 현재 선택된 인덱스
  int _selectedIndex = 0; // 0: 일기, 1: 마이

  @override
  Widget build(BuildContext context) {
    // 💡 MediaQuery를 사용하여 하단 시스템 내비게이션 바의 높이를 가져옴
    final double bottomSystemPadding = MediaQuery.of(context).padding.bottom;
    
    // 💡 원하는 BottomNavigationBar의 최소 높이 설정 (80.0px)
    final double desiredNavBarHeight = 80.0; 

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // 배경색을 #1A1A1A로 유지
      body: _buildBody(), // 현재 선택된 탭에 따라 body를 빌드하는 함수
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A), // 컨테이너 배경색을 #1A1A1A로 유지
          border: Border(
            top: BorderSide(
              color: Color(0xFF3F3F3F), // 테두리 색상 #3F3F3F
              width: 1.0, // 테두리 두께 1px
            ),
          ),
        ),
        // 💡 컨테이너의 높이를 다시 설정하여 바텀 네비게이션 바의 전체 공간을 늘립니다.
        height: desiredNavBarHeight + bottomSystemPadding, 
        // 💡 시스템 내비게이션 바 높이만큼 하단 패딩만 추가하여 안전 영역을 확보합니다.
        padding: EdgeInsets.only(bottom: bottomSystemPadding), 
        // 💡 BottomNavigationBar를 컨테이너 상단에 정렬하는 속성을 제거하여 내부 콘텐츠가 중앙에 오도록 합니다.
        // alignment: Alignment.topCenter, 
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              // 아이콘 크기를 원래대로 36으로 유지합니다.
              icon: _selectedIndex == 0
                  ? SvgPicture.asset('assets/icon/menu_diary_active.svg', width: 36, height: 36)
                  : SvgPicture.asset('assets/icon/menu_diary_inactive.svg', width: 36, height: 36),
              label: '일기',
            ),
            BottomNavigationBarItem(
              // 아이콘 크기를 원래대로 36으로 유지합니다.
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
          backgroundColor: Colors.black, // BottomNavigationBar 자체의 배경색은 검정색으로 유지
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          // 라벨 폰트 크기를 원래대로 12.0으로 유지합니다.
          selectedLabelStyle: const TextStyle(fontSize: 12.0),
          unselectedLabelStyle: const TextStyle(fontSize: 12.0),
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
            // 💡 CustomCalendar를 Expanded로 감싸서 남은 공간을 모두 차지하도록 합니다.
            Expanded(
              child: CustomCalendar(), 
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
}
