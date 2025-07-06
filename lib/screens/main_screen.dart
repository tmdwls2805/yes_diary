import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart'; // table_calendar 패키지 import
import 'package:intl/intl.dart'; // DateFormat을 사용하기 위해 import 추가
import 'package:yes_diary/widgets/custom_calendar.dart'; // CustomCalendar import

class MainScreen extends StatefulWidget { // StatelessWidget을 StatefulWidget으로 변경
  @override
  _MainScreenState createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  DateTime _focusedDay = DateTime.now(); // 현재 포커스된 달 (기본값: 현재 날짜)
  DateTime? _selectedDay; // 사용자가 선택한 날짜 (초기값: 없음)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메인 화면')),
      body: Center(
        child: Column(
          children: [
            CustomCalendar(), // Custom Calendar Widget
            Expanded(child: Container()), // 캘린더와 하단 메뉴바 사이 공간
            // 하단 메뉴바 위젯
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, color: Colors.red), // 일기 아이콘
                      Text(
                        '일기',
                        style: TextStyle(color: Colors.red, fontSize: 12.0),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sentiment_satisfied_alt, color: Color(0xFFFDE9E9)), // 마이 아이콘 (연한 핑크)
                      Text(
                        '마이',
                        style: TextStyle(color: Colors.black, fontSize: 12.0), // 검정색 텍스트
                      ),
                    ],
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