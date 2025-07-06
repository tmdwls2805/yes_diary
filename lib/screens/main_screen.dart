import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('메인 화면')),
      body: Center(
        child: Column(
          children: [
            // 캘린더 위젯이 들어갈 자리
            Text('캘린더'),
            Expanded(child: Container()), // 캘린더와 하단 메뉴바 사이 공간
            // 하단 메뉴바 위젯이 들어갈 자리
            BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  IconButton(icon: Icon(Icons.home), onPressed: () {}),
                  IconButton(icon: Icon(Icons.settings), onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 