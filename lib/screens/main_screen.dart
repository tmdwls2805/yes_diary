import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/screens/diary_tab_screen.dart';
import 'package:yes_diary/widgets/my_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_selectedIndex == 1) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
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
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _selectedIndex == 0
                      ? SvgPicture.asset('assets/icon/menu_diary_active.svg', width: 24, height: 24)
                      : SvgPicture.asset('assets/icon/menu_diary_inactive.svg', width: 24, height: 24),
                ),
                label: '일기',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _selectedIndex == 1
                      ? SvgPicture.asset('assets/icon/menu_my_active.svg', width: 24, height: 24)
                      : SvgPicture.asset('assets/icon/menu_my_inactive.svg', width: 24, height: 24),
                ),
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
            selectedLabelStyle: const TextStyle(fontSize: 10.0, height: 1.0),
            unselectedLabelStyle: const TextStyle(fontSize: 10.0, height: 1.0),
            iconSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return const MyScreen();
    }
    return const DiaryTabScreen();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
