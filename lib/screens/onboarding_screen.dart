import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('온보딩')),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: const <Widget>[
              OnboardingPage(
                title: '환영합니다!',
                description: '예스 다이어리에서 당신의 하루를 기록해보세요.',
                image: Icons.book,
              ),
              OnboardingPage(
                title: '간편한 기록',
                description: '손쉽게 감정과 생각을 정리할 수 있습니다.',
                image: Icons.edit,
              ),
              OnboardingPage(
                title: '한눈에 보기',
                description: '캘린더로 지난 기록을 한눈에 확인하세요.',
                image: Icons.calendar_today,
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => buildDot(index, context)),
                  ),
                  if (_currentPage == 2) // 마지막 페이지에서만 시작하기 버튼 표시
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/main');
                        },
                        child: Text('시작하기'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData image;

  const OnboardingPage({required this.title, required this.description, required this.image});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(image, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
