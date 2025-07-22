# 앗! 네의 일기

# 남은 할 일 
- 온보딩, 스플래시, 아이콘, 마이 페이지, 로그인
- 전화번호 로그인
- 로그인 시 데이터 sqlite3에서 postgresql로 마이그레이션
- 일기 많이 썼을때 로딩 덜 되게 효율성 (hive, shared_reference 알아보기)

# 우선순위
- 가입한 날짜의 달부터 나오는 dropdown
- 일기 작성 취소 시 다이얼로그
- 일기 디테일 화면
- 일기 쓰지 않았음 화면
- 일기 수정
- 일기 삭제
- 일기 스와이프 동작 (가입한 날짜의 달 1일부터 현재 날짜) (이전으로 스와이프 동작 못함)
- 현재 날짜 이후의 달 캘린더 보이지 않기

# Android 네비게이션 바 뒤로가기 고려사항
- 마지막은 항상 main_screen 
- main_screen에서 toast message 나오며 "한번 더 누르면 앱이 종료됩니다." 하단에 위치 (2초 안에 두번 클릭 시 앱 종료)


# sqlite3 현재 구조
user - id, created_at
diary - date, emotion(red, yellow 색이 들어감), content


# 요청
- 저장 취소 다이얼로그 flow 변경
- green에 대한 몸통까지 있는 디자인
- 