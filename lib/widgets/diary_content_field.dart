import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiaryContentField extends StatelessWidget {
  final TextEditingController controller;
  final bool isReadOnly;
  final String hintText;

  const DiaryContentField({
    Key? key,
    required this.controller,
    this.isReadOnly = false,
    this.hintText = '오늘의 일기를 작성해주세요...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF363636),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Scrollbar(
        child: TextField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: null,
          expands: true,
          maxLength: isReadOnly ? null : 2000,
          maxLengthEnforcement: isReadOnly ? MaxLengthEnforcement.none : MaxLengthEnforcement.enforced,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: isReadOnly ? '' : hintText,
            hintStyle: const TextStyle(color: Color(0xFF808080)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            counterText: isReadOnly ? '' : null,
          ),
        ),
      ),
    );
  }
}