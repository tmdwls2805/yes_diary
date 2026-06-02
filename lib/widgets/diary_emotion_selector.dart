import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/constants/app_image.dart';

class DiaryEmotionSelector extends StatefulWidget {
  final String? selectedEmotion;
  final Function(String)? onEmotionSelected;
  final bool isReadOnly;
  final bool showQuestionText;
  final Map<String, String> imagePaths;
  final double itemSpacing;

  const DiaryEmotionSelector({
    super.key,
    this.selectedEmotion,
    this.onEmotionSelected,
    this.isReadOnly = false,
    this.showQuestionText = true,
    this.imagePaths = AppImages.emotionFaceSvgPaths,
    this.itemSpacing = 4,
  });

  @override
  State<DiaryEmotionSelector> createState() => _DiaryEmotionSelectorState();
}

class _DiaryEmotionSelectorState extends State<DiaryEmotionSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _animatingEmotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(String emotionName) {
    if (widget.isReadOnly) return;
    widget.onEmotionSelected?.call(emotionName);
    setState(() {
      _animatingEmotion = emotionName;
    });
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() {
          _animatingEmotion = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildEmotionOptions(),
          ),
        ),
        if (widget.showQuestionText) ...[
          const SizedBox(height: 20),
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 28.0),
              child: Text(
                widget.selectedEmotion == null
                    ? '오늘 해소할 감정은 무엇인가요?'
                    : AppImages.emotionQuestionTexts[widget.selectedEmotion]!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildEmotionOptions() {
    final children = <Widget>[];
    final entries = widget.imagePaths.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      children.add(_buildEmotionOption(entry.key, entry.value));

      if (i < entries.length - 1) {
        children.add(SizedBox(width: widget.itemSpacing));
      }
    }

    return children;
  }

  Widget _buildEmotionOption(String emotionName, String imagePath) {
    final isSelected = widget.selectedEmotion == emotionName;
    final isAnimating = _animatingEmotion == emotionName;

    final content = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:
            isSelected ? Border.all(color: Colors.white, width: 2.0) : null,
      ),
      child: _buildAssetImage(imagePath),
    );

    return GestureDetector(
      onTap: () => _handleTap(emotionName),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double translateY = isSelected ? -8.0 : 0.0;
          double rotation = 0.0;

          if (isAnimating) {
            final t = _controller.value;
            final lift = math.sin(t * math.pi) * 8.0;
            translateY = -8.0 - lift;
            rotation = math.sin(t * math.pi * 4) * 0.18 * (1 - t);
          }

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: rotation,
              child: child,
            ),
          );
        },
        child: content,
      ),
    );
  }

  Widget _buildAssetImage(String imagePath) {
    if (imagePath.endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      imagePath,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
    );
  }
}
