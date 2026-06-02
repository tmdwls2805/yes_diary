import 'package:flutter/material.dart';

class AppImages {
  // 감정 이모티콘 SVG 경로 매핑
  static const Map<String, String> emotionFaceSvgPaths = {
    'red': 'assets/emotion/red.svg',
    'yellow': 'assets/emotion/yellow.svg',
    'blue': 'assets/emotion/blue.svg',
    'pink': 'assets/emotion/pink.svg',
    'green': 'assets/emotion/green.svg',
    // 여기에 추가될 색상 값들을 추가할 수 있습니다.
  };

  static const Map<String, String> emotionBlockImagePaths = {
    'red': 'assets/emotion/red_block.png',
    'yellow': 'assets/emotion/yellow_block.png',
    'blue': 'assets/emotion/blue_block.png',
    'pink': 'assets/emotion/pink_block.png',
    'green': 'assets/emotion/green_block.png',
  };

  static const Map<String, String> emotiongrayFaceSvgPaths = {
    'red': 'assets/emotion/red_gray.svg',
    'yellow': 'assets/emotion/yellow_gray.svg',
    'blue': 'assets/emotion/blue_gray.svg',
    'pink': 'assets/emotion/pink_gray.svg',
    'green': 'assets/emotion/green_gray.svg',
    // 여기에 추가될 색상 값들을 추가할 수 있습니다.
  };

  static const Map<String, String> emotionBodySvgPaths = {
    'red': 'assets/emotion/red_body.svg',
    'yellow': 'assets/emotion/yellow_body.svg',
    'blue': 'assets/emotion/blue_body.svg',
    'pink': 'assets/emotion/pink_body.svg',
    'green': 'assets/emotion/green_body.svg',
    // 여기에 추가될 색상 값들을 추가할 수 있습니다.
  };

  // 감정별 카드 이미지
  static const Map<String, String> emotionCardImagePaths = {
    'red': 'assets/emotion/red_card.png',
    'yellow': 'assets/emotion/yellow_card.png',
    'blue': 'assets/emotion/blue_card.png',
    'pink': 'assets/emotion/pink_card.png',
    'green': 'assets/emotion/green_card.png',
  };

  // 감정별 라벨 (이모지 포함)
  static const Map<String, String> emotionLabels = {
    'red': '화 🔥',
    'yellow': '기쁨 🥳',
    'blue': '황당 😰',
    'pink': '슬픔 💧',
    'green': '체념 😮‍💨',
  };

  // 감정별 색상
  static const Map<String, Color> emotionColors = {
    'red': Color(0xFFFF4646),
    'yellow': Color(0xFFFFCE6D),
    'blue': Color(0xFFB4E9FF),
    'pink': Color(0xFFFFB4D3),
    'green': Color(0xFF8CE3C0),
  };

  // 감정별 질문 문장 매핑
  static const Map<String, String> emotionQuestionTexts = {
    'red': "아휴 가'족'같은 회사🤬",
    'yellow': '산은 산이고 물은 물이로다⛰️',
    'blue': '네?? 제가 해요??',
    'pink': '안죄송해서 죄송해요🥹',
    'green': '네네~ 맘~~대로 하세여',
  };

  // 감정 카드 위에 표시되는 문구
  static const Map<String, String> emotionCardTexts = {
    'red': "아휴 가'족'\n같은 회사🤬",
    'yellow': '오늘은\n나의 날🥳',
    'blue': '네?? 제가 해요??',
    'pink': '안죄송해서\n죄송해요🥹',
    'green': '그러를 그러세요ㅎ',
  };
}
