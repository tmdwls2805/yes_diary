# 다국어 지원 가이드 (Localization Guide)

이 프로젝트는 `easy_localization` 패키지를 사용하여 다국어를 지원합니다.

## 지원 언어

- 🇰🇷 한국어 (기본)
- 🇺🇸 영어
- 🇯🇵 일본어
- 🇨🇳 중국어

## 파일 구조

```
assets/translations/
├── ko.json  # 한국어
├── en.json  # 영어
├── ja.json  # 일본어
└── zh.json  # 중국어
```

## 사용법

### 1. 텍스트 번역하기

#### 방법 1: `.tr()` 사용 (추천)
```dart
Text('home.work'.tr())
```

#### 방법 2: `context.tr()` 사용
```dart
Text(context.tr('home.work'))
```

### 2. 언어 변경하기

```dart
// 영어로 변경
await context.setLocale(Locale('en', 'US'));

// 일본어로 변경
await context.setLocale(Locale('ja', 'JP'));

// 중국어로 변경
await context.setLocale(Locale('zh', 'CN'));

// 한국어로 변경
await context.setLocale(Locale('ko', 'KR'));
```

### 3. 현재 언어 확인

```dart
Locale currentLocale = context.locale;
print('현재 언어: ${currentLocale.languageCode}');
```

### 4. 기기 언어 사용

```dart
await context.setLocale(context.deviceLocale);
```

## 번역 추가하기

### 1. JSON 파일에 번역 키 추가

각 언어 파일에 동일한 키로 번역을 추가합니다.

**ko.json:**
```json
{
  "home": {
    "work": "근무",
    "greeting": "안녕하세요"
  }
}
```

**en.json:**
```json
{
  "home": {
    "work": "Work",
    "greeting": "Hello"
  }
}
```

### 2. 코드에서 사용

```dart
Text('home.greeting'.tr())
```

## 매개변수가 있는 번역

### JSON 파일:
```json
{
  "welcome_message": "안녕하세요, {}님!"
}
```

### 코드:
```dart
Text('welcome_message'.tr(args: ['홍길동']))
// 결과: 안녕하세요, 홍길동님!
```

## 복수형 처리

### JSON 파일:
```json
{
  "items_count": {
    "zero": "항목 없음",
    "one": "1개 항목",
    "other": "{}개 항목"
  }
}
```

### 코드:
```dart
Text('items_count'.plural(5))
// 결과: 5개 항목
```

## 언어 선택 UI 예시

```dart
DropdownButton<Locale>(
  value: context.locale,
  items: [
    DropdownMenuItem(
      value: Locale('ko', 'KR'),
      child: Text('🇰🇷 한국어'),
    ),
    DropdownMenuItem(
      value: Locale('en', 'US'),
      child: Text('🇺🇸 English'),
    ),
    DropdownMenuItem(
      value: Locale('ja', 'JP'),
      child: Text('🇯🇵 日本語'),
    ),
    DropdownMenuItem(
      value: Locale('zh', 'CN'),
      child: Text('🇨🇳 中文'),
    ),
  ],
  onChanged: (Locale? newLocale) {
    if (newLocale != null) {
      context.setLocale(newLocale);
    }
  },
)
```

## 주의사항

1. **모든 언어 파일에 동일한 키가 있어야 합니다**
   - 한 언어에만 키가 있으면 다른 언어에서 오류가 발생할 수 있습니다.

2. **중첩된 키 사용**
   - `home.work`와 같이 `.`으로 구분하여 중첩된 키를 사용할 수 있습니다.

3. **Hot Reload**
   - JSON 파일 변경 후에는 앱을 재시작해야 합니다 (Hot Reload로는 반영 안 됨).

4. **fallbackLocale**
   - 번역이 없는 경우 한국어(ko)로 폴백됩니다.

## 기존 텍스트를 번역으로 교체하는 방법

### Before:
```dart
Text('근무')
```

### After:
```dart
import 'package:easy_localization/easy_localization.dart';

Text('home.work'.tr())
```

## 번역 파일에 없는 키 처리

번역 키가 없으면 키 자체가 표시됩니다. 예:
```dart
'non_existent_key'.tr()
// 결과: "non_existent_key"
```

## 도움말

- [easy_localization 공식 문서](https://pub.dev/packages/easy_localization)
- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
