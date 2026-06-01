import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';

enum TimeState {
  workTime, // 근무 시간
  nightWorkTime, // 야근 시간
  wakeUpTime, // 기상 시간
  bedTime, // 취침 시간
}

class _WorkSchedule {
  final TimeOfDay start;
  final TimeOfDay end;

  const _WorkSchedule({
    required this.start,
    required this.end,
  });
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

class _HomeTabScreenState extends ConsumerState<HomeTabScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _wakeUpLeadMinutes = 180;
  TimeState currentTimeState = TimeState.workTime;
  final List<BubbleModel> _bubbles = [];
  final Random _random = Random();
  static const int _maxBubbles = 30; // 최대 버블 개수 제한
  bool _isLeftTurn = true; // 왼쪽/오른쪽 번갈아가며
  DateTime? _lastClickTime; // 마지막 클릭 시간
  static const Duration _clickCooldown =
      Duration(milliseconds: 500); // 0.5초 쿨다운
  int _bubbleIdCounter = 0; // 버블 고유 ID 카운터
  late AnimationController _lottieController;
  String _department = '';
  _WorkSchedule _workSchedule = const _WorkSchedule(
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 18, minute: 0),
  );
  Timer? _timeStateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lottieController = AnimationController(vsync: this);
    _loadHomeProfile();
    _timeStateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshTimeState(),
    );
  }

  Future<void> _loadHomeProfile() async {
    final profile = await SecureStorageService().getOnboardingProfile();
    if (!mounted) return;
    setState(() {
      _department = profile['department'] ?? '';
      _workSchedule = _WorkSchedule(
        start: _parseTimeOfDay(profile['startTime']) ??
            const TimeOfDay(hour: 9, minute: 0),
        end: _parseTimeOfDay(profile['endTime']) ??
            const TimeOfDay(hour: 18, minute: 0),
      );
    });
    await _refreshTimeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeStateTimer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHomeProfile();
    }
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  int _normalizeMinute(int minute) {
    const minutesPerDay = 24 * 60;
    return (minute % minutesPerDay + minutesPerDay) % minutesPerDay;
  }

  bool _isInRange(int value, int start, int end) {
    if (start == end) return true;
    if (start < end) return value >= start && value < end;
    return value >= start || value < end;
  }

  int get _workStartMinute => _toMinutes(_workSchedule.start);
  int get _workEndMinute => _toMinutes(_workSchedule.end);
  int get _wakeUpStartMinute =>
      _normalizeMinute(_workStartMinute - _wakeUpLeadMinutes);

  bool _isWakeUpPeriod(DateTime now) {
    final nowMinute = now.hour * 60 + now.minute;
    return _isInRange(nowMinute, _wakeUpStartMinute, _workStartMinute);
  }

  bool _isWorkPeriod(DateTime now) {
    final nowMinute = now.hour * 60 + now.minute;
    return _isInRange(nowMinute, _workStartMinute, _workEndMinute);
  }

  bool _isAfterWorkPeriod(DateTime now) {
    return !_isWakeUpPeriod(now) && !_isWorkPeriod(now);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _bedTimeDateKey(DateTime now) {
    final nowMinute = now.hour * 60 + now.minute;
    final afterWorkWraps = _workEndMinute > _wakeUpStartMinute;
    final anchorDate = afterWorkWraps && nowMinute < _wakeUpStartMinute
        ? now.subtract(const Duration(days: 1))
        : now;
    return _dateKey(anchorDate);
  }

  Future<TimeState> _calculateTimeState(DateTime now) async {
    final savedBedTimeDate = await SecureStorageService().getHomeBedTimeDate();

    if (_isWakeUpPeriod(now)) {
      return TimeState.wakeUpTime;
    }

    if (_isWorkPeriod(now)) {
      return TimeState.workTime;
    }

    if (savedBedTimeDate == _bedTimeDateKey(now)) {
      return TimeState.bedTime;
    }

    return TimeState.nightWorkTime;
  }

  Future<void> _refreshTimeState() async {
    final nextState = await _calculateTimeState(DateTime.now());
    if (!mounted) return;
    setState(() {
      currentTimeState = nextState;
    });
  }

  Future<void> _startBedTime() async {
    if (!_isAfterWorkPeriod(DateTime.now())) return;
    await SecureStorageService().saveHomeBedTimeDate(
      _bedTimeDateKey(DateTime.now()),
    );
    if (!mounted) return;
    setState(() {
      currentTimeState = TimeState.bedTime;
    });
  }

  DateTime _workEndDateTime(DateTime now) {
    final startMinute = _workStartMinute;
    final endMinute = _workEndMinute;
    final nowMinute = now.hour * 60 + now.minute;
    var date = DateTime(
      now.year,
      now.month,
      now.day,
      _workSchedule.end.hour,
      _workSchedule.end.minute,
    );

    if (endMinute <= startMinute && nowMinute >= startMinute) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  int _remainingWorkHours(DateTime now) {
    final remaining = _workEndDateTime(now).difference(now);
    if (remaining.isNegative) return 0;
    final minutes = remaining.inMinutes;
    return (minutes / 60).ceil();
  }

  int _remainingWorkMinutes(DateTime now) {
    final remaining = _workEndDateTime(now).difference(now);
    if (remaining.isNegative) return 0;
    return remaining.inMinutes.clamp(0, 59);
  }

  DateTime _lastWorkEndDateTime(DateTime now) {
    final nowMinute = now.hour * 60 + now.minute;
    final afterWorkWraps = _workEndMinute > _wakeUpStartMinute;
    final endDate = afterWorkWraps && nowMinute < _wakeUpStartMinute
        ? now.subtract(const Duration(days: 1))
        : now;

    return DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      _workSchedule.end.hour,
      _workSchedule.end.minute,
    );
  }

  int _elapsedAfterWorkHours(DateTime now) {
    final elapsed = now.difference(_lastWorkEndDateTime(now));
    if (elapsed.isNegative) return 0;
    return elapsed.inMinutes ~/ 60;
  }

  DateTime _nextWorkStartDateTime(DateTime now) {
    var start = DateTime(
      now.year,
      now.month,
      now.day,
      _workSchedule.start.hour,
      _workSchedule.start.minute,
    );
    if (!start.isAfter(now)) {
      start = start.add(const Duration(days: 1));
    }
    return start;
  }

  int _remainingUntilWorkStartHours(DateTime now) {
    final remaining = _nextWorkStartDateTime(now).difference(now);
    if (remaining.isNegative) return 0;
    return (remaining.inMinutes / 60).ceil();
  }

  String _workInProgressLabel(DateTime now) {
    const suffixes = ['.', '..', '...'];
    return '업무중${suffixes[now.second % suffixes.length]}';
  }

  String _actionButtonLabel(TimeState state) {
    final now = DateTime.now();
    switch (state) {
      case TimeState.workTime:
        final remaining = _workEndDateTime(now).difference(now);
        if (remaining.inMinutes <= 60) {
          return 'H-0 M-${_remainingWorkMinutes(now)} ${_workInProgressLabel(now)}';
        }
        return 'H-${_remainingWorkHours(now)} ${_workInProgressLabel(now)}';
      case TimeState.nightWorkTime:
        return 'H+${_elapsedAfterWorkHours(now)} 퇴근!';
      case TimeState.bedTime:
        return '출근 H-${_remainingUntilWorkStartHours(now)}';
      case TimeState.wakeUpTime:
        return '출근 준비중...';
    }
  }

  bool _canTapActionButton(TimeState state) {
    return state == TimeState.nightWorkTime;
  }

  Widget _buildLottieAnimation(String assetPath, TimeState state) {
    return Lottie.asset(
      assetPath,
      key: ValueKey(state),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      controller: _lottieController,
      onLoaded: (composition) {
        _lottieController
          ..duration = Duration(
            milliseconds: (composition.duration.inMilliseconds / 0.6).round(),
          )
          ..reset()
          ..repeat();
      },
    );
  }

  Widget _getAnimationForTimeState(TimeState state) {
    switch (state) {
      case TimeState.workTime:
        return _buildLottieAnimation(
          'assets/home/work_time.json',
          state,
        );
      case TimeState.nightWorkTime:
        return _buildLottieAnimation(
          'assets/home/night_work_time.json',
          state,
        );
      case TimeState.wakeUpTime:
        return _buildLottieAnimation(
          'assets/home/wake_up_time.json',
          state,
        );
      case TimeState.bedTime:
        return _buildLottieAnimation(
          'assets/home/bed_time.json',
          state,
        );
    }
  }

  void _createBubbles() {
    final now = DateTime.now();

    // 쿨다운 체크
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!) < _clickCooldown) {
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
    final bubblePath =
        _isLeftTurn ? 'assets/home/bubble_1.svg' : 'assets/home/bubble_2.svg';
    final bubbleX = _isLeftTurn
        ? _random.nextDouble() * (centerX - bubbleWidth) // 왼쪽 영역
        : centerX + _random.nextDouble() * (centerX - bubbleWidth); // 오른쪽 영역
    final bubbleY =
        screenHeight * 0.7 + _random.nextDouble() * (screenHeight * 0.12);

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
    final timeState = currentTimeState;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
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
                            offset: Offset(
                                0,
                                timeState == TimeState.wakeUpTime
                                    ? -screenHeight * 0.08
                                    : 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 부서 태그 - 시간대에 따라 변경 (기상/취침 시간은 숨김)
                                if (timeState != TimeState.wakeUpTime &&
                                    timeState != TimeState.bedTime &&
                                    _department.isNotEmpty)
                                  Transform.translate(
                                    offset: Offset(0, -screenHeight * 0.05),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _buildDepartmentTag(_department),
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
                if (timeState != TimeState.bedTime)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.05,
                      left: 16,
                      right: 16,
                    ),
                    child: _buildHomeActionButton(timeState),
                  ),
              ],
            ),

            if (timeState == TimeState.bedTime)
              Positioned(
                left: 16,
                right: 16,
                bottom: screenHeight * 0.05,
                child: _buildHomeActionButton(timeState),
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

  Widget _buildDepartmentTag(String text) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return IntrinsicWidth(
      child: Container(
        height: screenHeight * 0.055,
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06, vertical: screenHeight * 0.01),
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

  Widget _buildHomeActionButton(TimeState state) {
    final canTap = _canTapActionButton(state);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canTap ? _startBedTime : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canTap ? const Color(0xFFFF5252) : const Color(0xFF3A3A3A),
          disabledBackgroundColor: const Color(0xFF3A3A3A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _actionButtonLabel(state),
          style: TextStyle(
            color: canTap ? const Color(0xFFFFFFFF) : const Color(0xFF9A9A9A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
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

class _BubbleWidgetState extends State<BubbleWidget>
    with SingleTickerProviderStateMixin {
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
