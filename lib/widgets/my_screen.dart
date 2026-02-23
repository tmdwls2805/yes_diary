import 'package:flutter/material.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 상단 스와이프 가능한 콘텐츠 영역
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildFirstContent(),
                    _buildSecondContent(),
                  ],
                ),
              ),

              // 하단 고정 영역 (인디케이터 + 버튼)
              Column(
                children: [
                  // 인디케이터
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _currentPage == 0 ? 'assets/icon/indicate_active.png' : 'assets/icon/indicate_inactive.png',
                          width: 8,
                          height: 8,
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          _currentPage == 1 ? 'assets/icon/indicate_active.png' : 'assets/icon/indicate_inactive.png',
                          width: 8,
                          height: 8,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 카카오 로그인 버튼
                  Center(
                    child: SizedBox(
                      width: 358,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 카카오 로그인 구현
                          print('카카오 로그인 버튼 클릭');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/Kakao.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '카카오로 시작하기',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 애플 로그인 버튼
                  Center(
                    child: SizedBox(
                      width: 358,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 애플 로그인 구현
                          print('애플 로그인 버튼 클릭');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/Apple.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Apple로 시작하기',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstContent() {
    return const Center(
      child: Text(
        '첫 번째 페이지',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSecondContent() {
    return const Center(
      child: Text(
        '두 번째 페이지',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
