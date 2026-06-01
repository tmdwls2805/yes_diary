import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'thank_you_screen.dart';
import '../core/services/storage/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../providers/user_provider.dart';
import '../providers/diary_provider.dart';
import 'app_wrapper.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  final String nickname;
  final String? kakaoAccessToken;

  const PinSetupScreen({
    super.key,
    required this.nickname,
    this.kakaoAccessToken,
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  bool _isLoading = false;
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  final AuthService _authService = AuthService();

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
      _showErrorDialog('auth.error_password_required'.tr());
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      _showErrorDialog('auth.error_password_numeric'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // kakaoAccessToken이 없으면 (애플 로그인 등) 바로 감사 화면으로 이동
      if (widget.kakaoAccessToken == null) {
        print('임시: 카카오 토큰 없이 진행 (애플 로그인 등)');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ThankYouScreen()),
          );
        }
        return;
      }

      final localUserId = ref.read(userProvider).userId;
      final onboardingProfile =
          await SecureStorageService().getOnboardingProfile();
      final signupNickname = onboardingProfile['nickname'] ?? widget.nickname;

      // 서버에 닉네임 + PIN으로 회원가입
      print('회원가입 시도: nickname=$signupNickname, password=$pin');
      final result = await _authService.signupWithKakao(
        accessToken: widget.kakaoAccessToken!,
        nickname: signupNickname,
        password: pin,
        department: onboardingProfile['department'],
        workStartTime: onboardingProfile['startTime'],
        workEndTime: onboardingProfile['endTime'],
        onboardingEmotion: onboardingProfile['emotion'],
      );

      await _completeSignup(result, localUserId);
    } catch (e) {
      print('회원가입 실패: $e');
      if (mounted) {
        _showErrorDialog('${'auth.error_signup_failed'.tr()}\n$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSkip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // kakaoAccessToken이 없으면 (애플 로그인 등) 바로 감사 화면으로 이동
      if (widget.kakaoAccessToken == null) {
        print('임시: 카카오 토큰 없이 건너뛰기 (애플 로그인 등)');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ThankYouScreen()),
          );
        }
        return;
      }

      final localUserId = ref.read(userProvider).userId;
      final onboardingProfile =
          await SecureStorageService().getOnboardingProfile();
      final signupNickname = onboardingProfile['nickname'] ?? widget.nickname;

      // 건너뛰기: PIN 없이 닉네임만으로 회원가입
      print('회원가입 시도 (PIN 없이): nickname=$signupNickname');
      final result = await _authService.signupWithKakao(
        accessToken: widget.kakaoAccessToken!,
        nickname: signupNickname,
        department: onboardingProfile['department'],
        workStartTime: onboardingProfile['startTime'],
        workEndTime: onboardingProfile['endTime'],
        onboardingEmotion: onboardingProfile['emotion'],
      );

      await _completeSignup(result, localUserId);
    } catch (e) {
      print('회원가입 실패: $e');
      if (mounted) {
        _showErrorDialog('${'auth.error_signup_failed'.tr()}\n$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeSignup(
    Map<String, dynamic> tokens,
    String? localUserId,
  ) async {
    final user = tokens['user'];

    await TokenService.saveTokens(
      accessToken: tokens['accessToken'],
      refreshToken: tokens['refreshToken'],
      userInfo: {
        'id': user['id'],
        'nickname': user['nickname'],
        'provider': user['provider'],
        if (user['createdAt'] != null) 'createdAt': user['createdAt'],
        if (user['updatedAt'] != null) 'updatedAt': user['updatedAt'],
        if (user['department'] != null) 'department': user['department'],
        if (user['workStartTime'] != null)
          'workStartTime': user['workStartTime'],
        if (user['workEndTime'] != null) 'workEndTime': user['workEndTime'],
        if (user['onboardingEmotion'] != null)
          'onboardingEmotion': user['onboardingEmotion'],
      },
    );

    print('회원가입 완료: ${user['nickname']}');

    final userId = user['id'].toString();
    await ref.read(userProvider.notifier).saveUserId(userId);
    if (user['createdAt'] != null) {
      await ref
          .read(userProvider.notifier)
          .saveCreatedAt(DateTime.parse(user['createdAt']));
    }

    var shouldSync = false;
    if (localUserId != null) {
      final hasLocalDiaries =
          await ref.read(diaryProvider.notifier).hasLocalDiaries(localUserId);
      if (hasLocalDiaries && mounted) {
        shouldSync = await _showDiarySyncDialog();
      }
    }

    if (shouldSync && localUserId != null) {
      await ref
          .read(diaryProvider.notifier)
          .syncLocalDiariesToServer(localUserId);
    }

    await ref.read(diaryProvider.notifier).clearLocalDiaries();

    final now = DateTime.now();
    await ref.read(diaryProvider.notifier).fetchAndSaveMonthlyDiaries(
          now.year,
          now.month,
          userId,
        );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AppWrapper(initialIndex: 1),
      ),
      (route) => false,
    );
  }

  Future<bool> _showDiarySyncDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '로컬 일기를 동기화할까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '이전에 로그인 없이 작성한 일기를 계정에 저장하시겠습니까?\n아니요를 선택하면 로컬 일기는 삭제됩니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '아니요',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '예',
                style: TextStyle(
                  color: Color(0xFFFF4646),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
          title: Text(
            'common.error'.tr(),
            style: const TextStyle(
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
              child: Text(
                'common.ok'.tr(),
                style: const TextStyle(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.062),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.024),

              // 뒤로가기 버튼
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: screenWidth * 0.062,
                ),
              ),

              SizedBox(height: screenHeight * 0.014),

              // 환영 메시지
              Text(
                'auth.welcome'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.062,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),

              SizedBox(height: screenHeight * 0.058),

              // 비밀번호 설정 안내
              Text(
                'auth.password_prompt'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.041,
                ),
              ),

              SizedBox(height: screenHeight * 0.017),

              // PIN 입력 박스 4개
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Container(
                    width: screenWidth * 0.203,
                    height: screenHeight * 0.066,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.062,
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

              SizedBox(height: screenHeight * 0.017),

              // 유효성 메시지
              Text(
                'auth.password_skip_hint'.tr(),
                style: TextStyle(
                  color: const Color(0xFFFF9E9E),
                  fontSize: screenWidth * 0.031,
                ),
              ),

              SizedBox(height: screenHeight * 0.017),

              // 건너뛰기 + 확인 버튼
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: screenHeight * 0.066,
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
                        child: Text(
                          'auth.skip'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.041,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.031),
                  Expanded(
                    child: SizedBox(
                      height: screenHeight * 0.066,
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
                            ? SizedBox(
                                width: screenWidth * 0.062,
                                height: screenWidth * 0.062,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'auth.confirm'.tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.041,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.047),
            ],
          ),
        ),
      ),
    );
  }
}
