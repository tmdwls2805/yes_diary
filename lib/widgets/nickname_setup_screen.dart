import 'package:flutter/material.dart';
import 'dart:math';
import 'pin_setup_screen.dart';

class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  // 랜덤 닉네임 생성용 단어 목록
  final List<String> _adjectives = [
    '행복한', '즐거운', '신나는', '평화로운', '차분한',
    '활발한', '귀여운', '멋진', '빛나는', '따뜻한',
    '시원한', '상쾌한', '포근한', '달콤한', '향기로운',
  ];

  final List<String> _nouns = [
    '고양이', '강아지', '토끼', '햄스터', '다람쥐',
    '펭귄', '코알라', '판다', '여우', '사슴',
    '별', '구름', '달', '해', '꽃',
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 랜덤 닉네임 생성
  void _generateRandomNickname() {
    final random = Random();
    final adjective = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    final randomNumber = random.nextInt(100);

    setState(() {
      _nicknameController.text = '$adjective$noun$randomNumber';
    });
  }

  Future<void> _handleSubmit() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      _showErrorDialog('닉네임을 입력해주세요.');
      return;
    }

    if (nickname.length < 2 || nickname.length > 10) {
      _showErrorDialog('닉네임은 2~10자로 입력해주세요.');
      return;
    }

    // PIN 설정 화면으로 이동
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(nickname: nickname),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '오류',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFFEE500),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 뒤로가기 버튼
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(height: 12),

              // 환영 메시지
              const Text(
                '앗! 네의 일기에\n가입해주셔서 감사해요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 49),

              const Text(
                '앗! 네의 일기에서 사용하실 닉네임을 알려주세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 14),

              // 닉네임 입력 필드 (테두리 박스 스타일)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white12,
                    width: 1,
                  ),
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _nicknameController,
                  enabled: !_isLoading,
                  maxLength: 10,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: '닉네임',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    counterText: '',
                    suffixIcon: GestureDetector(
                      onTap: _generateRandomNickname,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 24.0),
                        child: Image.asset(
                          'assets/icon/dice.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),

              const SizedBox(height: 14),

              // 유효성 메시지
              const Text(
                '*닉네임 정하기 어렵다면 주사위로 정해보세요.',
                style: TextStyle(
                  color: Color(0xFFFF9E9E),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              // 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4646),
                    disabledBackgroundColor: const Color(0xFF3A3A3A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '이 닉네임 사용하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
