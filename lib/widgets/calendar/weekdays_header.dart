import 'package:flutter/material.dart';

class WeekdaysHeader extends StatelessWidget {
  const WeekdaysHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final days = ['일', '월', '화', '수', '목', '금', '토'];
          return Expanded(
            child: Center(
              child: Text(
                days[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}