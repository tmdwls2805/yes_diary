import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/constants/app_image.dart';

class DiaryBodyWithNavigation extends StatelessWidget {
  final String? emotion;
  final VoidCallback? onLeftSwipe;
  final VoidCallback? onRightSwipe;
  final double imageWidth;
  final double imageHeight;

  const DiaryBodyWithNavigation({
    Key? key,
    this.emotion,
    this.onLeftSwipe,
    this.onRightSwipe,
    this.imageWidth = 92,
    this.imageHeight = 142,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10.0),
        SizedBox(
          height: imageHeight,
          child: Stack(
            children: [
              // Center body image
              Center(
                child: SvgPicture.asset(
                  emotion != null 
                    ? (AppImages.emotionBodySvgPaths[emotion] ?? 'assets/emotion/gray_body.svg')
                    : 'assets/emotion/gray_body.svg',
                  width: imageWidth,
                  height: imageHeight,
                ),
              ),
              // Left swipe button
              if (onLeftSwipe != null)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onLeftSwipe,
                        icon: Transform.rotate(
                          angle: 3.14159, // 180 degrees in radians
                          child: SvgPicture.asset(
                            'assets/button/swipe.svg',
                            width: 42,
                            height: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Right swipe button
              if (onRightSwipe != null)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onRightSwipe,
                        icon: SvgPicture.asset(
                          'assets/button/swipe.svg',
                          width: 42,
                          height: 42,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
        if (emotion != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppImages.emotionQuestionTexts[emotion] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}