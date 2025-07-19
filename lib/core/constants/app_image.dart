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
    'green': 'assets/emotion/gray_body.svg',
    // 여기에 추가될 색상 값들을 추가할 수 있습니다.
  };

  // 감정별 질문 문장 매핑
  static const Map<String, String> emotionQuestionTexts = {
    'red': '오늘은 어떤 일 때문에 화가 났나요?',
    'yellow': '어떤 일로 시무룩해졌나요? 이야기를 들려주세요.',
    'blue': '오늘 하루를 평온하게 만든 순간은 언제인가요?',
    'pink': '무엇이 당신을 슬프게 했나요? 마음을 털어놓아 보세요.',
    'green': '무엇이 당신을 기쁘게 했나요? 그 순간을 기록해 보세요.',
  };
} 