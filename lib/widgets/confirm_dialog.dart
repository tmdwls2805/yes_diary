import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- 기본: 버튼 2개 (네/아니요) ---

/// [핵심] 재사용 가능한 커스텀 확인/취소 다이얼로그
///
/// [설명]
/// 아이콘, 제목, 내용을 파라미터로 받아 다양한 다이얼로그를 표시합니다.
/// 사용자가 '네'를 누르면 `true`를, '아니요'를 누르거나 닫으면 `false` 또는 `null`을 반환합니다.
Future<bool?> showCustomConfirmDialog({
  required BuildContext context,
  required String svgAsset,
  required String title,
  required String content,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          SvgPicture.asset(
                            svgAsset,
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
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
                      Text(
                        content,
                        style: const TextStyle(
                          color: Color(0xFF535353),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
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
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text(
                            '네',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      Container(
                          width: 1, height: 50, color: Colors.grey[200]),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
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

// --- 신규: 버튼 1개 (확인) ---

/// [신규] '확인' 버튼 하나만 있는 재사용 가능한 커스텀 알림 다이얼로그
///
/// [설명]
/// 아이콘, 제목, 내용을 파라미터로 받아 정보를 표시하는 다이얼로그입니다.
Future<void> showCustomAlertDialog({
  required BuildContext context,
  required String svgAsset,
  required String title,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          SvgPicture.asset(
                            svgAsset,
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
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
                      Text(
                        content,
                        style: const TextStyle(
                          color: Color(0xFF535353),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions (버튼 1개)
                Container(
                  height: 50,
                  width: 320,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontSize: 16),
                    ),
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


// --- 특수 목적 다이얼로그들 ---

/// [신규] 삭제 확인 다이얼로그 (버튼 2개)
Future<bool?> showDeleteConfirmDialog(BuildContext context) {
  return showCustomConfirmDialog(
    context: context,
    svgAsset: 'assets/emotion/pink.svg',
    title: '정말 삭제할까요?',
    content: '삭제하신 일기는 복구할 수 없습니다.\n정말 삭제하시겠습니까?',
  );
}

/// [수정] 글쓰기 종료 확인 다이얼로그 (버튼 2개)
Future<bool?> showExitConfirmDialog(BuildContext context) {
  return showCustomConfirmDialog(
    context: context,
    svgAsset: 'assets/emotion/blue.svg',
    title: '혹시,, 너 사측이야??',
    content: '글쓰기를 취소하면 저장되지 않습니다.\n정말 취소하시겠습니까?',
  );
}

/// [신규] 일기 저장 완료 다이얼로그 (버튼 1개)
Future<void> showSaveConfirmDialog(BuildContext context) {
  return showCustomAlertDialog(
    context: context,
    svgAsset: 'assets/emotion/red.svg',
    title: '오늘도 수고했어!',
    content: '작성하신 글이 저장 되었습니다.\n캘린더에서 확인해보세요!',
  );
}