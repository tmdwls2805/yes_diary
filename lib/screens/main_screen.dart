import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'dart:async'; // Import Timer

class MainScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  int _clickCount = 0;
  double _fillPercentage = 0.0;
  Timer? _decayTimer; // Timer for gradual decrease

  @override
  void initState() {
    super.initState();
    _startDecayTimer(); // Start the decay timer
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    super.dispose();
  }

  void _startDecayTimer() {
    _decayTimer?.cancel(); // Cancel any existing timer
    _decayTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_clickCount > 0) {
        setState(() {
          _clickCount = (_clickCount - 1).clamp(0, 100);
          _fillPercentage = _clickCount / 100.0;
        });
      } else {
        _decayTimer?.cancel(); // Stop timer if fill is empty
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);
    final double bottomSystemPadding = MediaQuery.of(context).padding.bottom;
    final double desiredNavBarHeight = 80.0;

    return PopScope(
      canPop: false, // Disable default pop behavior
      onPopInvoked: (didPop) {
        if (didPop) return; // If the system is already handling the pop, do nothing
        if (_selectedIndex == 1) {
          setState(() {
            _selectedIndex = 0; // Navigate to the Calendar tab
          });
        } else {
          // Let the CustomCalendar handle its own PopScope for app exit
          // The CustomCalendar has its own PopScope to handle app exit on double-tap
          // No explicit pop needed here, as the CustomCalendar's PopScope will be triggered.
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
      ),
    );
  }

  Widget _buildBody() {
    final userData = ref.watch(userProvider);

    return Column(
      children: [
        Flexible(
          child: userData.userId == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : CustomCalendar(
                    initialDate: userData.createdAt,
                  ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
          child: Container(
            width: double.infinity,
            height: 50.0,
            decoration: BoxDecoration( // Add BoxDecoration to the parent Container
              borderRadius: BorderRadius.circular(34.0),
              border: Border.all(color: const Color(0x14FF0000), width: 1.0), // Apply the border here
            ),
            child: ClipRRect( // Clip the Stack to match the parent Container's rounded corners
              borderRadius: BorderRadius.circular(34.0),
              child: Stack(
                children: [
                  // AnimatedContainer as the background fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: _fillPercentage * (MediaQuery.of(context).size.width - 32.0), // Subtract horizontal padding
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE22200), // Fill color
                      // No need for borderRadius here, as it's clipped by the parent ClipRRect
                    ),
                  ),
                  SizedBox.expand( // Ensures ElevatedButton takes full available size
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _clickCount = (_clickCount + 1).clamp(0, 100); // Cap clicks at 100
                          _fillPercentage = _clickCount / 100.0;
                          print('Click count: $_clickCount, Fill percentage: $_fillPercentage');
                          _startDecayTimer(); // Restart or ensure timer is running on click
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Make button transparent to show fill
                        elevation: 0, // Remove shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(34.0), // Keep this for visual shape if needed
                        ),
                        side: BorderSide.none, // Remove the side from ElevatedButton
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '🔥 ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '퇴사',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '하고 싶을 때 누르는 버튼',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/emotion/red.svg',
                            width: 40, // Adjusted SVG size
                            height: 40, // Adjusted SVG size
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}