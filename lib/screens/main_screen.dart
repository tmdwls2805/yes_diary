import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';
import 'package:yes_diary/widgets/my_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'dart:async'; // Import Timer
import 'dart:math'; // Import Random
import 'package:flutter/services.dart'; // Import HapticFeedback

class MainScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _clickCount = 0;
  double _fillPercentage = 0.0;
  Timer? _decayTimer; // Timer for gradual decrease
  Timer? _slowDecayTimer; // 8초 후 천천히 줄어드는 타이머
  List<ParticleModel> _particles = []; // 파티클 리스트
  bool _isBurning = false; // 100% 도달 시 불타는 효과 상태
  Timer? _burningTimer; // 불타는 효과용 타이머
  Timer? _particleCleanupTimer; // 파티클 정리용 타이머 (배치 처리)
  late AnimationController _pulseController; // 펄스 애니메이션 컨트롤러
  late Animation<double> _pulseAnimation;
  bool _showFlash = false; // 화면 플래시 효과

  @override
  void initState() {
    super.initState();
    _startDecayTimer(); // Start the decay timer
    _startParticleCleanup(); // 파티클 배치 정리 시작

    // 펄스 애니메이션 초기화
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _slowDecayTimer?.cancel();
    _burningTimer?.cancel();
    _particleCleanupTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startDecayTimer() {
    _decayTimer?.cancel(); // Cancel any existing timer
    _decayTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_clickCount > 0 && !_isBurning) {
        setState(() {
          _clickCount = (_clickCount - 1).clamp(0, 100);
          _fillPercentage = _clickCount / 100.0;
        });
      } else {
        _decayTimer?.cancel(); // Stop timer if fill is empty
      }
    });
  }

  // 파티클 배치 정리 타이머 시작 (성능 최적화)
  void _startParticleCleanup() {
    _particleCleanupTimer?.cancel();
    // 50ms마다 만료된 파티클을 배치로 정리 (setState 한 번만 호출)
    _particleCleanupTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final initialLength = _particles.length;

      // 1800ms 이상 된 파티클 제거
      _particles.removeWhere((particle) {
        final age = now.difference(particle.createdAt).inMilliseconds;
        return age >= 1800;
      });

      // 파티클이 제거되었을 때만 setState 호출
      if (_particles.length != initialLength && mounted) {
        setState(() {});
      }
    });
  }

  // 100% 도달 시 5초 동안 불타는 효과
  void _startBurningEffect() {
    // 이미 불타는 중이면 무시
    if (_isBurning) return;

    // 진동 효과
    HapticFeedback.heavyImpact();

    setState(() {
      _isBurning = true;
      _showFlash = true;
    });

    // 펄스 애니메이션 반복 시작
    _pulseController.repeat(reverse: true);

    // 즉시 첫 파티클 생성
    _createParticles();

    // 화면 플래시 효과 (깜빡임)
    _flashScreen();

    // 파티클을 계속 생성하는 타이머 (5ms마다 생성 - 미친듯한 연속성!!!)
    _burningTimer = Timer.periodic(const Duration(milliseconds: 5), (timer) {
      _createParticles();
      // 주기적으로 진동
      if (timer.tick % 100 == 0) {
        HapticFeedback.mediumImpact();
      }
    });

    // 8초 후 효과 종료 (더 길게!)
    Future.delayed(const Duration(seconds: 8), () {
      _burningTimer?.cancel();
      _pulseController.stop();
      _pulseController.reset();

      if (mounted) {
        setState(() {
          _isBurning = false;
          _showFlash = false;
        });

        // 천천히 줄어들게 (3초 동안)
        _startSlowDecay();
      }
    });
  }

  // 3초 동안 천천히 100에서 0으로 줄어들게
  void _startSlowDecay() {
    // 기존 타이머들 정리
    _slowDecayTimer?.cancel();
    _decayTimer?.cancel();

    const totalDuration = 3000; // 3초
    const interval = 30; // 30ms 간격
    const steps = totalDuration ~/ interval; // 100 스텝
    int currentStep = 0;

    _slowDecayTimer = Timer.periodic(const Duration(milliseconds: interval), (timer) {
      currentStep++;
      if (currentStep >= steps || !mounted) {
        timer.cancel();
        _slowDecayTimer = null;
        if (mounted) {
          setState(() {
            _clickCount = 0;
            _fillPercentage = 0.0;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _fillPercentage = (1.0 - (currentStep / steps)).clamp(0.0, 1.0);
          _clickCount = (_fillPercentage * 100).round();
        });
      }
    });
  }

  // 화면 플래시 효과
  void _flashScreen() {
    int flashCount = 0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (flashCount >= 10 || !_isBurning) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _showFlash = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _showFlash = !_showFlash;
        });
      }
      flashCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);

    return PopScope(
      canPop: false, // Disable default pop behavior
      onPopInvoked: (didPop) {
        if (didPop) return; // If the system is already handling the pop, do nothing
        if (_selectedIndex == 1) {
          setState(() {
            _selectedIndex = 0; // Navigate to the Calendar tab
          });
        } else {
          // Let the CustomCalendar handle its own PopScope for app exit
          // The CustomCalendar has its own PopScope to handle app exit on double-tap
          // No explicit pop needed here, as the CustomCalendar's PopScope will be triggered.
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: _buildBody(),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(
              top: BorderSide(
                color: Color(0xFF3F3F3F),
                width: 1.0,
              ),
            ),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _selectedIndex == 0
                      ? SvgPicture.asset('assets/icon/menu_diary_active.svg', width: 24, height: 24)
                      : SvgPicture.asset('assets/icon/menu_diary_inactive.svg', width: 24, height: 24),
                ),
                label: '일기',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _selectedIndex == 1
                      ? SvgPicture.asset('assets/icon/menu_my_active.svg', width: 24, height: 24)
                      : SvgPicture.asset('assets/icon/menu_my_inactive.svg', width: 24, height: 24),
                ),
                label: '마이',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.red,
            unselectedItemColor: const Color(0xFF808080),
            onTap: _onItemTapped,
            backgroundColor: Colors.black,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontSize: 10.0, height: 1.0),
            unselectedLabelStyle: const TextStyle(fontSize: 10.0, height: 1.0),
            iconSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final userData = ref.watch(userProvider);

    // 마이 탭이 선택된 경우
    if (_selectedIndex == 1) {
      return const MyScreen();
    }

    // 일기 탭 (기본)
    return Stack(
      children: [
        Column(
          children: [
            Flexible(
              child: userData.userId == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : CustomCalendar(
                        initialDate: userData.createdAt,
                      ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 불타는 효과 배경 (버튼 뒤)
                  if (_isBurning)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: FireBackgroundPainter(
                              animation: _pulseController.value,
                            ),
                          );
                        },
                      ),
                    ),

                  // 버튼
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isBurning ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: double.infinity,
                          height: 50.0,
                          decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34.0),
                      border: Border.all(
                        color: _isBurning ? const Color(0xFFFF4400) : const Color(0x14FF0000),
                        width: _isBurning ? 2.0 : 1.0,
                      ),
                      boxShadow: _isBurning ? [
                        BoxShadow(
                          color: const Color(0xFFFF4400).withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFAA00).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ] : null,
                    ),
                    child: ClipRRect( // Clip the Stack to match the parent Container's rounded corners
                      borderRadius: BorderRadius.circular(34.0),
                      child: Stack(
                        children: [
                      // AnimatedContainer as the background fill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: _fillPercentage * (MediaQuery.of(context).size.width - 32.0), // Subtract horizontal padding
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: _isBurning ? const Color(0xFFFF4400) : const Color(0xFFE22200), // 불타는 중일 때 더 밝은 색
                          boxShadow: _isBurning ? [
                            BoxShadow(
                              color: const Color(0xFFFF4400).withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ] : null,
                        ),
                      ),
                      SizedBox.expand( // Ensures ElevatedButton takes full available size
                        child: ElevatedButton(
                          onPressed: _isBurning ? null : () {
                            setState(() {
                              _clickCount = (_clickCount + 1).clamp(0, 100); // Cap clicks at 100
                              _fillPercentage = _clickCount / 100.0;
                              print('Click count: $_clickCount, Fill percentage: $_fillPercentage');
                            });

                            // 100에 도달하면 불타는 효과 시작
                            if (_clickCount >= 100 && !_isBurning) {
                              _startBurningEffect();
                            } else {
                              _startDecayTimer(); // Restart or ensure timer is running on click
                              _createParticles(); // 100 미만일 때만 일반 파티클 생성
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Make button transparent to show fill
                            elevation: 0, // Remove shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(34.0), // Keep this for visual shape if needed
                            ),
                            side: BorderSide.none, // Remove the side from ElevatedButton
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '🔥 ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '퇴사',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '하고 싶을 때 누르는 버튼',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SvgPicture.asset(
                                'assets/emotion/red.svg',
                                width: 40, // Adjusted SVG size
                                height: 40, // Adjusted SVG size
                              ),
                            ],
                          ),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      // 파티클들 표시
      ..._particles.map((particle) => FireParticle(particle: particle)),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 파티클 생성 메서드
  void _createParticles() {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 버튼의 대략적인 Y 위치 (화면 하단 근처)
    final buttonY = screenHeight - 150.0;

    // 불타는 중일 때는 더 많이, 일반일 때는 적게
    final particleCount = _isBurning
        ? random.nextInt(16) + 30  // 30-45개 (불타는 중 - 지옥불!!!)
        : random.nextInt(5) + 8;  // 8-12개 (일반)

    // 완전히 고유한 ID 생성 및 생성 시간 기록
    final now = DateTime.now();
    final baseId = now.microsecondsSinceEpoch;

    final newParticles = <ParticleModel>[];

    for (int i = 0; i < particleCount; i++) {
      // 완전히 고유한 ID 생성
      final particleId = baseId * 1000 + i;

      // 버튼 중앙에서 아주 좁게 시작 (가운데 집중)
      final startX = screenWidth / 2 + random.nextDouble() * 40 - 20;

      // 위로 갈수록 훨씬 더 넓게 퍼지기 (대폭발 효과!!!)
      final endX = screenWidth / 2 + random.nextDouble() * 400 - 200;

      // 훨씬 더 높이 튀어오름 (450~700 픽셀 위로!!!)
      final peakHeight = buttonY - 450.0 - random.nextDouble() * 250;

      final particle = ParticleModel(
        id: particleId,
        startX: startX,
        startY: buttonY,
        endX: endX,
        endY: peakHeight,
        rotation: random.nextDouble() * 1440, // 4바퀴 회전!!
        createdAt: now, // 생성 시간 기록 (배치 정리용)
      );

      newParticles.add(particle);

      // 이제 개별 타이머 없이 배치 정리 타이머가 처리함 (성능 최적화!)
    }

    // 즉시 추가 - 동기적으로 처리
    _particles.addAll(newParticles);
    // 강제로 즉시 리빌드
    if (mounted) {
      setState(() {});
    }
  }
}

// 파티클 모델 클래스
class ParticleModel {
  final int id;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final DateTime createdAt; // 생성 시간 추가 (배치 정리용)

  ParticleModel({
    required this.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.createdAt,
  });
}

// 파티클 위젯
class FireParticle extends StatefulWidget {
  final ParticleModel particle;

  const FireParticle({Key? key, required this.particle}) : super(key: key);

  @override
  State<FireParticle> createState() => _FireParticleState();
}

class _FireParticleState extends State<FireParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionX;
  late Animation<double> _positionY;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800), // 훨씬 더 오래 유지!
      vsync: this,
    );

    // 좌우 움직임 - 부드럽게
    _positionX = Tween<double>(
      begin: widget.particle.startX,
      end: widget.particle.endX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 위로 튀어오르는 포물선 궤적 (중력 효과)
    // 폭발적으로 빠르게 올라가고, 정점에서 느려지고, 내려올 때 빠르게 가속
    _positionY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.particle.startY,
          end: widget.particle.endY,
        ).chain(CurveTween(curve: Curves.easeOutCubic)), // 더 빠르게!
        weight: 45, // 올라가는 시간 짧게
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.particle.endY,
          end: widget.particle.startY + 50, // 원래 위치보다 약간 아래로
        ).chain(CurveTween(curve: Curves.easeInCubic)), // 더 빠르게!
        weight: 55, // 내려오는 시간 길게
      ),
    ]).animate(_controller);

    // 올라갈 때는 보이고, 내려올 때 사라지기
    _opacity = TweenSequence<double>([
      // 올라가는 동안 완전히 보임 (0~45%)
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
      // 내려오면서 빠르게 투명해짐 (45~100%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)), // 더 빠르게 사라짐
        weight: 55,
      ),
    ]).animate(_controller);

    // 크기 변화 (더 드라마틱하게!)
    _scale = Tween<double>(begin: 1.3, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 회전 애니메이션
    _rotation = Tween<double>(begin: 0.0, end: widget.particle.rotation).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionX.value,
          top: _positionY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Transform.rotate(
                angle: _rotation.value * pi / 180,
                child: const Text(
                  '🔥',
                  style: TextStyle(fontSize: 40), // 더 크게!
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 불타는 배경 효과를 그리는 CustomPainter
class FireBackgroundPainter extends CustomPainter {
  final double animation;

  FireBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 버튼 전체를 뒤덮는 강렬한 불꽃 오버레이
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.5),
        radius: 1.5,
        colors: [
          const Color(0xFFFF0000).withOpacity(0.8), // 중심 강렬한 빨강
          const Color(0xFFFF4400).withOpacity(0.6), // 주황
          const Color(0xFFFF8800).withOpacity(0.4), // 연한 주황
          const Color(0xFFFFDD00).withOpacity(0.2), // 노랑
          const Color(0x00FFDD00), // 투명
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(
      Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40),
      backgroundPaint,
    );

    // 2. 움직이는 불꽃 파티클 (많이!)
    for (int i = 0; i < 40; i++) {
      final seed = i + animation * 100;
      final localRandom = Random(seed.toInt());

      // 버튼 하단에서 위로 올라가는 불꽃
      final offsetX = localRandom.nextDouble() * size.width;
      final progress = (animation + localRandom.nextDouble()) % 1.0;
      final offsetY = size.height * (1.0 - progress) + localRandom.nextDouble() * 20 - 10;

      final radius = (localRandom.nextDouble() * 15 + 5) * (1.0 - progress);

      // 불꽃 색상 (하단 빨강 -> 상단 노랑)
      final color = progress < 0.3
          ? const Color(0xFFFF0000)
          : progress < 0.6
              ? const Color(0xFFFF6600)
              : const Color(0xFFFFDD00);

      final opacity = (1.0 - progress) * 0.9;

      final flamePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.5),
            color.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(offsetX, offsetY), radius: radius),
        )
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(offsetX, offsetY), radius, flamePaint);
    }

    // 3. 불꽃 왜곡 효과 (흔들림)
    for (int i = 0; i < 10; i++) {
      final localRandom = Random((animation * 1000 + i * 100).toInt());
      final offsetX = localRandom.nextDouble() * size.width;
      final offsetY = localRandom.nextDouble() * size.height;

      final distortPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFAA00).withOpacity(0.6),
            const Color(0xFFFF4400).withOpacity(0.3),
            const Color(0x00FF0000),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(offsetX, offsetY), radius: 40),
        )
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(offsetX, offsetY), 40, distortPaint);
    }

    // 4. 버튼 가장자리 강렬한 불꽃 테두리
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF0000).withOpacity(0.9),
          const Color(0xFFFF6600).withOpacity(0.7),
          const Color(0xFFFFDD00).withOpacity(0.5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.screen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5, -5, size.width + 10, size.height + 10),
        const Radius.circular(34),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(FireBackgroundPainter oldDelegate) => true;
}