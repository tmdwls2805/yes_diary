import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/constants/app_image.dart';

class DiaryEmotionSelector extends StatelessWidget {
  final String? selectedEmotion;
  final Function(String)? onEmotionSelected;
  final bool isReadOnly;

  const DiaryEmotionSelector({
    Key? key,
    this.selectedEmotion,
    this.onEmotionSelected,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: AppImages.emotionFaceSvgPaths.entries.map((entry) {
              final emotionName = entry.key;
              final svgPath = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildEmotionOption(emotionName, svgPath),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 28.0),
            child: Text(
              selectedEmotion == null
                  ? '오늘 해소할 감정은 무엇인가요?'
                  : AppImages.emotionQuestionTexts[selectedEmotion]!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionOption(String emotionName, String svgPath) {
    final isSelected = selectedEmotion == emotionName;
    return GestureDetector(
      onTap: isReadOnly ? null : () => onEmotionSelected?.call(emotionName),
      child: Transform.translate(
        offset: Offset(0, isSelected ? -8.0 : 0),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: const Color(0xFFFF0000), width: 2.0)
                : null,
          ),
          child: SvgPicture.asset(
            svgPath,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}