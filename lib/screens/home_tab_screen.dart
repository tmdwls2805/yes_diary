import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
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
        return Lottie.asset(
          'assets/home/night_work_time.json',
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
      case TimeState.wakeUpTime:
        return Lottie.asset(
          'assets/home/wake_up_time.json',
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
      case TimeState.bedTime:
        return Lottie.asset(
          'assets/home/bed_time.json',
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
    final bubbleWidth = screenWidth * 0.375; // 버블 너비 (화면 너비의 37.5%)

    // 왼쪽/오른쪽 번갈아가며
    final bubblePath = _isLeftTurn ? 'assets/home/bubble_1.svg' : 'assets/home/bubble_2.svg';
    final bubbleX = _isLeftTurn
        ? _random.nextDouble() * (centerX - bubbleWidth) // 왼쪽 영역
        : centerX + _random.nextDouble() * (centerX - bubbleWidth); // 오른쪽 영역
    final bubbleY = screenHeight * 0.7 + _random.nextDouble() * (screenHeight * 0.12);

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // 언어 선택 버튼 (오른쪽 상단)
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => _showLanguagePicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCurrentLanguageLabel(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.language, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            // 메인 컨텐츠
            Column(
              children: [
                Expanded(
                  child: timeState == TimeState.bedTime
                      ? Stack(
                          children: [
                            // 취침 애니메이션 - 전체 화면 채우기
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: GestureDetector(
                                  onTap: _createBubbles,
                                  child: _getAnimationForTimeState(timeState),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Transform.translate(
                            offset: Offset(0, timeState == TimeState.wakeUpTime ? -screenHeight * 0.08 : 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 부서 태그 - 시간대에 따라 변경 (기상/취침 시간은 숨김)
                                if (timeState != TimeState.wakeUpTime && timeState != TimeState.bedTime)
                                  Transform.translate(
                                    offset: Offset(0, -screenHeight * 0.05),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _buildDepartmentTag(_getDepartmentNameForTimeState(timeState)),
                                    ),
                                  ),

                                SizedBox(height: screenHeight * 0.05),

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

                // TimeState 전환 버튼들 - 취침이 아닐 때만 여기 표시
                if (timeState != TimeState.bedTime)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.05,
                      left: screenWidth * 0.04,
                      right: screenWidth * 0.04,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTimeStateButton('home.work'.tr(), TimeState.workTime),
                        _buildTimeStateButton('home.night_work'.tr(), TimeState.nightWorkTime),
                        _buildTimeStateButton('home.wake_up'.tr(), TimeState.wakeUpTime),
                        _buildTimeStateButton('home.bed_time'.tr(), TimeState.bedTime),
                      ],
                    ),
                  ),
              ],
            ),

            // 취침일 때만 버튼을 애니메이션 위에 겹쳐서 표시
            if (timeState == TimeState.bedTime)
              Positioned(
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                bottom: screenHeight * 0.05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeStateButton('home.work'.tr(), TimeState.workTime),
                    _buildTimeStateButton('home.night_work'.tr(), TimeState.nightWorkTime),
                    _buildTimeStateButton('home.wake_up'.tr(), TimeState.wakeUpTime),
                    _buildTimeStateButton('home.bed_time'.tr(), TimeState.bedTime),
                  ],
                ),
              ),

            // 버블 애니메이션들
            ..._bubbles.map((bubble) => BubbleWidget(
              key: ValueKey(bubble.id),
              bubble: bubble,
              onComplete: () => _removeBubble(bubble.id),
              screenWidth: screenWidth,
            )),
          ],
        ),
      ),
    );
  }

  String _getCurrentLanguageLabel(BuildContext context) {
    final locale = context.locale;
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      default:
        return '한국어';
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'locale': const Locale('ko'), 'label': '한국어'},
      {'locale': const Locale('en'), 'label': 'English'},
      {'locale': const Locale('ja'), 'label': '日本語'},
      {'locale': const Locale('zh'), 'label': '中文'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                '언어 선택',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...languages.map((lang) {
                final isSelected = context.locale == lang['locale'];
                return ListTile(
                  title: Text(
                    lang['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.red : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.red)
                      : null,
                  onTap: () {
                    context.setLocale(lang['locale'] as Locale);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepartmentTag(String text) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return IntrinsicWidth(
      child: Container(
        height: screenHeight * 0.055,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.01),
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
          style: TextStyle(
            color: const Color(0xFFA5A5A5),
            fontSize: screenWidth * 0.056,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeStateButton(String label, TimeState state) {
    final isSelected = currentTimeState == state;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        child: SizedBox(
          height: screenHeight * 0.07,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                currentTimeState = state;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? const Color(0xFF6E6E6E) : const Color(0xFF3A3A3A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFBDBDBD) : const Color(0xFF6E6E6E),
                fontSize: screenWidth * 0.041,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  final double screenWidth;

  const BubbleWidget({
    super.key,
    required this.bubble,
    required this.onComplete,
    required this.screenWidth,
  });

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
    final bubbleWidth = widget.screenWidth * 0.375; // 146 / 390 ≈ 0.375
    final bubbleHeight = widget.screenWidth * 0.131; // 51 / 390 ≈ 0.131

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
                width: bubbleWidth,
                height: bubbleHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}
