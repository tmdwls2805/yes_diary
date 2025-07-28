import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/providers/user_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);
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
    final userData = ref.watch(userProvider);
    
    switch (_selectedIndex) {
      case 0:
        return Column(
          children: [
            Expanded(
              child: userData.userId == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : CustomCalendar(
                      initialDate: userData.createdAt,
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