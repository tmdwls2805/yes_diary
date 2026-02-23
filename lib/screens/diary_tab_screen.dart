import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/widgets/custom_calendar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class DiaryTabScreen extends ConsumerStatefulWidget {
  const DiaryTabScreen({super.key});

  @override
  ConsumerState<DiaryTabScreen> createState() => _DiaryTabScreenState();
}

class _DiaryTabScreenState extends ConsumerState<DiaryTabScreen> with SingleTickerProviderStateMixin {
  int _clickCount = 0;
  double _fillPercentage = 0.0;
  Timer? _decayTimer;
  Timer? _slowDecayTimer;
  List<ParticleModel> _particles = [];
  bool _isBurning = false;
  Timer? _burningTimer;
  Timer? _particleCleanupTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    _startDecayTimer();
    _startParticleCleanup();

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
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_clickCount > 0 && !_isBurning) {
        setState(() {
          _clickCount = (_clickCount - 1).clamp(0, 100);
          _fillPercentage = _clickCount / 100.0;
        });
      } else {
        _decayTimer?.cancel();
      }
    });
  }

  void _startParticleCleanup() {
    _particleCleanupTimer?.cancel();
    _particleCleanupTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final initialLength = _particles.length;

      _particles.removeWhere((particle) {
        final age = now.difference(particle.createdAt).inMilliseconds;
        return age >= 1800;
      });

      if (_particles.length != initialLength && mounted) {
        setState(() {});
      }
    });
  }

  void _startBurningEffect() {
    if (_isBurning) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _isBurning = true;
      _showFlash = true;
    });

    _pulseController.repeat(reverse: true);
    _createParticles();
    _flashScreen();

    _burningTimer = Timer.periodic(const Duration(milliseconds: 5), (timer) {
      _createParticles();
      if (timer.tick % 100 == 0) {
        HapticFeedback.mediumImpact();
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      _burningTimer?.cancel();
      _pulseController.stop();
      _pulseController.reset();

      if (mounted) {
        setState(() {
          _isBurning = false;
          _showFlash = false;
        });
        _startSlowDecay();
      }
    });
  }

  void _startSlowDecay() {
    _slowDecayTimer?.cancel();
    _decayTimer?.cancel();

    const totalDuration = 3000;
    const interval = 30;
    const steps = totalDuration ~/ interval;
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

  void _createParticles() {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonY = screenHeight - 150.0;

    final particleCount = _isBurning
        ? random.nextInt(16) + 30
        : random.nextInt(5) + 8;

    final now = DateTime.now();
    final baseId = now.microsecondsSinceEpoch;

    final newParticles = <ParticleModel>[];

    for (int i = 0; i < particleCount; i++) {
      final particleId = baseId * 1000 + i;

      final startX = screenWidth / 2 + random.nextDouble() * 40 - 20;
      final endX = screenWidth / 2 + random.nextDouble() * 400 - 200;
      final peakHeight = buttonY - 450.0 - random.nextDouble() * 250;

      final particle = ParticleModel(
        id: particleId,
        startX: startX,
        startY: buttonY,
        endX: endX,
        endY: peakHeight,
        rotation: random.nextDouble() * 1440,
        createdAt: now,
      );

      newParticles.add(particle);
    }

    _particles.addAll(newParticles);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);

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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(34.0),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: _fillPercentage * (MediaQuery.of(context).size.width - 32.0),
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    color: _isBurning ? const Color(0xFFFF4400) : const Color(0xFFE22200),
                                    boxShadow: _isBurning ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF4400).withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ] : null,
                                  ),
                                ),
                                SizedBox.expand(
                                  child: ElevatedButton(
                                    onPressed: _isBurning ? null : () {
                                      setState(() {
                                        _clickCount = (_clickCount + 1).clamp(0, 100);
                                        _fillPercentage = _clickCount / 100.0;
                                      });

                                      if (_clickCount >= 100 && !_isBurning) {
                                        _startBurningEffect();
                                      } else {
                                        _startDecayTimer();
                                        _createParticles();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(34.0),
                                      ),
                                      side: BorderSide.none,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: RichText(
                                            text: const TextSpan(
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
                                          width: 40,
                                          height: 40,
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
        ..._particles.map((particle) => FireParticle(particle: particle)),
      ],
    );
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
  final DateTime createdAt;

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

  const FireParticle({super.key, required this.particle});

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
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _positionX = Tween<double>(
      begin: widget.particle.startX,
      end: widget.particle.endX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _positionY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.particle.startY,
          end: widget.particle.endY,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.particle.endY,
          end: widget.particle.startY + 50,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_controller);

    _scale = Tween<double>(begin: 1.3, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

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
                  style: TextStyle(fontSize: 40),
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
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.5),
        radius: 1.5,
        colors: [
          const Color(0xFFFF0000).withOpacity(0.8),
          const Color(0xFFFF4400).withOpacity(0.6),
          const Color(0xFFFF8800).withOpacity(0.4),
          const Color(0xFFFFDD00).withOpacity(0.2),
          const Color(0x00FFDD00),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(
      Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40),
      backgroundPaint,
    );

    for (int i = 0; i < 40; i++) {
      final seed = i + animation * 100;
      final localRandom = Random(seed.toInt());

      final offsetX = localRandom.nextDouble() * size.width;
      final progress = (animation + localRandom.nextDouble()) % 1.0;
      final offsetY = size.height * (1.0 - progress) + localRandom.nextDouble() * 20 - 10;

      final radius = (localRandom.nextDouble() * 15 + 5) * (1.0 - progress);

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
