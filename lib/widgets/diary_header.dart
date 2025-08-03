import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryHeader extends StatelessWidget implements PreferredSizeWidget {
  final DateTime selectedDate;
  final String leftButtonText;
  final String? rightButtonText;
  final Widget? rightButtonWidget;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;
  final Color? rightButtonColor;
  final FontWeight? rightButtonFontWeight;

  const DiaryHeader({
    Key? key,
    required this.selectedDate,
    required this.leftButtonText,
    this.rightButtonText,
    this.onLeftPressed,
    this.onRightPressed,
    this.rightButtonColor,
    this.rightButtonFontWeight,
    this.rightButtonWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 24.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: TextButton(
            onPressed: onLeftPressed ?? () => Navigator.pop(context),
            child: Text(
              leftButtonText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          title: Text(
            DateFormat('yyyy.MM.dd').format(selectedDate),
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.bold
            ),
          ),
          centerTitle: true,
          actions: [
            if (rightButtonWidget != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(child: rightButtonWidget!),
              )
            else if (rightButtonText != null)
              TextButton(
                onPressed: onRightPressed,
                child: Text(
                  rightButtonText!,
                  style: TextStyle(
                    color: rightButtonColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: rightButtonFontWeight ?? FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24.0);
}