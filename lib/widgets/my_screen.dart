import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'nickname_setup_screen.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;
  int _speechBubbleDirection = 0;
  double _currentRotation = -90.0; // 누적 회전 각도 (시작: -90도)
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1초마다 말풍선 방향을 시계 반대방향으로 회전
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _speechBubbleDirection = (_speechBubbleDirection + 1) % 5;
        _currentRotation -= 72.0; // 무조건 시계 반대방향으로 72도씩 회전
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// 카카오 로그인 처리
  Future<void> _handleKakaoLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 카카오톡 설치 여부 확인 후 로그인
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공: ${token.accessToken}');
        } catch (error) {
          print('카카오톡으로 로그인 실패: $error');

          // 카카오톡 로그인 실패 시 카카오계정으로 로그인 시도
          if (mounted) {
            token = await UserApi.instance.loginWithKakaoAccount();
            print('카카오계정으로 로그인 성공: ${token.accessToken}');
          } else {
            return;
          }
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공: ${token.accessToken}');
      }

      // 2. 서버에 사용자 존재 여부 확인 및 로그인
      print('서버에 사용자 확인 요청 중... Token: ${token.accessToken.substring(0, 20)}...');
      final result = await _authService.checkKakaoUser(token.accessToken);
      print('서버 응답: $result');

      final bool isExistingUser = result['existingUser'] ?? false;

      if (isExistingUser && result['tokens'] != null) {
        // 3-1. 기존 사용자: 토큰 저장 및 자동 로그인
        final tokens = result['tokens'];
        final user = tokens['user'];

        await TokenService.saveTokens(
          accessToken: tokens['accessToken'],
          refreshToken: tokens['refreshToken'],
          userInfo: {
            'id': user['id'],
            'nickname': user['nickname'],
            'provider': user['provider'],
            'createdAt': user['createdAt'],
            'updatedAt': user['updatedAt'],
          },
        );

        print('자동 로그인 완료: ${user['nickname']}');

        if (mounted) {
          _showUserCheckDialog(true, nickname: user['nickname']);
        }
      } else {
        // 3-2. 신규 사용자: 닉네임 설정 화면으로 이동
        final kakaoInfo = result['kakaoInfo'];
        if (kakaoInfo != null) {
          print('신규 사용자 - socialId: ${kakaoInfo['socialId']}');
        } else {
          print('신규 사용자');
        }

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NicknameSetupScreen(),
            ),
          );
        }
      }
    } catch (error) {
      print('카카오 로그인 실패: $error');
      if (mounted) {
        String errorMessage = '로그인 중 오류가 발생했습니다.';

        if (error.toString().contains('bundleId validation failed')) {
          errorMessage = 'iOS Bundle ID 설정 오류\n\n'
              '카카오 개발자 콘솔에서 다음을 확인해주세요:\n'
              '1. 플랫폼 설정 > iOS\n'
              '2. Bundle ID: com.example.yesDiary\n\n'
              '등록되어 있는지 확인해주세요.';
        } else if (error.toString().contains('서버 오류: 500')) {
          errorMessage = '서버 오류가 발생했습니다.\n\n'
              '백엔드 서버가 실행 중인지 확인해주세요.\n'
              'URL: http://localhost:8080/api/auth/kakao/check\n\n'
              '서버 로그를 확인하여 오류 원인을\n파악해주세요.';
        } else if (error.toString().contains('네트워크 오류')) {
          errorMessage = '네트워크 연결 오류\n\n'
              '서버가 실행 중인지 확인해주세요.\n'
              'localhost:8080이 정상적으로\n접근 가능한지 확인해주세요.';
        } else {
          errorMessage += '\n\n상세 정보:\n$error';
        }

        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 사용자 확인 다이얼로그 표시
  void _showUserCheckDialog(bool existingUser, {String? nickname}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existingUser ? '로그인 성공' : '환영합니다!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            existingUser
                ? '환영합니다, ${nickname ?? '사용자'}님!\n자동 로그인되었습니다.'
                : '앗! 네의 일기에 가입해주셔서 감사해요.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 기존 사용자면 메인 화면으로, 신규 사용자면 닉네임 설정 화면으로 이동
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

  /// 에러 다이얼로그 표시
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
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 0),
          child: Column(
            children: [
              // 상단 스와이프 가능한 콘텐츠 영역
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildFirstContent(),
                    _buildSecondContent(),
                  ],
                ),
              ),

              // 하단 고정 영역 (인디케이터 + 버튼)
              Column(
                children: [
                  // 첫 번째 페이지일 때만 보이는 안내 텍스트
                  if (_currentPage == 0) ...[
                    const Text(
                      '로그인하면 일기를\n영구 저장할 수 있어요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 두 번째 페이지일 때만 보이는 안내 텍스트
                  if (_currentPage == 1) ...[
                    const Text(
                      '퇴사 생각나신다고요?\n감쓰 리포트를 확인해 보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 인디케이터
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _currentPage == 0 ? 'assets/icon/indicate_active.png' : 'assets/icon/indicate_inactive.png',
                          width: 8,
                          height: 8,
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          _currentPage == 1 ? 'assets/icon/indicate_active.png' : 'assets/icon/indicate_inactive.png',
                          width: 8,
                          height: 8,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 카카오 로그인 버튼
                  Center(
                    child: SizedBox(
                      width: 358,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleKakaoLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icon/Kakao.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '카카오로 시작하기',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 애플 로그인 버튼
                  Center(
                    child: SizedBox(
                      width: 358,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 애플 로그인 구현
                          print('애플 로그인 버튼 클릭');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/Apple.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Apple로 시작하기',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstContent() {
    return Align(
      alignment: const Alignment(0, 0.70), // 위로 올려서 글씨와 가깝게
      child: SizedBox(
        width: 400,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 원형 오각형 형태로 SVG 배치
            _buildCircularEmotionIcon('assets/emotion/red.svg', 0),
            _buildCircularEmotionIcon('assets/emotion/blue.svg', 1),
            _buildCircularEmotionIcon('assets/emotion/green.svg', 2),
            _buildCircularEmotionIcon('assets/emotion/pink.svg', 3),
            _buildCircularEmotionIcon('assets/emotion/yellow.svg', 4),

            // 가운데 말풍선
            _buildSpeechBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularEmotionIcon(String assetPath, int index) {
    // 오각형 배치: 360도를 5로 나눔 (72도씩)
    // 맨 위부터 시작 (-90도)하여 시계방향으로 배치
    const angle = -90;
    final currentAngle = angle + (index * 72);
    final radians = currentAngle * math.pi / 180;
    const radius = 110.0; // 중심으로부터의 거리 (서로 더 띄움)

    final x = radius * math.cos(radians);
    final y = radius * math.sin(radians);

    return Transform.translate(
      offset: Offset(x, y),
      child: SvgPicture.asset(
        assetPath,
        width: 90,
        height: 90,
      ),
    );
  }

  Widget _buildSecondContent() {
    return Column(
      children: [
        const Spacer(flex: 2),

        // 상단 텍스트
        const Text(
          '앗 네! 현황',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 40),

        // 감정 아이콘 + 그라데이션 (3개)
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 감정 아이콘 세로 배열 + 회수 텍스트
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 첫 번째 아이콘 (약간 작게)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/emotion/yellow.svg',
                        width: 75,
                        height: 75,
                      ),
                      const SizedBox(width: 64),
                      const Text(
                        '8회',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 두 번째 아이콘 (약간 크게)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/emotion/red.svg',
                        width: 85,
                        height: 85,
                      ),
                      const SizedBox(width: 80),
                      const Text(
                        '17회',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 세 번째 아이콘 (약간 작게)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/emotion/green.svg',
                        width: 75,
                        height: 75,
                      ),
                      const SizedBox(width: 64),
                      const Text(
                        '6회',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 그라데이션 오버레이 (위아래 모두 어두움, 중간은 투명)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A1A1A),           // 위쪽 어두움
                        Color(0xB31A1A1A),           // alpha: 0.7
                        Color(0x4D1A1A1A),           // alpha: 0.3
                        Colors.transparent,          // 중간 투명
                        Color(0x4D1A1A1A),           // alpha: 0.3
                        Color(0xB31A1A1A),           // alpha: 0.7
                        Color(0xFF1A1A1A),           // 아래쪽 어두움
                      ],
                      stops: [0.0, 0.1, 0.2, 0.5, 0.7, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildSpeechBubble() {
    // 각 방향에 따른 메시지
    final messages = [
      '앗 네!',      // red
      '네.....',     // yellow
      '네ㅜㅜ',      // pink
      'ㅎ네ㅎ',      // green
      '네?????',     // blue
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // 말풍선 본체 (고정)
        CustomPaint(
          size: const Size(80, 50),
          painter: _SpeechBubbleBodyPainter(),
        ),
        // 말풍선 꼬리 (회전) - 누적 각도로 무조건 시계 반대방향으로 회전
        AnimatedRotation(
          turns: _currentRotation / 360,
          duration: const Duration(milliseconds: 300),
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _SpeechBubbleTailPainter(),
          ),
        ),
        // 말풍선 안의 텍스트 (고정)
        Text(
          messages[_speechBubbleDirection],
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// 말풍선 본체를 그리는 커스텀 페인터 (고정)
class _SpeechBubbleBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 둥근 사각형 본체
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 말풍선 꼬리를 그리는 커스텀 페인터 (회전)
class _SpeechBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 삼각형 꼬리 (말풍선 본체 안쪽에서 시작하여 틈 없이)
    final trianglePath = Path();
    // 말풍선 본체 안쪽에서 시작 (겹치도록)
    trianglePath.moveTo(centerX - 10, centerY - 15);  // 왼쪽 (본체 안쪽)
    trianglePath.lineTo(centerX, centerY - 55);       // 꼭짓점 (위쪽으로 길게)
    trianglePath.lineTo(centerX + 10, centerY - 15);  // 오른쪽 (본체 안쪽)
    trianglePath.close();

    canvas.drawPath(trianglePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
