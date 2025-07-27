import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/constants/app_image.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final bool isCurrentMonthDay;
  final bool isPreviousMonthDay;
  final double squareCellSize;
  final double textSizedBoxHeight;
  final VoidCallback? onTap;
  final String? emotion;

  const CalendarDayCell({
    Key? key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.isCurrentMonthDay,
    required this.isPreviousMonthDay,
    required this.squareCellSize,
    required this.textSizedBoxHeight,
    required this.onTap,
    this.emotion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    // 1. 배경색 및 글자색 결정
    Color backgroundColor;
    Color textColor;
    
    if (isCurrentMonthDay) {
      if (day.year == now.year && day.month == now.month && day.day == now.day) {
        backgroundColor = const Color(0xFFFF4646);
        textColor = const Color(0xFFFF3B3B); // 오늘 날짜는 항상 FF3B3B
      } else {
        backgroundColor = const Color(0xFF4C3030);
        textColor = const Color(0xFFC5C5C5);
      }
    } else { // 이전 달 또는 다음 달의 날짜
      backgroundColor = const Color(0xFF363636);
      textColor = const Color(0xFF363636);
    }

    // 2. 감정 SVG 위젯 설정
    Widget? emotionSvgWidget;
    Widget? todayIconWidget;
    
    if (emotion != null) {
      String? svgPath;
      if (isCurrentMonthDay) {
        svgPath = AppImages.emotionFaceSvgPaths[emotion];
      } else {
        svgPath = AppImages.emotiongrayFaceSvgPaths[emotion];
      }
      
      if (svgPath != null) {
        emotionSvgWidget = SvgPicture.asset(
          svgPath,
          width: squareCellSize,
          height: squareCellSize,
          fit: BoxFit.contain,
        );
        backgroundColor = Colors.transparent;
        
        if (isCurrentMonthDay) {
          if (day.year == now.year && day.month == now.month && day.day == now.day) {
            textColor = const Color(0xFFFF3B3B);
          } else {
            textColor = const Color(0xFFC5C5C5);
          }
        }
      }
    }

    // 3. 오늘 날짜 작성 이모티콘 위젯 설정 (현재 월에서만 표시)
    if (day.year == now.year && day.month == now.month && day.day == now.day && emotion == null && isCurrentMonthDay) {
      todayIconWidget = SvgPicture.asset(
        'assets/icon/write_diary.svg',
        width: squareCellSize * 0.8,
        height: squareCellSize * 0.8,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Column(
          children: [
            Container(
              height: squareCellSize,
              width: squareCellSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (emotionSvgWidget != null) emotionSvgWidget!,
                  if (todayIconWidget != null) todayIconWidget!,
                ],
              ),
            ),
            SizedBox(
              height: textSizedBoxHeight,
              child: Text(
                '${day.day}',
                style: TextStyle(color: textColor, fontSize: 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}