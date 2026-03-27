import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'dart:async';

enum TimeState {
  workTime,      // 근무 시간
  nightWorkTime, // 야근 시간
  wakeUpTime,    // 기상 시간
  bedTime,       // 취침 시간
}

// 버블 모델 클래스
class BubbleModel {
  final int id;
  final String svgPath;
  final double startX;
  final double startY;
  final DateTime createdAt;

  BubbleModel({
    required this.id,
    required this.svgPath,
    required this.startX,
    required this.startY,
    required this.createdAt,
  });
}

class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> with TickerProviderStateMixin {
  // 임시: 현재 시간대 설정 (테스트용)
  TimeState currentTimeState = TimeState.workTime;
  List<BubbleModel> _bubbles = [];
  final Random _random = Random();
  static const int _maxBubbles = 30; // 최대 버블 개수 제한
  bool _isLeftTurn = true; // 왼쪽/오른쪽 번갈아가며
  DateTime? _lastClickTime; // 마지막 클릭 시간
  static const Duration _clickCooldown = Duration(milliseconds: 500); // 0.5초 쿨다운
  int _bubbleIdCounter = 0; // 버블 고유 ID 카운터
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }


  TimeState _getCurrentTimeState() {
    // TODO: 실제 시간에 따라 TimeState 반환
    // final now = DateTime.now();
    // final hour = now.hour;

    return currentTimeState;
  }

  Widget _getAnimationForTimeState(TimeState state) {
    switch (state) {
      case TimeState.workTime:
        return Lottie.asset(
          'assets/home/work_time.json',
          width: double.infinity,
          fit: BoxFit.fitWidth,
          controller: _lottieController,
          onLoaded: (composition) {
            // 속도 조절: 0.6배 속도 = 원본 시간의 1.67배 길이
            _lottieController.duration = Duration(
              milliseconds: (composition.duration.inMilliseconds / 0.6).round(),
            );
            _lottieController.forward();
            _lottieController.repeat();
          },
        );
      case TimeState.nightWorkTime:
        return Image.asset(
          'assets/home/night_work_time.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        );
      case TimeState.wakeUpTime:
        return Image.asset(
          'assets/home/wake_up_time.png', // 나중에 추가
          width: double.infinity,
          fit: BoxFit.fitWidth,
        );
      case TimeState.bedTime:
        return Image.asset(
          'assets/home/bed_time.png', // 나중에 추가
          width: double.infinity,
          fit: BoxFit.fitWidth,
        );
    }
  }

  String _getDepartmentNameForTimeState(TimeState state) {
    switch (state) {
      case TimeState.workTime:
        return '연구사설공중분해팀';
      case TimeState.nightWorkTime:
        return '야근중인팀';
      case TimeState.wakeUpTime:
        return '기상팀';
      case TimeState.bedTime:
        return '취침팀';
    }
  }

  void _createBubbles() {
    final now = DateTime.now();

    // 쿨다운 체크
    if (_lastClickTime != null && now.difference(_lastClickTime!) < _clickCooldown) {
      return;
    }

    // 최대 버블 개수 제한
    if (_bubbles.length >= _maxBubbles) {
      return;
    }

    _lastClickTime = now;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = screenWidth / 2;

    // 왼쪽/오른쪽 번갈아가며
    final bubblePath = _isLeftTurn ? 'assets/home/bubble_1.svg' : 'assets/home/bubble_2.svg';
    final bubbleX = _isLeftTurn
        ? _random.nextDouble() * (centerX - 146) // 왼쪽 영역
        : centerX + _random.nextDouble() * (centerX - 146); // 오른쪽 영역
    final bubbleY = screenHeight * 0.7 + _random.nextDouble() * 100;

    final bubble = BubbleModel(
      id: _bubbleIdCounter++,
      svgPath: bubblePath,
      startX: bubbleX,
      startY: bubbleY,
      createdAt: now,
    );

    setState(() {
      _bubbles.add(bubble);
      _isLeftTurn = !_isLeftTurn; // 다음 턴으로 전환
    });
  }

  void _removeBubble(int bubbleId) {
    if (!mounted) return;
    setState(() {
      _bubbles.removeWhere((bubble) => bubble.id == bubbleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeState = _getCurrentTimeState();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 부서 태그 - 시간대에 따라 변경
                          Transform.translate(
                            offset: const Offset(0, -40),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildDepartmentTag(_getDepartmentNameForTimeState(timeState)),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 애니메이션/이미지 - 시간대에 따라 변경
                          GestureDetector(
                            onTap: _createBubbles,
                            child: _getAnimationForTimeState(timeState),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 버튼
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: 358,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E6E6E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '버튼',
                        style: TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 버블 애니메이션들
            ..._bubbles.map((bubble) => BubbleWidget(
              key: ValueKey(bubble.id),
              bubble: bubble,
              onComplete: () => _removeBubble(bubble.id),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentTag(String text) {
    return IntrinsicWidth(
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF7F7F7F),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFA5A5A5),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// 버블 위젯
class BubbleWidget extends StatefulWidget {
  final BubbleModel bubble;
  final VoidCallback onComplete;

  const BubbleWidget({super.key, required this.bubble, required this.onComplete});

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _positionY = Tween<double>(
      begin: widget.bubble.startY,
      end: -100, // 화면 위로 사라짐
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      // 애니메이션 완료 시 콜백 호출
      widget.onComplete();
    });
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
          left: widget.bubble.startX,
          top: _positionY.value,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacity.value,
              child: SvgPicture.asset(
                widget.bubble.svgPath,
                width: 146,
                height: 51,
              ),
            ),
          ),
        );
      },
    );
  }
}
