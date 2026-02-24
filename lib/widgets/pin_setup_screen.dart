import 'package:flutter/material.dart';
import 'thank_you_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final String nickname;

  const PinSetupScreen({
    super.key,
    required this.nickname,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  bool _isLoading = false;
  final List<TextEditingController> _pinControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _handlePinSubmit() async {
    // PIN 확인
    final pin = _pinControllers.map((c) => c.text).join();

    if (pin.length != 4) {
      _showErrorDialog('비밀번호를 설정해주세요.');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      _showErrorDialog('비밀번호는 숫자만 입력 가능합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 서버에 닉네임 + PIN 저장 API 호출
      await Future.delayed(const Duration(seconds: 1)); // 임시

      if (mounted) {
        // 감사 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ThankYouScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('설정에 실패했습니다.\n$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSkip() {
    // 건너뛰기: PIN 없이 닉네임만 저장
    // TODO: 서버에 닉네임만 저장 API 호출
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ThankYouScreen()),
    );
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

              // 비밀번호 설정 안내
              const Text(
                '앗! 네의 일기를 다른 사람들이 보는 건 곤란하죠.\n앱에 사용할 비밀번호를 입력해주세요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 14),

              // PIN 입력 박스 4개
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Container(
                    width: 79,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white12,
                        width: 1,
                      ),
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _pinControllers[index],
                      focusNode: _pinFocusNodes[index],
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          // 다음 입력 박스로 포커스 이동
                          _pinFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          // 이전 입력 박스로 포커스 이동
                          _pinFocusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 14),

              // 유효성 메시지
              const Text(
                '*비밀번호는 설정하지 않아도 괜찮아요.',
                style: TextStyle(
                  color: Color(0xFFFF9E9E),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              // 건너뛰기 + 확인 버튼
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSkip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C5C5C),
                          disabledBackgroundColor: const Color(0xFF2A2A2A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '건너뛰기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePinSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4646),
                          disabledBackgroundColor: const Color(0xFF3A3A3A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '확인',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
