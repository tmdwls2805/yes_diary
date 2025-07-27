import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 화면 너비 정보 가져오기 (여기서도 반응형 폰트 크기 등을 적용할 수 있습니다)
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black, // 배경색을 검정색으로 설정
      appBar: AppBar(
        title: Text(
          'My',
          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.05), // 제목 폰트 크기도 반응형
        ),
        backgroundColor: Colors.black, // 앱바 배경색 검정색
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼 등 아이콘 색상 흰색
      ),
      body: Center(
        child: Text(
          'my',
          style: TextStyle(fontSize: screenWidth * 0.12, color: Colors.white), // "my" 텍스트 스타일도 반응형
        ),
      ),
    );
  }
}