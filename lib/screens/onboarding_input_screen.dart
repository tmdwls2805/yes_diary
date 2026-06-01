import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/widgets/my_screen.dart';

class OnboardingInputScreen extends StatefulWidget {
  const OnboardingInputScreen({super.key});

  @override
  State<OnboardingInputScreen> createState() => _OnboardingInputScreenState();
}

class _OnboardingInputScreenState extends State<OnboardingInputScreen>
    with TickerProviderStateMixin {
  static const List<String> _messages = [
    '안녕하세요!',
    '저희는 감정요정이에요~!',
    '회사에서 받은 스트레스!',
    '저희가 다 들어드릴게요!',
    '먼저, 어떻게 불러드릴까요?',
  ];

  late final List<AnimationController> _controllers;
  late final TextEditingController _nameController;
  late final ScrollController _scrollController;
  bool _inputEnabled = false;
  bool _showTimePicker = false;
  bool _showEmotionPicker = false;
  bool _showWriteDiary = false;
  int _step = 0;
  int _userBubbleSeq = 0;
  int _selectedTimeTab = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String _nickname = '';
  String _department = '';
  _Emotion? _selectedEmotion;

  static const List<_Emotion> _emotionChips = [
    _Emotion('화🔥', 'assets/emotion/red.svg', 'red'),
    _Emotion('기쁨🍀', 'assets/emotion/yellow.svg', 'yellow'),
    _Emotion('당황😰', 'assets/emotion/blue.svg', 'blue'),
    _Emotion('슬픔😢', 'assets/emotion/pink.svg', 'pink'),
    _Emotion('허탈☠️', 'assets/emotion/green.svg', 'green'),
  ];
  final List<_TimelineItem> _timeline = [];

  static const List<String> _placeholders = [
    '사용하실 닉네임을 입력해주세요.',
    '근무 부서를 입력해주세요.',
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _messages.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      ),
    );
    _nameController = TextEditingController();
    _nameController.addListener(() => setState(() {}));
    _scrollController = ScrollController();
    _startSequence();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startSequence() async {
    for (var i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      _scrollToBottom();
      await _controllers[i].forward();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!mounted) return;
    setState(() => _inputEnabled = true);
  }

  Future<void> _runFollowUp(
    List<_FollowUp> messages, {
    bool reEnableInput = false,
    bool showTimePicker = false,
    bool showEmotionPicker = false,
    bool showWriteDiary = false,
  }) async {
    for (final item in messages) {
      if (!mounted) return;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      setState(() {
        _timeline.add(_TimelineItem.bot(item, controller));
      });
      _scrollToBottom();
      await controller.forward();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!mounted) return;
    setState(() {
      if (reEnableInput) _inputEnabled = true;
      if (showTimePicker) _showTimePicker = true;
      if (showEmotionPicker) _showEmotionPicker = true;
      if (showWriteDiary) _showWriteDiary = true;
    });
    if (showTimePicker || showEmotionPicker || showWriteDiary) {
      _scrollToBottom();
    }
  }

  Future<void> _selectEmotion(_Emotion emotion) async {
    setState(() {
      _selectedEmotion = emotion;
      _timeline.add(_TimelineItem.user(emotion.label, _userBubbleSeq++));
      _showEmotionPicker = false;
    });
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final greeting = emotion.key == 'green' ? '안녕하세요!' : '또 만나네요!';
    _runFollowUp([
      _FollowUp(greeting, emotion.iconAsset),
      _FollowUp('제가 $_nickname 님의 감정요정이에요!'),
      const _FollowUp('저희 함께 힘든 회사생활'),
      const _FollowUp('잘 헤쳐나가봐요🔥'),
    ], showWriteDiary: true);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submitTime() async {
    final text = '출근 ${_fmt(_startTime)}, 퇴근 ${_fmt(_endTime)}';
    setState(() {
      _timeline.add(_TimelineItem.user(text, _userBubbleSeq++));
      _showTimePicker = false;
      _step += 1;
    });
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _runFollowUp([
      const _FollowUp('이제, 저희와 함께 일해요!', 'assets/emotion/pink.svg'),
      _FollowUp('$_nickname 님과 함꼐할 요정 선택을 위한'),
      const _FollowUp('마지막 질문 타임!'),
      const _FollowUp('회사에서 주로 느끼는 감정은'),
      const _FollowUp('무엇인가요?'),
    ], showEmotionPicker: true);
  }

  Future<void> _submit() async {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    final currentStep = _step;
    setState(() {
      _timeline.add(_TimelineItem.user(text, _userBubbleSeq++));
      _nameController.clear();
      _step += 1;
      _inputEnabled = false;
    });
    FocusScope.of(context).unfocus();
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (currentStep == 0) {
      _nickname = text;
      await SecureStorageService().saveOnboardingNickname(text);
      _runFollowUp([
        _FollowUp('$text 님, 안녕하세요.', 'assets/emotion/yellow.svg'),
        _FollowUp('$text 님은 어느 부서에서,'),
        const _FollowUp('근무하고 계신가요?'),
      ], reEnableInput: true);
    } else if (currentStep == 1) {
      _department = text;
      await SecureStorageService().saveOnboardingDepartment(text);
      _runFollowUp([
        _FollowUp('그럼, $text로 세팅할게요!', 'assets/emotion/blue.svg'),
        const _FollowUp('출/퇴근 시간도 알려주시면'),
        const _FollowUp('저희도 맞춰 출퇴근할게요!'),
      ], showTimePicker: true);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final item in _timeline) {
      item.controller?.dispose();
    }
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 116),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedBubble(
                      controller: _controllers[0],
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/emotion/red.svg',
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(width: 12),
                          _Bubble(text: _messages[0]),
                        ],
                      ),
                    ),
                    for (var i = 1; i < _messages.length; i++) ...[
                      const SizedBox(height: 12),
                      _AnimatedBubble(
                        controller: _controllers[i],
                        child: Padding(
                          padding: const EdgeInsets.only(left: 60),
                          child: _Bubble(text: _messages[i]),
                        ),
                      ),
                    ],
                    for (var ti = 0; ti < _timeline.length; ti++) ...[
                      SizedBox(
                        height: (_timeline[ti].isUser ||
                                (ti > 0 && _timeline[ti - 1].isUser))
                            ? 15
                            : 12,
                      ),
                      if (_timeline[ti].isUser)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _UserBubble(
                            key: ValueKey('user_${_timeline[ti].userSeq}'),
                            text: _timeline[ti].text,
                          ),
                        )
                      else
                        _AnimatedBubble(
                          controller: _timeline[ti].controller!,
                          child: _timeline[ti].iconAsset != null
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      _timeline[ti].iconAsset!,
                                      width: 48,
                                      height: 48,
                                    ),
                                    const SizedBox(width: 12),
                                    _Bubble(text: _timeline[ti].text),
                                  ],
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(left: 60),
                                  child: _Bubble(text: _timeline[ti].text),
                                ),
                        ),
                    ],
                    if (_showEmotionPicker) ...[
                      const SizedBox(height: 46),
                      const Center(
                        child: Text(
                          '선택해주세요!',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final e in _emotionChips.take(3))
                              _EmotionChip(
                                label: e.label,
                                onTap: () => _selectEmotion(e),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final e in _emotionChips.skip(3))
                              _EmotionChip(
                                label: e.label,
                                onTap: () => _selectEmotion(e),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 56),
                    ],
                    if (_showWriteDiary) ...[
                      const SizedBox(height: 36),
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            await SecureStorageService()
                                .saveOnboardingProfile(
                              nickname: _nickname,
                              department: _department,
                              startTime: _fmt(_startTime),
                              endTime: _fmt(_endTime),
                              emotion: _selectedEmotion?.key ?? '',
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MyScreen(showSkipLogin: true),
                              ),
                            );
                          },
                          child: Container(
                            width: 264,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4646),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '일기 작성하기',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SvgPicture.asset(
                                  'assets/icon/write_diary.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_step < 2) Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2C),
                border: Border(top: BorderSide(color: Color(0xFF4B4B4B))),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF585858)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: _nameController,
                          enabled: _inputEnabled,
                          cursorColor: Colors.white,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: _inputEnabled && _step < _placeholders.length
                                ? _placeholders[_step]
                                : null,
                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9A9A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _nameController.text.trim().isEmpty
                              ? const Color(0xFF737373)
                              : const Color(0xFFFF4646),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Color(0xFFFFFFFF),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: slide, child: child);
              },
              child: _showTimePicker
                  ? Container(
                      key: const ValueKey('time_picker'),
                      height: 302,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2C),
                        border: Border(
                          top: BorderSide(color: Color(0xFF4B4B4B)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TimeTab(
                                  label: '출근',
                                  time: _startTime,
                                  selected: _selectedTimeTab == 0,
                                  onTap: () => setState(
                                    () => _selectedTimeTab = 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TimeTab(
                                  label: '퇴근',
                                  time: _endTime,
                                  selected: _selectedTimeTab == 1,
                                  onTap: () => setState(
                                    () => _selectedTimeTab = 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: _WheelTimePicker(
                              key: ValueKey('wheel_$_selectedTimeTab'),
                              time: _selectedTimeTab == 0
                                  ? _startTime
                                  : _endTime,
                              onChanged: (t) => setState(() {
                                if (_selectedTimeTab == 0) {
                                  _startTime = t;
                                } else {
                                  _endTime = t;
                                }
                              }),
                            ),
                          ),
                          GestureDetector(
                            onTap: _submitTime,
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4646),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '보내기',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              color: (_step < 2 || _showTimePicker)
                  ? const Color(0xFF2C2C2C)
                  : Colors.black,
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }
}

class _AnimatedBubble extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _AnimatedBubble({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;

  const _Bubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          left: -4,
          bottom: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -10,
          bottom: -4,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatefulWidget {
  final String text;

  const _UserBubble({super.key, required this.text});

  @override
  State<_UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends State<_UserBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 52, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4646),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icon/write_diary.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4646),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -4,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4646),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUp {
  final String text;
  final String? iconAsset;
  const _FollowUp(this.text, [this.iconAsset]);
}

class _Emotion {
  final String label;
  final String iconAsset;
  final String key;
  const _Emotion(this.label, this.iconAsset, this.key);
}

class _EmotionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmotionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4646),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _WheelTimePicker extends StatefulWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _WheelTimePicker({
    super.key,
    required this.time,
    required this.onChanged,
  });

  @override
  State<_WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<_WheelTimePicker> {
  late int _period;
  late int _hour24;
  late int _minute;
  late final FixedExtentScrollController _periodCtrl;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _hour24 = widget.time.hour;
    _period = _hour24 < 12 ? 0 : 1;
    _minute = widget.time.minute;
    _periodCtrl = FixedExtentScrollController(initialItem: _period);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour24);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _periodCtrl.addListener(_onScroll);
    _hourCtrl.addListener(_onScroll);
    _minuteCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  double _distance(FixedExtentScrollController ctrl, int index) {
    if (!ctrl.hasClients || ctrl.position.maxScrollExtent == 0) {
      return (index - ctrl.initialItem).toDouble().abs();
    }
    final selected = ctrl.offset / 36;
    return (index - selected).abs();
  }

  TextStyle _wheelStyle(double distance) {
    final isSelected = distance < 0.5;
    final double fontSize;
    if (isSelected) {
      fontSize = 24;
    } else {
      final t = ((distance - 0.5) / 0.5).clamp(0.0, 1.0);
      fontSize = 24 - (24 - 16) * t;
    }
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: fontSize,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      color: isSelected ? Colors.white : const Color(0xFF777777),
    );
  }

  void _emit() {
    widget.onChanged(TimeOfDay(hour: _hour24, minute: _minute));
  }

  void _onHourChanged(int i) {
    final newPeriod = i < 12 ? 0 : 1;
    setState(() {
      _hour24 = i;
      if (newPeriod != _period) {
        _period = newPeriod;
        _periodCtrl.animateToItem(
          newPeriod,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    _emit();
  }

  void _onPeriodChanged(int i) {
    if (i == _period) return;
    final newHour = (_hour24 % 12) + (i == 1 ? 12 : 0);
    setState(() {
      _period = i;
      _hour24 = newHour;
    });
    _hourCtrl.animateToItem(
      newHour,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoPicker(
            scrollController: _periodCtrl,
            itemExtent: 36,
            backgroundColor: Colors.transparent,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: _onPeriodChanged,
            children: [
              Center(
                child: Text(
                  '오전',
                  style: _wheelStyle(_distance(_periodCtrl, 0)),
                ),
              ),
              Center(
                child: Text(
                  '오후',
                  style: _wheelStyle(_distance(_periodCtrl, 1)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            scrollController: _hourCtrl,
            itemExtent: 36,
            backgroundColor: Colors.transparent,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: _onHourChanged,
            children: List.generate(
              24,
              (i) => Center(
                child: Text(
                  '${i.toString().padLeft(2, '0')}시',
                  style: _wheelStyle(_distance(_hourCtrl, i)),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            scrollController: _minuteCtrl,
            itemExtent: 36,
            backgroundColor: Colors.transparent,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: (i) {
              setState(() => _minute = i);
              _emit();
            },
            children: List.generate(
              60,
              (i) => Center(
                child: Text(
                  '${i.toString().padLeft(2, '0')}분',
                  style: _wheelStyle(_distance(_minuteCtrl, i)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeTab extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool selected;
  final VoidCallback onTap;

  const _TimeTab({
    required this.label,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  String get _formatted =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF424242),
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? null
              : Border.all(color: const Color(0xFF585858)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: selected ? const Color(0xFFFF4646) : Colors.white,
              ),
            ),
            Text(
              _formatted,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: selected ? const Color(0xFFFF4646) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem {
  final bool isUser;
  final String text;
  final String? iconAsset;
  final AnimationController? controller;
  final int? userSeq;

  const _TimelineItem._({
    required this.isUser,
    required this.text,
    this.iconAsset,
    this.controller,
    this.userSeq,
  });

  factory _TimelineItem.user(String text, int seq) =>
      _TimelineItem._(isUser: true, text: text, userSeq: seq);

  factory _TimelineItem.bot(_FollowUp f, AnimationController controller) =>
      _TimelineItem._(
        isUser: false,
        text: f.text,
        iconAsset: f.iconAsset,
        controller: controller,
      );
}
