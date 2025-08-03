import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 앱 전역에서 사용할 수 있는 확인/취소 다이얼로그를 표시합니다.
///
/// 사용자가 '네'를 누르면 `true`를, '아니요'를 누르거나 닫으면 `false` 또는 `null`을 반환합니다.
Future<bool?> showExitConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: Container(
            width: 320,
            // [MODIFIED] 좌우 패딩을 제거하여 구분선이 끝까지 닿도록 함
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [MODIFIED] 제목과 내용 컨텐츠에만 좌우 패딩을 적용
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Title
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/emotion/blue.svg',
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '혹시,, 너 사측이야??',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Content
                      const Text(
                        '글쓰기를 취소하면 저장되지 않습니다.\n정말로 취소하겠습니까?',
                        style: TextStyle(
                          color: Color(0xFF535353),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions
                Container(
                  height: 50,
                  width: 320,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          // [MODIFIED] 버튼 텍스트 크기를 16으로 변경
                          child: const Text(
                            '네',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey[200]),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          // [MODIFIED] 버튼 텍스트 크기를 16으로 변경
                          child: const Text(
                            '아니요',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
