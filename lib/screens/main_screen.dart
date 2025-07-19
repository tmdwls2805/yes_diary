import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;
  DateTime? _createdAt;
  String? _currentUserId;
  bool _isLoading = true; // 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final secureStorageService = SecureStorageService();
    String? createdAtString = await secureStorageService.getCreatedAt();
    String? userIdString = await secureStorageService.getUserId();

    setState(() {
      if (createdAtString != null) {
        _createdAt = DateTime.parse(createdAtString);
      }
      _currentUserId = userIdString;
      _isLoading = false; // 데이터 로드 완료
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSystemPadding = MediaQuery.of(context).padding.bottom;
    final double desiredNavBarHeight = 80.0; 

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), 
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A), 
          border: Border(
            top: BorderSide(
              color: Color(0xFF3F3F3F), 
              width: 1.0, 
            ),
          ),
        ),
        height: desiredNavBarHeight + bottomSystemPadding, 
        padding: EdgeInsets.only(bottom: bottomSystemPadding), 
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
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Column(
          children: [
            Expanded(
              // _isLoading이 false이고 _currentUserId가 null이 아닐 때만 CustomCalendar를 렌더링
              child: _isLoading || _currentUserId == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : CustomCalendar(
                      initialDate: _createdAt,
                      userId: _currentUserId!, // null이 아님이 보장되므로 ! 사용
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
        return Container();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
